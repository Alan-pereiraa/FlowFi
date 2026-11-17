<?php

namespace Tests\Feature\Dashboard;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Notification\Models\Notification;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * TIPO: TESTE DE INTEGRAÇÃO (nível API) — no Laravel, um "Feature Test".
 *
 * POR QUÊ:
 *  - Não é unitário: nenhuma classe é isolada nem simulada (sem mocks). Cada
 *    teste atravessa várias camadas reais ao mesmo tempo:
 *    rota -> autenticação (Sanctum) -> validação (Request) -> Service ->
 *    Repository -> banco -> JSON (Resource).
 *  - Não é E2E: a requisição HTTP é simulada dentro do próprio PHP (getJson),
 *    sem navegador, sem rede e sem o app Flutter.
 *  - Os dados são criados por factories direto no banco, e o banco é um SQLite
 *    em memória (RefreshDatabase), isolado do banco de desenvolvimento.
 *
 * O QUE COBRE: cálculo de saldos, limites do mês, isolamento entre usuários,
 * validação de parâmetros e consistência entre o resumo geral e cada rota.
 */
class DashboardTest extends TestCase
{
    use RefreshDatabase;

    // Todas as rotas do dashboard: usadas no teste de acesso sem login.
    private const array ROUTES = [
        '/api/v1/dashboard',
        '/api/v1/dashboard/summary',
        '/api/v1/dashboard/spending-by-category',
        '/api/v1/dashboard/upcoming-installments',
        '/api/v1/dashboard/recent-transactions',
        '/api/v1/dashboard/goals',
    ];

    protected function setUp(): void
    {
        parent::setUp();

        // PONTO ESTRATÉGICO: congela o relógio em 15/09/2026. Sem isso, "atrasado",
        // "próximos dias" e "mês atual" mudariam a cada dia e o teste quebraria sozinho.
        $this->travelTo('2026-09-15 12:00:00');
    }

    // Cria um usuário e um token Sanctum, simulando alguém logado.
    private function authenticated(): array
    {
        $user = User::factory()->create();

        return [$user, $user->createToken('api')->plainTextToken];
    }

    /**
     * Helper de preparação: monta uma transação direto no banco via factories,
     * sem passar pela API de criação. Assim, se um teste falhar, o problema está
     * no dashboard, e não na criação de transação.
     *
     * $installments: lista de [valor, data, status opcional ('paid')].
     * $category: Category = usa essa; false = sem categoria; null = cria uma nova.
     */
    private function transaction(User $user, string $type, array $installments, Category|false|null $category = null, array $attributes = []): Transaction
    {
        $cents = array_sum(array_map(fn (array $row) => (int) round($row[0] * 100), $installments));

        $transaction = Transaction::factory()->create([
            'user_id' => $user->id,
            'category_id' => $category === false ? null : ($category ?? Category::factory()->for($user)->create())->id,
            'type' => $type,
            'total_amount' => number_format($cents / 100, 2, '.', ''),
            'date' => $installments[0][1],
            'installments_count' => count($installments),
            ...$attributes,
        ]);

        // Regra de domínio: só despesa tem parcelas; receita e transferência não.
        if ($type !== 'expense') {
            return $transaction;
        }

        foreach ($installments as $step => $row) {
            Installment::factory()->for($transaction)->create([
                'step' => $step + 1,
                'amount' => $row[0],
                'date' => $row[1],
                'status' => $row[2] ?? Installment::STATUS_PENDING,
                // O horário do pagamento é convertido de São Paulo para o fuso do app,
                // para a parcela cair no mês certo ("contar no mês em que foi paga").
                'paid_at' => ($row[2] ?? null) === Installment::STATUS_PAID
                    ? CarbonImmutable::parse($row[1], 'America/Sao_Paulo')->setTimezone(config('app.timezone'))
                    : null,
            ]);
        }

        return $transaction;
    }

    // SEGURANÇA: sem login, as 6 rotas devem responder 401. Um laço cobre todas.
    public function test_guest_cannot_access_the_dashboard(): void
    {
        foreach (self::ROUTES as $route) {
            $this->getJson($route)->assertUnauthorized();
        }
    }

    // CÁLCULO: separa o mês em pago x pendente e confere saldo e saldo projetado.
    public function test_summary_splits_the_month_into_paid_and_pending(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'income', [['1000.00', '2026-09-15']]);
        $this->transaction($user, 'income', [['500.00', '2026-09-20']]);
        $this->transaction($user, 'expense', [['200.00', '2026-09-02', 'paid']]);
        // Despesa parcelada: 1 paga em setembro, 1 pendente em setembro, 1 em outubro (fora do mês).
        $this->transaction($user, 'expense', [
            ['100.00', '2026-09-10', 'paid'],
            ['100.00', '2026-09-25'],
            ['100.00', '2026-10-25'],
        ]);

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertOk()
            ->assertJsonPath('data.period', ['month' => '2026-09', 'from' => '2026-09-01', 'to' => '2026-09-30'])
            ->assertJsonPath('data.income', ['paid' => '1000.00', 'pending' => '500.00', 'total' => '1500.00'])
            ->assertJsonPath('data.expense', ['paid' => '300.00', 'pending' => '100.00', 'total' => '400.00'])
            ->assertJsonPath('data.balance', '700.00')
            ->assertJsonPath('data.projected_balance', '1100.00');
    }

    // VALOR-LIMITE: dias 01 e 30 entram no mês; 31/08 e 01/10 ficam de fora.
    public function test_month_boundaries_are_inclusive_on_both_ends(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'expense', [['10.00', '2026-08-31']]);
        $this->transaction($user, 'expense', [['20.00', '2026-09-01']]);
        $this->transaction($user, 'expense', [['40.00', '2026-09-30']]);
        $this->transaction($user, 'expense', [['80.00', '2026-10-01']]);

        // 20 + 40 = 60 (os dias 31/08 e 01/10 não entram).
        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.expense.total', '60.00');
    }

    // CÁLCULO: "saldo até hoje" soma tudo que já foi pago, de qualquer mês.
    public function test_balance_to_date_covers_every_paid_installment_regardless_of_month(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'income', [['1000.00', '2026-06-05']]);
        $this->transaction($user, 'expense', [['250.50', '2026-08-10', 'paid']]);
        // Despesa pendente não entra no saldo até a data.
        $this->transaction($user, 'expense', [['999.00', '2026-09-28']]);

        // 1000,00 - 250,50 = 749,50.
        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.balance', '0.00')
            ->assertJsonPath('data.balance_to_date', '749.50');
    }

    // BORDA: o saldo pode ficar negativo (não pode ser truncado em zero).
    public function test_balance_can_go_negative(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'expense', [['75.25', '2026-09-03', 'paid']]);

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.balance', '-75.25');
    }

    // REGRA: "atrasadas" são só despesas pendentes já vencidas, de qualquer mês.
    public function test_summary_reports_overdue_installments_from_any_month(): void
    {
        [$user, $token] = $this->authenticated();

        // Duas parcelas vencidas (01/07 e 01/09, antes de "hoje" = 15/09).
        $this->transaction($user, 'expense', [['30.00', '2026-07-01'], ['20.00', '2026-09-01']]);
        // Vence hoje: ainda não conta como atrasada.
        $this->transaction($user, 'expense', [['99.00', '2026-09-15']]);
        // Já paga: não conta.
        $this->transaction($user, 'expense', [['11.00', '2026-08-01', 'paid']]);
        // Receita nunca é "atrasada".
        $this->transaction($user, 'income', [['400.00', '2026-09-10']]);

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.overdue.expense', ['count' => 2, 'amount' => '50.00'])
            ->assertJsonMissingPath('data.overdue.income');
    }

    // BORDA: conta sem nenhuma transação devolve zeros, sem erro nem null.
    public function test_summary_is_all_zeros_for_an_empty_account(): void
    {
        [, $token] = $this->authenticated();

        // Sem o parâmetro "month": usa o mês atual (setembro, por causa do travelTo).
        $this->withToken($token)->getJson('/api/v1/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.period.month', '2026-09')
            ->assertJsonPath('data.income.total', '0.00')
            ->assertJsonPath('data.expense.total', '0.00')
            ->assertJsonPath('data.balance', '0.00')
            ->assertJsonPath('data.balance_to_date', '0.00')
            ->assertJsonPath('data.transferred_to_goals', '0.00')
            ->assertJsonPath('data.overdue.expense', ['count' => 0, 'amount' => '0.00']);
    }

    // SEGURANÇA/ISOLAMENTO (o mais importante): dados de outro usuário e registros
    // apagados (soft delete) nunca podem entrar nas somas.
    public function test_other_accounts_and_deleted_rows_never_leak_into_the_numbers(): void
    {
        [$user, $token] = $this->authenticated();
        $stranger = User::factory()->create();

        $this->transaction($user, 'expense', [['10.00', '2026-09-05']]);
        // Valor alto de outro usuário: se vazar, o total quebra.
        $this->transaction($stranger, 'expense', [['5000.00', '2026-09-05', 'paid']]);

        // Transação apagada (parcelas e transação).
        $deletedTransaction = $this->transaction($user, 'expense', [['700.00', '2026-09-06']]);
        $deletedTransaction->installments()->delete();
        $deletedTransaction->delete();

        // Transação mantida, mas com uma parcela apagada: só a parcela viva conta.
        $keptTransaction = $this->transaction($user, 'expense', [['3.00', '2026-09-07'], ['900.00', '2026-09-08']]);
        $keptTransaction->installments()->where('step', 2)->delete();

        // Receita apagada e receita de outro usuário: nenhuma pode aparecer.
        $this->transaction($user, 'income', [['900.00', '2026-09-06']])->delete();
        $this->transaction($stranger, 'income', [['900.00', '2026-09-06']]);

        // 10 + 3 = 13: só o que é do usuário e não foi apagado.
        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.income.total', '0.00')
            ->assertJsonPath('data.expense.total', '13.00')
            ->assertJsonPath('data.balance_to_date', '0.00');

        $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions')
            ->assertJsonCount(2, 'data');
    }

    // TESTE NEGATIVO: formatos de mês inválidos devolvem 422 com erro no campo "month".
    public function test_month_must_be_a_valid_year_month(): void
    {
        [, $token] = $this->authenticated();

        foreach (['2026-13', '2026-00', '2026-9', '26-09', 'september', '2026-09-01'] as $month) {
            $this->withToken($token)->getJson('/api/v1/dashboard?month='.$month)
                ->assertUnprocessable()
                ->assertJsonValidationErrors('month');
        }
    }

    // CÁLCULO: ranking por categoria (maior gasto primeiro), com percentual do limite.
    public function test_spending_by_category_ranks_expenses_and_measures_the_limit(): void
    {
        [$user, $token] = $this->authenticated();

        $food = Category::factory()->for($user)->create(['name' => 'Food', 'limit_amount' => '400.00']);
        $fun = Category::factory()->for($user)->create(['name' => 'Fun', 'limit_amount' => null]);
        $salary = Category::factory()->for($user)->create(['name' => 'Salary']);

        $this->transaction($user, 'expense', [['100.00', '2026-09-02', 'paid'], ['100.00', '2026-09-20']], $food);
        $this->transaction($user, 'expense', [['50.00', '2026-09-04', 'paid']], $food);
        $this->transaction($user, 'expense', [['300.00', '2026-09-12']], $fun);
        // Outubro: fora do mês consultado, não pode somar em "Fun".
        $this->transaction($user, 'expense', [['70.00', '2026-10-02']], $fun);
        // Receita não entra em "gastos por categoria".
        $this->transaction($user, 'income', [['3000.00', '2026-09-01']], $salary);

        $response = $this->withToken($token)->getJson('/api/v1/dashboard/spending-by-category?month=2026-09')
            ->assertOk()
            ->assertJsonPath('data.period.month', '2026-09')
            ->assertJsonCount(2, 'data.categories');

        // Ordem: Fun (300) vem antes de Food (250).
        $this->assertSame(['Fun', 'Food'], array_column(array_column($response->json('data.categories'), 'category'), 'name'));

        $response->assertJsonPath('data.categories.0.total', '300.00')
            ->assertJsonPath('data.categories.0.paid', '0.00')
            ->assertJsonPath('data.categories.0.pending', '300.00')
            // Sem limite: o percentual é null (e não zero).
            ->assertJsonPath('data.categories.0.limit_amount', null)
            ->assertJsonPath('data.categories.0.limit_used_percent', null)
            ->assertJsonPath('data.categories.1.category.id', $food->id)
            ->assertJsonPath('data.categories.1.paid', '150.00')
            ->assertJsonPath('data.categories.1.pending', '100.00')
            ->assertJsonPath('data.categories.1.total', '250.00')
            ->assertJsonPath('data.categories.1.limit_amount', '400.00')
            // 250 de 400 = 62,5%.
            ->assertJsonPath('data.categories.1.limit_used_percent', 62.5);
    }

    // HISTÓRICO: categoria apagada continua aparecendo nos gastos antigos, com o nome de antes.
    public function test_spending_keeps_a_deleted_category_with_its_old_name(): void
    {
        [$user, $token] = $this->authenticated();

        $category = Category::factory()->for($user)->create(['name' => 'Old gym']);
        $this->transaction($user, 'expense', [['80.00', '2026-09-03', 'paid']], $category);
        $category->delete();

        $this->withToken($token)->getJson('/api/v1/dashboard/spending-by-category?month=2026-09')
            ->assertJsonPath('data.categories.0.category.name', 'Old gym')
            ->assertJsonPath('data.categories.0.total', '80.00');
    }

    // BORDA: despesas sem categoria são agrupadas num único item com category = null.
    public function test_spending_groups_uncategorized_expenses_under_a_null_category(): void
    {
        [$user, $token] = $this->authenticated();

        // O "false" no helper significa "sem categoria".
        $this->transaction($user, 'expense', [['40.00', '2026-09-03', 'paid']], false);
        $this->transaction($user, 'expense', [['60.00', '2026-09-20']], false);

        $this->withToken($token)->getJson('/api/v1/dashboard/spending-by-category?month=2026-09')
            ->assertOk()
            ->assertJsonCount(1, 'data.categories')
            ->assertJsonPath('data.categories.0.category', null)
            ->assertJsonPath('data.categories.0.paid', '40.00')
            ->assertJsonPath('data.categories.0.pending', '60.00')
            ->assertJsonPath('data.categories.0.total', '100.00')
            ->assertJsonPath('data.categories.0.limit_amount', null);
    }

    // LISTA: próximas parcelas — atrasadas primeiro; ignora pagas e distantes;
    // respeita os parâmetros "days" (janela) e "limit" (quantidade).
    public function test_upcoming_installments_lists_overdue_first_and_skips_paid_and_far_ones(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['name' => 'Rent']);

        $this->transaction($user, 'expense', [['10.00', '2026-08-20']], $category, ['description' => 'Late one']);
        $this->transaction($user, 'expense', [['20.00', '2026-09-15']], $category);
        $this->transaction($user, 'expense', [['30.00', '2026-09-25']], $category);
        // Paga: fica de fora. Muito distante (novembro): fora da janela padrão.
        $this->transaction($user, 'expense', [['40.00', '2026-09-10', 'paid']], $category);
        $this->transaction($user, 'expense', [['50.00', '2026-11-30']], $category);

        $response = $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments')
            ->assertOk()
            ->assertJsonCount(3, 'data');

        $this->assertSame(['10.00', '20.00', '30.00'], array_column($response->json('data'), 'amount'));
        $this->assertSame([true, false, false], array_column($response->json('data'), 'overdue'));

        $response->assertJsonPath('data.0.description', 'Late one')
            ->assertJsonPath('data.0.type', 'expense')
            ->assertJsonPath('data.0.step', 1)
            ->assertJsonPath('data.0.installments_count', 1)
            ->assertJsonPath('data.0.date', '2026-08-20')
            ->assertJsonPath('data.0.category.name', 'Rent');

        // Janela maior (90 dias): a parcela de novembro passa a aparecer (4 itens).
        $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments?days=90')
            ->assertJsonCount(4, 'data');

        // "limit=1" devolve só a primeira (a atrasada).
        $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments?limit=1')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.amount', '10.00');
    }

    // TESTE NEGATIVO / VALOR-LIMITE: days e limit fora da faixa permitida devolvem 422.
    public function test_upcoming_installments_validates_its_window(): void
    {
        [, $token] = $this->authenticated();

        $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments?days=0')
            ->assertUnprocessable()->assertJsonValidationErrors('days');
        $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments?days=366')
            ->assertUnprocessable()->assertJsonValidationErrors('days');
        $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments?limit=51')
            ->assertUnprocessable()->assertJsonValidationErrors('limit');
    }

    // LISTA: transações recentes — mais novas primeiro, com status derivado das parcelas:
    // paid (todas pagas), partial (algumas pagas), pending (nenhuma paga).
    public function test_recent_transactions_are_newest_first_with_a_payment_status(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['name' => 'Market', 'icon' => 'shopping_cart', 'color' => '#4CAF50']);

        $this->transaction($user, 'expense', [['10.00', '2026-09-01', 'paid']], $category, ['description' => 'Paid']);
        $this->transaction($user, 'expense', [['10.00', '2026-09-05', 'paid'], ['10.00', '2026-10-05']], $category, ['description' => 'Partial']);
        $this->transaction($user, 'income', [['10.00', '2026-09-20']], $category, ['description' => 'Pending']);

        $response = $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions')
            ->assertOk()
            ->assertJsonCount(3, 'data');

        $this->assertSame(['Pending', 'Partial', 'Paid'], array_column($response->json('data'), 'description'));
        $this->assertSame(['pending', 'partial', 'paid'], array_column($response->json('data'), 'status'));

        $response->assertJsonPath('data.1.total_amount', '20.00')
            ->assertJsonPath('data.1.installments_count', 2)
            ->assertJsonPath('data.1.paid_installments_count', 1)
            ->assertJsonPath('data.1.category', ['id' => $category->id, 'name' => 'Market', 'icon' => 'shopping_cart', 'color' => '#4CAF50']);

        $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions?limit=2')
            ->assertJsonCount(2, 'data');

        // Limite máximo permitido é 20: 21 deve ser rejeitado.
        $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions?limit=21')
            ->assertUnprocessable()->assertJsonValidationErrors('limit');
    }

    // LISTA: metas — ordenadas por prazo (sem prazo por último), com percentual de progresso.
    public function test_goals_report_their_saved_balance_and_progress(): void
    {
        [$user, $token] = $this->authenticated();

        $later = Goal::factory()->for($user)->create(['name' => 'Car', 'target_amount' => '10000.00', 'current_amount' => '0.00', 'expires_at' => '2027-12-01']);
        $sooner = Goal::factory()->for($user)->create(['name' => 'Trip', 'target_amount' => '2000.00', 'current_amount' => '600.00', 'expires_at' => '2027-01-01']);
        $open = Goal::factory()->for($user)->create(['name' => 'Rainy day', 'target_amount' => '500.00', 'current_amount' => '125.00', 'expires_at' => null]);
        // Meta de outro usuário e meta apagada: não podem aparecer.
        Goal::factory()->for(User::factory()->create())->create(['current_amount' => '999.00']);
        Goal::factory()->for($user)->create(['current_amount' => '0.00'])->delete();

        $response = $this->withToken($token)->getJson('/api/v1/dashboard/goals')
            ->assertOk()
            ->assertJsonCount(3, 'data');

        $this->assertSame(['Trip', 'Car', 'Rainy day'], array_column($response->json('data'), 'name'));

        $response->assertJsonPath('data.0.id', $sooner->id)
            ->assertJsonPath('data.0.target_amount', '2000.00')
            ->assertJsonPath('data.0.current_amount', '600.00')
            // 600 de 2000 = 30%.
            ->assertJsonPath('data.0.progress_percent', 30)
            ->assertJsonPath('data.0.expires_at', '2027-01-01')
            ->assertJsonPath('data.1.id', $later->id)
            ->assertJsonPath('data.1.current_amount', '0.00')
            ->assertJsonPath('data.1.progress_percent', 0)
            ->assertJsonPath('data.2.id', $open->id)
            ->assertJsonPath('data.2.current_amount', '125.00')
            ->assertJsonPath('data.2.progress_percent', 25)
            ->assertJsonPath('data.2.expires_at', null);
    }

    // REGRA DE NEGÓCIO: transferência para meta tira dinheiro do saldo, mas não conta
    // como receita nem como despesa, e não aparece em gastos por categoria.
    public function test_transfers_to_goals_leave_the_balance_without_counting_as_income_or_expense(): void
    {
        [$user, $token] = $this->authenticated();
        $goal = Goal::factory()->for($user)->create(['name' => 'Trip', 'icon' => 'flight', 'color' => '#FF9800']);

        $this->transaction($user, 'income', [['1000.00', '2026-09-01']]);
        $this->transaction($user, 'expense', [['100.00', '2026-09-02', 'paid']]);
        $this->transaction($user, 'transfer', [['250.00', '2026-09-03']], false, ['goal_id' => $goal->id]);
        // Transferência de agosto: entra no saldo até hoje, mas não no total do mês.
        $this->transaction($user, 'transfer', [['40.00', '2026-08-30']], false, ['goal_id' => $goal->id]);

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertOk()
            ->assertJsonPath('data.income.total', '1000.00')
            ->assertJsonPath('data.expense.total', '100.00')
            // 1000 - 100 - 250 = 650.
            ->assertJsonPath('data.balance', '650.00')
            ->assertJsonPath('data.projected_balance', '650.00')
            // 1000 - 100 - 250 - 40 = 610.
            ->assertJsonPath('data.balance_to_date', '610.00')
            ->assertJsonPath('data.transferred_to_goals', '250.00');

        // Transferência não é gasto: continua só 1 categoria (a da despesa).
        $this->withToken($token)->getJson('/api/v1/dashboard/spending-by-category?month=2026-09')
            ->assertJsonCount(1, 'data.categories');

        // Nas transações recentes, aparece como "transfer", já paga, com a meta e sem categoria.
        $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions')
            ->assertOk()
            ->assertJsonPath('data.0.type', 'transfer')
            ->assertJsonPath('data.0.total_amount', '250.00')
            ->assertJsonPath('data.0.status', 'paid')
            ->assertJsonPath('data.0.category', null)
            ->assertJsonPath('data.0.goal', ['id' => $goal->id, 'name' => 'Trip', 'icon' => 'flight', 'color' => '#FF9800'])
            ->assertJsonPath('data.2.goal', null);
    }

    // CONTRATO: a rota agregada /dashboard traz todos os blocos (estrutura do JSON)
    // e conta só as notificações não lidas do próprio usuário.
    public function test_overview_bundles_every_block_for_the_current_month(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'income', [['100.00', '2026-09-02']]);
        $this->transaction($user, 'expense', [['40.00', '2026-09-20']]);
        Goal::factory()->for($user)->create();
        // 2 não lidas + 1 lida do usuário, e 1 não lida de outro usuário: o total esperado é 2.
        Notification::factory()->for($user)->count(2)->create(['read_at' => null]);
        Notification::factory()->for($user)->create(['read_at' => now()]);
        Notification::factory()->for(User::factory()->create())->create(['read_at' => null]);

        $this->withToken($token)->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonStructure(['data' => [
                'summary' => ['period', 'income', 'expense', 'balance', 'projected_balance', 'balance_to_date', 'transferred_to_goals', 'overdue'],
                'spending_by_category' => ['period', 'categories'],
                'upcoming_installments',
                'recent_transactions',
                'goals',
                'unread_notifications',
            ]])
            ->assertJsonPath('data.summary.period.month', '2026-09')
            ->assertJsonPath('data.summary.balance', '100.00')
            ->assertJsonPath('data.summary.projected_balance', '60.00')
            ->assertJsonPath('data.summary.transferred_to_goals', '0.00')
            ->assertJsonCount(1, 'data.spending_by_category.categories')
            ->assertJsonCount(1, 'data.upcoming_installments')
            ->assertJsonCount(2, 'data.recent_transactions')
            ->assertJsonCount(1, 'data.goals')
            ->assertJsonPath('data.unread_notifications', 2);
    }

    // CONTRATO: o endpoint agregado e cada rota separada devem devolver exatamente
    // os mesmos dados (assertSame), garantindo que nunca divergem.
    public function test_overview_blocks_match_their_dedicated_routes(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'expense', [['40.00', '2026-09-20']]);

        $overview = $this->withToken($token)->getJson('/api/v1/dashboard?month=2026-09')->json('data');

        $this->assertSame($overview['summary'], $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')->json('data'));
        $this->assertSame($overview['spending_by_category'], $this->withToken($token)->getJson('/api/v1/dashboard/spending-by-category?month=2026-09')->json('data'));
        $this->assertSame($overview['upcoming_installments'], $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments')->json('data'));
        $this->assertSame($overview['recent_transactions'], $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions')->json('data'));
        $this->assertSame($overview['goals'], $this->withToken($token)->getJson('/api/v1/dashboard/goals')->json('data'));
    }
}
