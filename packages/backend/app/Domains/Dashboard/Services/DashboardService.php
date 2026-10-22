<?php

namespace App\Domains\Dashboard\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Services\GoalService;
use App\Domains\Ledger\Services\TransactionService;
use Carbon\CarbonImmutable;
use Illuminate\Support\Collection;

class DashboardService
{
    public const int DEFAULT_GOALS_LIMIT = 2;

    public const int DEFAULT_RECENT_LIMIT = 3;

    public function __construct(
        private readonly TransactionService $transactions,
        private readonly GoalService $goals,
    ) {}

    public function summary(User $user, ?string $month): array
    {
        $from = CarbonImmutable::createFromFormat('!Y-m', $month ?? CarbonImmutable::today()->format('Y-m'));

        $inMonth = $this->transactions->paidTotals($user, $from, $from->endOfMonth());
        $allTime = $this->transactions->paidTotals($user);

        return [
            'balance' => $allTime['income'] - $allTime['expense'],
            'income' => $inMonth['income'],
            'expense' => $inMonth['expense'],
        ];
    }

    public function recentGoals(User $user, int $limit): Collection
    {
        return $this->goals->latest($user, $limit);
    }

    public function recentTransactions(User $user, int $limit): Collection
    {
        return $this->transactions->latest($user, $limit, CarbonImmutable::today());
    }
}
