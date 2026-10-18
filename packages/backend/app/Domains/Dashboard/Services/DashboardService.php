<?php

namespace App\Domains\Dashboard\Services;

use App\Domains\Dashboard\Repositories\DashboardRepositoryInterface;
use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Shared\Casts\Money;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;

/**
 * Read-only home-screen numbers. Amounts stay integer cents all the way through (the Resources turn
 * them into decimal strings); the only floats here are display percentages.
 *
 * Money "moves" through installments, not transactions: a transaction counts in the month its
 * installments are due, and an installment is real money only once it is `paid`. Transfers (money set
 * aside into a goal) are neither income nor expense and never touch the balances.
 */
class DashboardService
{
    public const int DEFAULT_UPCOMING_DAYS = 30;

    public const int DEFAULT_UPCOMING_LIMIT = 10;

    public const int DEFAULT_RECENT_LIMIT = 5;

    public function __construct(
        private readonly DashboardRepositoryInterface $dashboard,
    ) {}

    /**
     * Every block of the home screen, in one payload.
     */
    public function overview(User $user, ?string $month): array
    {
        $period = $this->period($month);

        return [
            'summary' => $this->buildSummary($user, $period),
            'spending_by_category' => $this->buildSpendingByCategory($user, $period),
            'upcoming_installments' => $this->upcomingInstallments($user, self::DEFAULT_UPCOMING_DAYS, self::DEFAULT_UPCOMING_LIMIT),
            'recent_transactions' => $this->recentTransactions($user, self::DEFAULT_RECENT_LIMIT),
            'goals' => $this->goals($user),
            'unread_notifications' => $this->dashboard->unreadNotificationsCount($user),
        ];
    }

    public function summary(User $user, ?string $month): array
    {
        return $this->buildSummary($user, $this->period($month));
    }

    public function spendingByCategory(User $user, ?string $month): array
    {
        return $this->buildSpendingByCategory($user, $this->period($month));
    }

    public function upcomingInstallments(User $user, int $days, int $limit): Collection
    {
        return $this->dashboard->upcomingInstallments($user, CarbonImmutable::today()->addDays($days), $limit);
    }

    public function recentTransactions(User $user, int $limit): Collection
    {
        return $this->dashboard->recentTransactions($user, $limit);
    }

    /**
     * @return list<array{goal: Goal, progress_percent: float}>
     */
    public function goals(User $user): array
    {
        return $this->dashboard->goals($user)->map(fn (Goal $goal): array => [
            'goal' => $goal,
            'progress_percent' => $this->percent(
                Money::toCents($goal->current_amount, 'current_amount'),
                Money::toCents($goal->target_amount, 'target_amount'),
            ),
        ])->all();
    }

    /**
     * @return array{month: string, from: CarbonImmutable, to: CarbonImmutable}
     */
    private function period(?string $month): array
    {
        $from = CarbonImmutable::createFromFormat('Y-m-d', ($month ?? CarbonImmutable::today()->format('Y-m')).'-01')->startOfDay();

        return [
            'month' => $from->format('Y-m'),
            'from' => $from,
            'to' => $from->endOfMonth()->startOfDay(),
        ];
    }

    private function buildSummary(User $user, array $period): array
    {
        $month = $this->bucket($this->dashboard->installmentTotals($user, $period['from'], $period['to']));
        $allTime = $this->bucket($this->dashboard->installmentTotals($user, null, null));

        $overdue = ['expense' => ['count' => 0, 'total' => 0], 'income' => ['count' => 0, 'total' => 0]];
        foreach ($this->dashboard->overdueTotals($user, CarbonImmutable::today()) as $row) {
            if (isset($overdue[$row['type']])) {
                $overdue[$row['type']] = ['count' => $row['count'], 'total' => $row['total']];
            }
        }

        return [
            'period' => $this->describe($period),
            'income' => $month['income'],
            'expense' => $month['expense'],
            // Realized: only what was actually received/paid.
            'balance' => $month['income']['paid'] - $month['expense']['paid'],
            // Planned: everything due in the month, paid or not.
            'projected_balance' => $month['income']['total'] - $month['expense']['total'],
            // Transfers are not part of any of the figures above: they move money into a goal, they do
            // not earn or spend it. They get their own line.
            'balance_to_date' => $allTime['income']['paid'] - $allTime['expense']['paid'],
            'transferred_to_goals' => $month['transfer']['paid'],
            'overdue' => $overdue,
        ];
    }

    private function buildSpendingByCategory(User $user, array $period): array
    {
        $categories = array_map(function (array $row): array {
            // `categories.limit_amount` has no period in the ERD (open point); the dashboard reads it
            // as a monthly cap, since the rows it is compared with are a single month.
            return [
                ...$row,
                'limit_used_percent' => $row['limit_amount'] === null ? null : $this->percent($row['total'], $row['limit_amount']),
            ];
        }, $this->dashboard->expensesByCategory($user, $period['from'], $period['to']));

        return [
            'period' => $this->describe($period),
            'categories' => $categories,
        ];
    }

    /**
     * @param  list<array{type: string, status: string, total: int, count: int}>  $rows
     * @return array{income: array{paid: int, pending: int, total: int}, expense: array{paid: int, pending: int, total: int}, transfer: array{paid: int, pending: int, total: int}}
     */
    private function bucket(array $rows): array
    {
        $sums = [
            'income' => ['paid' => 0, 'pending' => 0, 'total' => 0],
            'expense' => ['paid' => 0, 'pending' => 0, 'total' => 0],
            'transfer' => ['paid' => 0, 'pending' => 0, 'total' => 0],
        ];

        foreach ($rows as $row) {
            if (! isset($sums[$row['type']][$row['status']])) {
                continue;
            }

            $sums[$row['type']][$row['status']] += $row['total'];
            $sums[$row['type']]['total'] += $row['total'];
        }

        return $sums;
    }

    private function describe(array $period): array
    {
        return [
            'month' => $period['month'],
            'from' => $period['from']->toDateString(),
            'to' => $period['to']->toDateString(),
        ];
    }

    private function percent(int $part, int $whole): float
    {
        return $whole > 0 ? round($part * 100 / $whole, 1) : 0.0;
    }
}
