<?php

namespace Tests\Feature\Dashboard;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Notification\Models\Notification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

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

        // "Today" is the 15th, so the 1st is overdue and the 25th is still ahead.
        $this->travelTo('2026-09-15 12:00:00');
    }

    /** @return array{0: User, 1: string} */
    private function authenticated(): array
    {
        $user = User::factory()->create();

        return [$user, $user->createToken('api')->plainTextToken];
    }

    /**
     * @param  list<array{0: string, 1: string, 2?: string}>  $installments  [amount, date, status = pending]
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

        foreach ($installments as $step => $row) {
            Installment::factory()->for($transaction)->create([
                'step' => $step + 1,
                'amount' => $row[0],
                'date' => $row[1],
                'status' => $row[2] ?? Installment::STATUS_PENDING,
                'paid_at' => ($row[2] ?? null) === Installment::STATUS_PAID ? now() : null,
            ]);
        }

        return $transaction;
    }

    public function test_guest_cannot_access_the_dashboard(): void
    {
        foreach (self::ROUTES as $route) {
            $this->getJson($route)->assertUnauthorized();
        }
    }

    public function test_summary_splits_the_month_into_paid_and_pending(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'income', [['1000.00', '2026-09-05', 'paid']]);
        $this->transaction($user, 'income', [['500.00', '2026-09-20']]);
        $this->transaction($user, 'expense', [['200.00', '2026-09-02', 'paid']]);
        // 300.00 in three monthly installments: only September's two belong to this month.
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

    public function test_month_boundaries_are_inclusive_on_both_ends(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'expense', [['10.00', '2026-08-31']]);
        $this->transaction($user, 'expense', [['20.00', '2026-09-01']]);
        $this->transaction($user, 'expense', [['40.00', '2026-09-30']]);
        $this->transaction($user, 'expense', [['80.00', '2026-10-01']]);

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.expense.total', '60.00');
    }

    public function test_balance_to_date_covers_every_paid_installment_regardless_of_month(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'income', [['1000.00', '2026-06-05', 'paid']]);
        $this->transaction($user, 'expense', [['250.50', '2026-08-10', 'paid']]);
        $this->transaction($user, 'expense', [['999.00', '2026-09-28']]); // pending: not money yet

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.balance', '0.00')
            ->assertJsonPath('data.balance_to_date', '749.50');
    }

    public function test_balance_can_go_negative(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'expense', [['75.25', '2026-09-03', 'paid']]);

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.balance', '-75.25');
    }

    public function test_summary_reports_overdue_installments_from_any_month(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'expense', [['30.00', '2026-07-01'], ['20.00', '2026-09-01']]);
        $this->transaction($user, 'expense', [['99.00', '2026-09-15']]);          // due today: not overdue
        $this->transaction($user, 'expense', [['11.00', '2026-08-01', 'paid']]);  // paid: not overdue
        $this->transaction($user, 'income', [['400.00', '2026-09-10']]);

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.overdue.expense', ['count' => 2, 'amount' => '50.00'])
            ->assertJsonPath('data.overdue.income', ['count' => 1, 'amount' => '400.00']);
    }

    public function test_summary_is_all_zeros_for_an_empty_account(): void
    {
        [, $token] = $this->authenticated();

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

    public function test_other_accounts_and_deleted_rows_never_leak_into_the_numbers(): void
    {
        [$user, $token] = $this->authenticated();
        $stranger = User::factory()->create();

        $this->transaction($user, 'expense', [['10.00', '2026-09-05']]);
        $this->transaction($stranger, 'expense', [['5000.00', '2026-09-05', 'paid']]);

        $deletedTransaction = $this->transaction($user, 'expense', [['700.00', '2026-09-06']]);
        $deletedTransaction->installments()->delete();
        $deletedTransaction->delete();

        $keptTransaction = $this->transaction($user, 'expense', [['3.00', '2026-09-07'], ['900.00', '2026-09-08']]);
        $keptTransaction->installments()->where('step', 2)->delete();

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertJsonPath('data.expense.total', '13.00')
            ->assertJsonPath('data.balance_to_date', '0.00');

        $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions')
            ->assertJsonCount(2, 'data');
    }

    public function test_month_must_be_a_valid_year_month(): void
    {
        [, $token] = $this->authenticated();

        foreach (['2026-13', '2026-00', '2026-9', '26-09', 'september', '2026-09-01'] as $month) {
            $this->withToken($token)->getJson('/api/v1/dashboard?month='.$month)
                ->assertUnprocessable()
                ->assertJsonValidationErrors('month');
        }
    }

    public function test_spending_by_category_ranks_expenses_and_measures_the_limit(): void
    {
        [$user, $token] = $this->authenticated();

        $food = Category::factory()->for($user)->create(['name' => 'Food', 'limit_amount' => '400.00']);
        $fun = Category::factory()->for($user)->create(['name' => 'Fun', 'limit_amount' => null]);
        $salary = Category::factory()->for($user)->create(['name' => 'Salary']);

        $this->transaction($user, 'expense', [['100.00', '2026-09-02', 'paid'], ['100.00', '2026-09-20']], $food);
        $this->transaction($user, 'expense', [['50.00', '2026-09-04', 'paid']], $food);
        $this->transaction($user, 'expense', [['300.00', '2026-09-12']], $fun);
        $this->transaction($user, 'expense', [['70.00', '2026-10-02']], $fun);   // other month
        $this->transaction($user, 'income', [['3000.00', '2026-09-01', 'paid']], $salary);

        $response = $this->withToken($token)->getJson('/api/v1/dashboard/spending-by-category?month=2026-09')
            ->assertOk()
            ->assertJsonPath('data.period.month', '2026-09')
            ->assertJsonCount(2, 'data.categories');

        // Biggest spender first.
        $this->assertSame(['Fun', 'Food'], array_column(array_column($response->json('data.categories'), 'category'), 'name'));

        $response->assertJsonPath('data.categories.0.total', '300.00')
            ->assertJsonPath('data.categories.0.paid', '0.00')
            ->assertJsonPath('data.categories.0.pending', '300.00')
            ->assertJsonPath('data.categories.0.limit_amount', null)
            ->assertJsonPath('data.categories.0.limit_used_percent', null)
            ->assertJsonPath('data.categories.1.category.id', $food->id)
            ->assertJsonPath('data.categories.1.paid', '150.00')
            ->assertJsonPath('data.categories.1.pending', '100.00')
            ->assertJsonPath('data.categories.1.total', '250.00')
            ->assertJsonPath('data.categories.1.limit_amount', '400.00')
            ->assertJsonPath('data.categories.1.limit_used_percent', 62.5);
    }

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

    public function test_upcoming_installments_lists_overdue_first_and_skips_paid_and_far_ones(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['name' => 'Rent']);

        $this->transaction($user, 'expense', [['10.00', '2026-08-20']], $category, ['description' => 'Late one']); // overdue
        $this->transaction($user, 'expense', [['20.00', '2026-09-15']], $category);                                // today
        $this->transaction($user, 'expense', [['30.00', '2026-09-25']], $category);
        $this->transaction($user, 'expense', [['40.00', '2026-09-10', 'paid']], $category);                         // paid
        $this->transaction($user, 'expense', [['50.00', '2026-11-30']], $category);                                // beyond 30 days

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

        $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments?days=90')
            ->assertJsonCount(4, 'data');

        $this->withToken($token)->getJson('/api/v1/dashboard/upcoming-installments?limit=1')
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.amount', '10.00');
    }

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

    public function test_recent_transactions_are_newest_first_with_a_payment_status(): void
    {
        [$user, $token] = $this->authenticated();
        $category = Category::factory()->for($user)->create(['name' => 'Market', 'icon' => 'shopping_cart', 'color' => '#4CAF50']);

        $this->transaction($user, 'expense', [['10.00', '2026-09-01', 'paid']], $category, ['description' => 'Paid']);
        $this->transaction($user, 'expense', [['10.00', '2026-09-05', 'paid'], ['10.00', '2026-10-05']], $category, ['description' => 'Partial']);
        $this->transaction($user, 'income', [['10.00', '2026-09-09']], $category, ['description' => 'Pending']);

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

        $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions?limit=21')
            ->assertUnprocessable()->assertJsonValidationErrors('limit');
    }

    public function test_goals_report_their_saved_balance_and_progress(): void
    {
        [$user, $token] = $this->authenticated();

        $later = Goal::factory()->for($user)->create(['name' => 'Car', 'target_amount' => '10000.00', 'current_amount' => '0.00', 'expires_at' => '2027-12-01']);
        $sooner = Goal::factory()->for($user)->create(['name' => 'Trip', 'target_amount' => '2000.00', 'current_amount' => '600.00', 'expires_at' => '2027-01-01']);
        $open = Goal::factory()->for($user)->create(['name' => 'Rainy day', 'target_amount' => '500.00', 'current_amount' => '125.00', 'expires_at' => null]);
        Goal::factory()->for(User::factory()->create())->create(['current_amount' => '999.00']);
        Goal::factory()->for($user)->create(['current_amount' => '0.00'])->delete();

        $response = $this->withToken($token)->getJson('/api/v1/dashboard/goals')
            ->assertOk()
            ->assertJsonCount(3, 'data');

        // Closest deadline first, open-ended goals last.
        $this->assertSame(['Trip', 'Car', 'Rainy day'], array_column($response->json('data'), 'name'));

        $response->assertJsonPath('data.0.id', $sooner->id)
            ->assertJsonPath('data.0.target_amount', '2000.00')
            ->assertJsonPath('data.0.current_amount', '600.00')
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

    public function test_transfers_to_goals_never_count_as_income_expense_or_balance(): void
    {
        [$user, $token] = $this->authenticated();
        $goal = Goal::factory()->for($user)->create(['name' => 'Trip', 'icon' => 'flight', 'color' => '#FF9800']);

        $this->transaction($user, 'income', [['1000.00', '2026-09-01', 'paid']]);
        $this->transaction($user, 'expense', [['100.00', '2026-09-02', 'paid']]);
        // A transfer is created already paid and has no category.
        $this->transaction($user, 'transfer', [['250.00', '2026-09-03', 'paid']], false, ['goal_id' => $goal->id]);
        $this->transaction($user, 'transfer', [['40.00', '2026-08-30', 'paid']], false, ['goal_id' => $goal->id]);

        $this->withToken($token)->getJson('/api/v1/dashboard/summary?month=2026-09')
            ->assertOk()
            ->assertJsonPath('data.income.total', '1000.00')
            ->assertJsonPath('data.expense.total', '100.00')
            ->assertJsonPath('data.balance', '900.00')
            ->assertJsonPath('data.projected_balance', '900.00')
            ->assertJsonPath('data.balance_to_date', '900.00')
            ->assertJsonPath('data.transferred_to_goals', '250.00');

        $this->withToken($token)->getJson('/api/v1/dashboard/spending-by-category?month=2026-09')
            ->assertJsonCount(1, 'data.categories');

        $this->withToken($token)->getJson('/api/v1/dashboard/recent-transactions')
            ->assertOk()
            ->assertJsonPath('data.0.type', 'transfer')
            ->assertJsonPath('data.0.total_amount', '250.00')
            ->assertJsonPath('data.0.status', 'paid')
            ->assertJsonPath('data.0.category', null)
            ->assertJsonPath('data.0.goal', ['id' => $goal->id, 'name' => 'Trip', 'icon' => 'flight', 'color' => '#FF9800'])
            ->assertJsonPath('data.2.goal', null);
    }

    public function test_overview_bundles_every_block_for_the_current_month(): void
    {
        [$user, $token] = $this->authenticated();

        $this->transaction($user, 'income', [['100.00', '2026-09-02', 'paid']]);
        $this->transaction($user, 'expense', [['40.00', '2026-09-20']]);
        Goal::factory()->for($user)->create();
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
