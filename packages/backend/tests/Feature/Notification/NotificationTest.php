<?php

namespace Tests\Feature\Notification;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Ledger\Services\ReminderService;
use App\Domains\Notification\Models\Notification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->travelTo('2026-09-15 12:00:00');
    }

    /** @return array{0: User, 1: string} */
    private function authenticated(): array
    {
        $user = User::factory()->create();

        return [$user, $user->createToken('api')->plainTextToken];
    }

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

        $this->expense($token, $category, '79.99');
        $this->assertDatabaseCount('notifications', 0);

        $this->expense($token, $category, '0.01');
        $this->assertDatabaseHas('notifications', [
            'user_id' => $user->id,
            'subject' => 'category_limit_warning',
            'subject_id' => $category->id,
        ]);

        $this->expense($token, $category, '10.00');
        $this->assertDatabaseCount('notifications', 1);

        $this->travelTo('2026-10-01 12:00:00');
        $this->expense($token, $category, '85.00', '2026-10-01');
        $this->assertDatabaseCount('notifications', 2);
    }

    public function test_category_without_limit_never_warns(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['limit_amount' => null]);

        $this->expense($token, $category, '5000.00');

        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_reminders_notify_due_soon_and_overdue_expense_installments_once(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['limit_amount' => null]);

        $this->expense($token, $category, '10.00', '2026-09-16');           // due tomorrow
        $this->expense($token, $category, '20.00', '2026-09-10');           // overdue
        $this->expense($token, $category, '30.00', '2026-09-30');           // too far ahead
        $this->expense($token, $category, '40.00', '2026-09-10', 'income'); // income: never a bill

        $reminders = app(ReminderService::class);

        $this->assertSame(
            ['installments_due_soon' => 1, 'installments_overdue' => 1, 'goals_near_deadline' => 0],
            $reminders->sendAll(),
        );
        $this->assertSame(
            ['installments_due_soon' => 0, 'installments_overdue' => 0, 'goals_near_deadline' => 0],
            $reminders->sendAll(),
        );
    }

    public function test_installment_reminder_message_describes_single_and_split_expenses(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['name' => 'Food', 'limit_amount' => null]);

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

        app(ReminderService::class)->sendAll();

        $messages = Notification::where('subject', 'installment_overdue')->orderBy('id')->pluck('message')->all();

        $this->assertContains('Your "Food" expense (45.00) was due on 2026-09-10 and is still unpaid.', $messages);
        $this->assertContains('Installment 1/3 of "Notebook" (100.00) was due on 2026-08-10 and is still unpaid.', $messages);
        $this->assertContains('Installment 2/3 of "Notebook" (100.00) was due on 2026-09-10 and is still unpaid.', $messages);
    }

    public function test_reminders_notify_only_unreached_goals_near_their_deadline(): void
    {
        $user = User::factory()->create();
        $near = Goal::factory()->for($user)->create(['target_amount' => '1000.00', 'expires_at' => '2026-09-20']);
        Goal::factory()->for($user)->create(['target_amount' => '1000.00', 'expires_at' => '2026-12-01']);
        $reached = Goal::factory()->for($user)->create(['target_amount' => '1000.00', 'expires_at' => '2026-09-20']);
        $reached->forceFill(['current_amount' => '1000.00'])->save();

        $sent = app(ReminderService::class)->sendAll();

        $this->assertSame(1, $sent['goals_near_deadline']);
        $this->assertDatabaseHas('notifications', ['subject' => 'goal_deadline', 'subject_id' => $near->id]);
    }

    public function test_a_deleted_notification_is_not_sent_again(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['limit_amount' => null]);
        $this->expense($token, $category, '20.00', '2026-09-10');

        app(ReminderService::class)->sendAll();
        $notification = Notification::firstOrFail();

        $this->withToken($token)->deleteJson("/api/v1/notifications/{$notification->id}")->assertNoContent();

        $this->assertSame(0, app(ReminderService::class)->sendAll()['installments_overdue']);
    }

    public function test_listing_exposes_subject_id_and_other_users_notifications_are_404(): void
    {
        [$user, $token] = $this->authenticated();
        $mine = Notification::factory()->for($user)->create(['subject' => 'goal_deadline', 'subject_id' => 42]);
        $theirs = Notification::factory()->create();

        $this->withToken($token)->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $mine->id)
            ->assertJsonPath('data.0.subject_id', 42);

        $this->withToken($token)->patchJson("/api/v1/notifications/{$theirs->id}/read")->assertNotFound();
        $this->withToken($token)->deleteJson("/api/v1/notifications/{$theirs->id}")->assertNotFound();
    }
}
