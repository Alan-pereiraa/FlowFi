<?php

namespace Tests\Feature\Notification;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Ledger\Services\ReminderService;
use App\Domains\Notification\Models\Notification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * TESTE DE INTEGRAÇÃO
 *
 * Verifica a integração entre as rotas da API, autenticação, banco de dados
 * e serviços responsáveis pela geração e gerenciamento de notificações.
 *
 * Testa os alertas de limites de gastos, lembretes de parcelas e metas,
 * prevenção de notificações duplicadas e acesso às notificações dos usuários.
 */
class NotificationTest extends TestCase
{
    // Reinicia o banco de dados antes da execução de cada teste.
    use RefreshDatabase;

    // Define uma data e hora fixa para garantir previsibilidade nos testes.
    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-09-15 12:00:00');
    }

    // Cria um usuário autenticado e retorna seus dados e token de acesso.
    private function authenticated(): array
    {
        $user = User::factory()->create();

        return [$user, $user->createToken('api')->plainTextToken];
    }

    // Realiza o cadastro de uma movimentação financeira pela API.
    private function expense(string $token, Category $category, string $amount, string $date = '2026-09-15', string $type = 'expense'): void
    {
        $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => $type,
            'date' => $date,
            'total_amount' => $amount,
        ])->assertCreated();
    }

    public function test_expense_reaching_80_percent_of_the_limit_warns_once_per_month(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['limit_amount' => '100.00']);

        // Verifica que gastos abaixo de 80% do limite não geram notificações.
        $this->expense($token, $category, '79.99');
        $this->assertDatabaseCount('notifications', 0);

        // Atinge exatamente 80% do limite e verifica a criação do alerta.
        $this->expense($token, $category, '0.01');
        $this->assertDatabaseHas('notifications', [
            'user_id' => $user->id,
            'subject' => 'category_limit_warning',
            'subject_id' => $category->id,
        ]);

        // Verifica que novos gastos no mesmo mês não duplicam o alerta.
        $this->expense($token, $category, '10.00');
        $this->assertDatabaseCount('notifications', 1);

        // Avança para o mês seguinte e verifica se um novo alerta é permitido.
        $this->travelTo('2026-10-01 12:00:00');
        $this->expense($token, $category, '85.00', '2026-10-01');
        $this->assertDatabaseCount('notifications', 2);
    }

    public function test_category_without_limit_never_warns(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['limit_amount' => null]);

        // Registra um gasto em uma categoria sem limite configurado.
        $this->expense($token, $category, '5000.00');

        // Garante que nenhum alerta de limite foi gerado.
        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_reminders_notify_due_soon_and_overdue_expense_installments_once(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['limit_amount' => null]);

        // Cadastra movimentações com diferentes datas e tipos para simular
        // parcelas próximas do vencimento, atrasadas e movimentações não elegíveis.
        $this->travelTo('2026-08-01 12:00:00');
        $this->expense($token, $category, '10.00', '2026-09-16');
        $this->expense($token, $category, '20.00', '2026-09-10');
        $this->expense($token, $category, '30.00', '2026-09-30');
        $this->expense($token, $category, '40.00', '2026-09-10', 'income');
        $this->travelTo('2026-09-15 12:00:00');

        $reminders = app(ReminderService::class);

        // Verifica a quantidade de lembretes gerados na primeira execução.
        $this->assertSame(
            ['installments_due_soon' => 1, 'installments_overdue' => 1, 'goals_near_deadline' => 0],
            $reminders->sendAll(),
        );

        // Executa novamente para garantir que os mesmos lembretes não sejam enviados em duplicidade.
        $this->assertSame(
            ['installments_due_soon' => 0, 'installments_overdue' => 0, 'goals_near_deadline' => 0],
            $reminders->sendAll(),
        );
    }

    public function test_installment_reminder_message_describes_single_and_split_expenses(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['name' => 'Food', 'limit_amount' => null]);

        // Cadastra um gasto à vista e outro parcelado para verificar
        // a composição das mensagens de lembrete.
        $this->travelTo('2026-08-01 12:00:00');
        $this->expense($token, $category, '45.00', '2026-09-10');

        $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'description' => 'Notebook',
            'date' => '2026-08-10',
            'total_amount' => '300.00',
            'installments_count' => 3,
            'period_unit' => 'month',
        ])->assertCreated();

        // Avança a data e processa os lembretes de vencimento.
        $this->travelTo('2026-09-15 12:00:00');
        app(ReminderService::class)->sendAll();

        // Recupera as mensagens das notificações de parcelas atrasadas.
        $messages = Notification::where('subject', 'installment_overdue')->orderBy('id')->pluck('message')->all();

        // Verifica se as mensagens apresentam corretamente os gastos à vista e parcelados.
        $this->assertContains('Seu gasto em "Food" (R$ 45,00) venceu em 10/09/2026 e ainda não foi paga.', $messages);
        $this->assertContains('Parcela 1/3 de "Notebook" (R$ 100,00) venceu em 10/08/2026 e ainda não foi paga.', $messages);
        $this->assertContains('Parcela 2/3 de "Notebook" (R$ 100,00) venceu em 10/09/2026 e ainda não foi paga.', $messages);
    }

    public function test_reminders_notify_only_unreached_goals_near_their_deadline(): void
    {
        $user = User::factory()->create();

        // Cria metas com diferentes prazos e situações de conclusão.
        $near = Goal::factory()->for($user)->create(['target_amount' => '1000.00', 'expires_at' => '2026-09-20']);
        Goal::factory()->for($user)->create(['target_amount' => '1000.00', 'expires_at' => '2026-12-01']);
        $reached = Goal::factory()->for($user)->create(['target_amount' => '1000.00', 'expires_at' => '2026-09-20']);
        $reached->forceFill(['current_amount' => '1000.00'])->save();

        // Executa o serviço de lembretes e verifica a quantidade de alertas gerados.
        $sent = app(ReminderService::class)->sendAll();

        $this->assertSame(1, $sent['goals_near_deadline']);

        // Confirma que a notificação foi criada para a meta próxima do prazo.
        $this->assertDatabaseHas('notifications', ['subject' => 'goal_deadline', 'subject_id' => $near->id]);
    }

    public function test_a_deleted_notification_is_not_sent_again(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['limit_amount' => null]);

        // Cria uma movimentação que resultará em um lembrete de parcela atrasada.
        $this->travelTo('2026-08-01 12:00:00');
        $this->expense($token, $category, '20.00', '2026-09-10');
        $this->travelTo('2026-09-15 12:00:00');

        app(ReminderService::class)->sendAll();
        $notification = Notification::firstOrFail();

        // Exclui a notificação pela API utilizando o token do usuário.
        $this->withToken($token)->deleteJson("/api/v1/notifications/{$notification->id}")->assertNoContent();

        // Verifica se a exclusão impede a geração de um novo lembrete.
        $this->assertSame(0, app(ReminderService::class)->sendAll()['installments_overdue']);
    }

    public function test_listing_exposes_subject_id_and_other_users_notifications_are_404(): void
    {
        [$user, $token] = $this->authenticated();

        // Cria notificações pertencentes a usuários diferentes.
        $mine = Notification::factory()->for($user)->create(['subject' => 'goal_deadline', 'subject_id' => 42]);
        $theirs = Notification::factory()->create();

        // Verifica se a listagem retorna somente as notificações do usuário autenticado
        // e se disponibiliza corretamente o identificador do assunto.
        $this->withToken($token)->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $mine->id)
            ->assertJsonPath('data.0.subject_id', 42);

        // Garante que o usuário não consiga alterar ou excluir notificações de terceiros.
        $this->withToken($token)->patchJson("/api/v1/notifications/{$theirs->id}/read")->assertNotFound();
        $this->withToken($token)->deleteJson("/api/v1/notifications/{$theirs->id}")->assertNotFound();
    }
}
