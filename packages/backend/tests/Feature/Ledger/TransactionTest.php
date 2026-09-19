<?php

namespace Tests\Feature\Ledger;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Models\Transaction;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TransactionTest extends TestCase
{
    use RefreshDatabase;

    /** @return array{0: User, 1: string} */
    private function authenticated(): array
    {
        $user = User::factory()->create();

        return [$user, $user->createToken('api')->plainTextToken];
    }

    public function test_single_payment_creates_exactly_one_installment(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create();

        $response = $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-09-13',
            'total_amount' => '150.00',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.schedule_type', 'single')
            ->assertJsonPath('data.installments_count', 1)
            ->assertJsonCount(1, 'data.installments')
            ->assertJsonPath('data.installments.0.step', 1)
            ->assertJsonPath('data.installments.0.amount', '150.00')
            ->assertJsonPath('data.installments.0.date', '2026-09-13')
            ->assertJsonPath('data.installments.0.status', 'pending');

        $this->assertDatabaseCount('installments', 1);
    }

    public function test_transaction_can_be_split_into_equal_periodic_installments(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create();

        $response = $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-01-01',
            'total_amount' => '100.01',
            'installments_count' => 3,
            'period_unit' => 'month',
            'period_interval' => 1,
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.schedule_type', 'periodic')
            ->assertJsonCount(3, 'data.installments');

        $installments = $response->json('data.installments');

        // 100.01 split three ways: the leftover cent is front-loaded so the sum stays exact.
        $this->assertSame(['33.34', '33.34', '33.33'], array_column($installments, 'amount'));
        $this->assertSame(['2026-01-01', '2026-02-01', '2026-03-01'], array_column($installments, 'date'));
    }

    public function test_transaction_can_use_custom_installments_across_different_periods(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create();

        $response = $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-01-01',
            'total_amount' => '300.00',
            'installments' => [
                ['amount' => '150.00', 'date' => '2026-02-25'],
                ['amount' => '100.00', 'date' => '2026-01-10'],
                ['amount' => '50.00', 'date' => '2026-05-01'],
            ],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.schedule_type', 'custom')
            ->assertJsonCount(3, 'data.installments')
            // Reordered chronologically regardless of the order they were sent in.
            ->assertJsonPath('data.installments.0.date', '2026-01-10')
            ->assertJsonPath('data.installments.0.amount', '100.00')
            ->assertJsonPath('data.installments.1.date', '2026-02-25')
            ->assertJsonPath('data.installments.2.date', '2026-05-01');
    }

    public function test_installment_amounts_must_add_up_to_the_total_amount(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create();

        $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-01-01',
            'total_amount' => '300.00',
            'installments' => [
                ['amount' => '100.00', 'date' => '2026-01-10'],
                ['amount' => '150.00', 'date' => '2026-02-25'],
            ],
        ])->assertUnprocessable()->assertJsonValidationErrors('installments');
    }

    public function test_updating_the_period_regenerates_the_installment_schedule(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create();

        $transactionId = $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-01-01',
            'total_amount' => '90.00',
            'installments_count' => 3,
            'period_unit' => 'month',
            'period_interval' => 1,
        ])->json('data.id');

        // "Trocar o período do installment de 1 mês para 15 dias."
        $response = $this->withToken($token)->patchJson("/api/v1/transactions/{$transactionId}", [
            'period_unit' => 'day',
            'period_interval' => 15,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.schedule_type', 'periodic')
            ->assertJsonPath('data.period_unit', 'day')
            ->assertJsonPath('data.period_interval', 15)
            ->assertJsonCount(3, 'data.installments')
            ->assertJsonPath('data.installments.0.date', '2026-01-01')
            ->assertJsonPath('data.installments.1.date', '2026-01-16')
            ->assertJsonPath('data.installments.2.date', '2026-01-31');

        $this->assertDatabaseCount('installments', 3);
    }

    public function test_editing_a_simple_field_does_not_touch_the_schedule(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create();

        $transactionId = $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-01-01',
            'total_amount' => '90.00',
            'installments_count' => 3,
            'period_unit' => 'month',
        ])->json('data.id');

        $response = $this->withToken($token)->patchJson("/api/v1/transactions/{$transactionId}", [
            'description' => 'Updated note',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.description', 'Updated note')
            ->assertJsonCount(3, 'data.installments')
            ->assertJsonPath('data.installments.1.date', '2026-02-01');
    }

    public function test_schedule_cannot_change_once_an_installment_is_paid(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create();

        $transactionId = $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-01-01',
            'total_amount' => '90.00',
            'installments_count' => 3,
            'period_unit' => 'month',
        ])->json('data.id');

        $firstInstallmentId = Transaction::findOrFail($transactionId)
            ->installments()
            ->orderBy('step')
            ->firstOrFail()
            ->id;

        $this->withToken($token)
            ->patchJson("/api/v1/transactions/{$transactionId}/installments/{$firstInstallmentId}/pay")
            ->assertOk()
            ->assertJsonPath('data.status', 'paid');

        $this->withToken($token)
            ->patchJson("/api/v1/transactions/{$transactionId}", ['installments_count' => 6])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('installments');
    }

    public function test_deleting_a_transaction_soft_deletes_its_installments(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create();

        $transactionId = $this->withToken($token)->postJson('/api/v1/transactions', [
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-01-01',
            'total_amount' => '90.00',
            'installments_count' => 3,
            'period_unit' => 'month',
        ])->json('data.id');

        $installmentIds = Transaction::withTrashed()
            ->findOrFail($transactionId)
            ->installments()
            ->pluck('id');

        $this->withToken($token)
            ->deleteJson("/api/v1/transactions/{$transactionId}")
            ->assertNoContent();

        $this->assertSoftDeleted('transactions', ['id' => $transactionId]);

        foreach ($installmentIds as $installmentId) {
            $this->assertSoftDeleted('installments', ['id' => $installmentId]);
        }
    }

    public function test_guest_cannot_access_transactions(): void
    {
        $this->getJson('/api/v1/transactions')->assertUnauthorized();
    }

    public function test_transaction_is_a_404_not_a_403_for_another_users_transaction(): void
    {
        [, $token] = $this->authenticated();
        $otherUser = User::factory()->create();
        $category = Category::factory()->for($otherUser)->create();

        $transactionId = $otherUser->transactions()->create([
            'category_id' => $category->id,
            'type' => 'expense',
            'date' => '2026-01-01',
            'total_amount' => '10.00',
            'installments_count' => 1,
            'schedule_type' => 'single',
        ])->id;

        $this->withToken($token)
            ->getJson("/api/v1/transactions/{$transactionId}")
            ->assertNotFound();
    }
}
