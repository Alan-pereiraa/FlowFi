<?php

namespace Tests\Feature\Domains\Ledger;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Services\TransactionService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class TransactionServiceTest extends TestCase
{
    use RefreshDatabase;

    private const DATE = '2026-10-01';

    // ------------------------------------------------------------------
    // Criação: parcelamento
    // ------------------------------------------------------------------

    public function test_transacao_unica_gera_uma_parcela_pendente_com_o_valor_total(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '100.00',
        ]);

        $this->assertCount(1, $transaction->installments);
        $installment = $transaction->installments->first();
        $this->assertSame('100.00', $installment->amount);
        $this->assertSame(Installment::STATUS_PENDING, $installment->status);
        $this->assertSame(Transaction::SCHEDULE_SINGLE, $transaction->schedule_type);
    }

    public function test_transacao_parcelada_distribui_os_centavos_restantes_nas_primeiras_parcelas(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '100.00',
            'installments_count' => 3,
        ]);

        $amounts = $transaction->installments->pluck('amount')->all();

        // 100.00 / 3 = 33.33 com 1 centavo sobrando, que vai para a 1ª parcela.
        $this->assertSame(['33.34', '33.33', '33.33'], $amounts);

        // Soma em centavos (inteiros), sem depender da extensão bcmath.
        $totalCents = array_sum(array_map(
            fn (string $amount) => (int) str_replace('.', '', $amount),
            $amounts
        ));
        $this->assertSame(10000, $totalCents);
        $this->assertSame(Transaction::SCHEDULE_PERIODIC, $transaction->schedule_type);
    }

    public function test_installments_explicitos_sao_usados_como_informados_e_ordenados_por_data(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'installments' => [
                ['amount' => '20.00', 'date' => '2026-11-01'],
                ['amount' => '10.00', 'date' => '2026-10-01'],
            ],
        ]);

        $rows = $transaction->installments->map(fn (Installment $i) => [
            'step' => $i->step,
            'amount' => $i->amount,
            'date' => $i->date->toDateString(),
        ])->all();

        $this->assertSame([
            ['step' => 1, 'amount' => '10.00', 'date' => '2026-10-01'],
            ['step' => 2, 'amount' => '20.00', 'date' => '2026-11-01'],
        ], $rows);
        $this->assertSame(Transaction::SCHEDULE_CUSTOM, $transaction->schedule_type);
    }

    // ------------------------------------------------------------------
    // Criação: limite mensal da categoria
    // ------------------------------------------------------------------

    public function test_despesa_que_ultrapassa_o_limite_mensal_da_categoria_e_bloqueada_e_nada_e_salvo(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user, '100.00');

        try {
            $this->service()->create($user, [
                'type' => Transaction::TYPE_EXPENSE,
                'category_id' => $category->id,
                'date' => self::DATE,
                'total_amount' => '150.00',
            ]);
            $this->fail('Era esperada uma ValidationException.');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('total_amount', $e->errors());
        }

        $this->assertDatabaseCount('transactions', 0);
        $this->assertDatabaseCount('installments', 0);
    }

    public function test_despesa_dentro_do_limite_mensal_e_permitida(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user, '100.00');

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '80.00',
        ]);

        $this->assertNotNull($transaction->id);
    }

    public function test_categoria_sem_limite_nunca_bloqueia_a_despesa(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user); // limit_amount null

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '5000.00',
        ]);

        $this->assertNotNull($transaction->id);
    }

    // ------------------------------------------------------------------
    // Criação: efeito em metas
    // ------------------------------------------------------------------

    public function test_transferencia_aumenta_o_saldo_da_meta(): void
    {
        $user = User::factory()->create();
        $goal = $this->goal($user, '0.00');

        $this->service()->create($user, [
            'type' => Transaction::TYPE_TRANSFER,
            'goal_id' => $goal->id,
            'date' => self::DATE,
            'total_amount' => '250.00',
        ]);

        $this->assertSame('250.00', $goal->fresh()->current_amount);
    }

    public function test_despesa_vinculada_a_meta_diminui_o_saldo_da_meta(): void
    {
        $user = User::factory()->create();
        $goal = $this->goal($user, '500.00');
        $category = $this->category($user);

        $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'goal_id' => $goal->id,
            'date' => self::DATE,
            'total_amount' => '120.00',
        ]);

        $this->assertSame('380.00', $goal->fresh()->current_amount);
    }

    public function test_receita_vinculada_a_meta_nao_altera_o_saldo(): void
    {
        $user = User::factory()->create();
        $goal = $this->goal($user, '300.00');

        $this->service()->create($user, [
            'type' => Transaction::TYPE_INCOME,
            'goal_id' => $goal->id,
            'date' => self::DATE,
            'total_amount' => '50.00',
        ]);

        $this->assertSame('300.00', $goal->fresh()->current_amount);
    }

    public function test_despesa_vinculada_a_meta_sem_saldo_suficiente_e_bloqueada_e_nada_e_salvo(): void
    {
        $user = User::factory()->create();
        $goal = $this->goal($user, '10.00');
        $category = $this->category($user);

        try {
            $this->service()->create($user, [
                'type' => Transaction::TYPE_EXPENSE,
                'category_id' => $category->id,
                'goal_id' => $goal->id,
                'date' => self::DATE,
                'total_amount' => '50.00',
            ]);
            $this->fail('Era esperada uma ValidationException.');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('goal_id', $e->errors());
        }

        $this->assertSame('10.00', $goal->fresh()->current_amount);
        $this->assertDatabaseCount('transactions', 0);
    }

    public function test_transferencia_marca_automaticamente_a_sua_parcela_como_paga(): void
    {
        $user = User::factory()->create();
        $goal = $this->goal($user, '0.00');

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_TRANSFER,
            'goal_id' => $goal->id,
            'date' => self::DATE,
            'total_amount' => '90.00',
        ]);

        $installment = $transaction->installments->first();
        $this->assertSame(Installment::STATUS_PAID, $installment->status);
        $this->assertNotNull($installment->paid_at);
    }

    // ------------------------------------------------------------------
    // Edição
    // ------------------------------------------------------------------

    public function test_editar_o_valor_de_despesa_vinculada_a_meta_ajusta_o_saldo_pela_diferenca(): void
    {
        $user = User::factory()->create();
        $goal = $this->goal($user, '500.00');
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'goal_id' => $goal->id,
            'date' => self::DATE,
            'total_amount' => '100.00',
        ]);
        $this->assertSame('400.00', $goal->fresh()->current_amount);

        $this->service()->update($transaction, ['total_amount' => '150.00']);

        $this->assertSame('350.00', $goal->fresh()->current_amount);
    }

    public function test_trocar_a_meta_vinculada_retira_o_efeito_da_antiga_e_aplica_na_nova(): void
    {
        $user = User::factory()->create();
        $goalA = $this->goal($user, '500.00');
        $goalB = $this->goal($user, '200.00');
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'goal_id' => $goalA->id,
            'date' => self::DATE,
            'total_amount' => '100.00',
        ]);
        $this->assertSame('400.00', $goalA->fresh()->current_amount);

        $this->service()->update($transaction, ['goal_id' => $goalB->id]);

        $this->assertSame('500.00', $goalA->fresh()->current_amount, 'A meta antiga deveria recuperar o valor');
        $this->assertSame('100.00', $goalB->fresh()->current_amount, 'A meta nova deveria ser debitada');
    }

    public function test_editar_o_cronograma_de_uma_transacao_com_parcela_paga_e_bloqueado(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '100.00',
        ]);
        $this->service()->payInstallment($user, $transaction->id, $transaction->installments->first()->id);

        try {
            $this->service()->update($transaction, ['total_amount' => '999.00']);
            $this->fail('Era esperada uma ValidationException.');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('installments', $e->errors());
        }

        $this->assertSame('100.00', $transaction->fresh()->total_amount);
    }

    public function test_editar_campos_simples_nao_e_bloqueado_mesmo_com_parcela_paga(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '100.00',
            'description' => 'Original',
        ]);
        $this->service()->payInstallment($user, $transaction->id, $transaction->installments->first()->id);

        $updated = $this->service()->update($transaction, ['description' => 'Atualizada']);

        $this->assertSame('Atualizada', $updated->description);
    }

    // ------------------------------------------------------------------
    // Exclusão
    // ------------------------------------------------------------------

    public function test_apagar_uma_transferencia_devolve_o_valor_para_a_meta(): void
    {
        $user = User::factory()->create();
        $goal = $this->goal($user, '0.00');

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_TRANSFER,
            'goal_id' => $goal->id,
            'date' => self::DATE,
            'total_amount' => '80.00',
        ]);
        $this->assertSame('80.00', $goal->fresh()->current_amount);

        $this->service()->delete($transaction);

        $this->assertSame('0.00', $goal->fresh()->current_amount);
        $this->expectException(ModelNotFoundException::class);
        $this->service()->findOwned($user, $transaction->id);
    }

    public function test_apagar_uma_transacao_remove_suas_parcelas(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '90.00',
            'installments_count' => 3,
        ]);
        $transactionId = $transaction->id;

        $this->service()->delete($transaction);

        $this->assertSame(0, Installment::where('transaction_id', $transactionId)->count());
        $this->assertSame(3, Installment::withTrashed()->where('transaction_id', $transactionId)->count());
    }

    // ------------------------------------------------------------------
    // Pagamento de parcela
    // ------------------------------------------------------------------

    public function test_pagar_uma_parcela_pendente_marca_como_paga_e_registra_paid_at(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '50.00',
        ]);
        $installmentId = $transaction->installments->first()->id;

        $paid = $this->service()->payInstallment($user, $transaction->id, $installmentId);

        $this->assertSame(Installment::STATUS_PAID, $paid->status);
        $this->assertNotNull($paid->paid_at);
    }

    public function test_pagar_uma_parcela_ja_paga_lanca_erro_e_nao_duplica_o_pagamento(): void
    {
        $user = User::factory()->create();
        $category = $this->category($user);

        $transaction = $this->service()->create($user, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '50.00',
        ]);
        $installmentId = $transaction->installments->first()->id;
        $firstPaidAt = $this->service()->payInstallment($user, $transaction->id, $installmentId)->paid_at;

        try {
            $this->service()->payInstallment($user, $transaction->id, $installmentId);
            $this->fail('Era esperada uma ValidationException.');
        } catch (ValidationException $e) {
            $this->assertArrayHasKey('status', $e->errors());
        }

        $this->assertTrue($firstPaidAt->equalTo(
            Installment::find($installmentId)->paid_at
        ));
    }

    // ------------------------------------------------------------------
    // Isolamento entre usuários
    // ------------------------------------------------------------------

    public function test_findOwned_nao_permite_acessar_transacao_de_outro_usuario(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $category = $this->category($owner);

        $transaction = $this->service()->create($owner, [
            'type' => Transaction::TYPE_EXPENSE,
            'category_id' => $category->id,
            'date' => self::DATE,
            'total_amount' => '30.00',
        ]);

        $this->expectException(ModelNotFoundException::class);
        $this->service()->findOwned($stranger, $transaction->id);
    }

    // ------------------------------------------------------------------
    // Auxiliares
    // ------------------------------------------------------------------

    private function service(): TransactionService
    {
        return app(TransactionService::class);
    }

    private function category(User $user, ?string $limit = null): Category
    {
        return Category::factory()->for($user)->create(['limit_amount' => $limit]);
    }

    private function goal(User $user, string $currentAmount): Goal
    {
        $goal = Goal::factory()->for($user)->create(['target_amount' => '1000.00']);
        $goal->forceFill(['current_amount' => $currentAmount])->save();

        return $goal;
    }
}