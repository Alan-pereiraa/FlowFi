<?php

namespace App\Domains\Dashboard\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;

/**
 * Read-only aggregates over the caller's own ledger. Every amount returned here is integer cents.
 */
interface DashboardRepositoryInterface
{
    /**
     * Installment sums grouped by transaction type (income, expense or transfer) and installment status, for installments due
     * inside [$from, $to] (inclusive). Both bounds null means "all time".
     *
     * @return list<array{type: string, status: string, total: int, count: int}>
     */
    public function installmentTotals(User $user, ?CarbonImmutable $from, ?CarbonImmutable $to): array;

    /**
     * Pending installments due before $today, grouped by transaction type.
     *
     * @return list<array{type: string, total: int, count: int}>
     */
    public function overdueTotals(User $user, CarbonImmutable $today): array;

    /**
     * Expense installments due inside [$from, $to], grouped by category, biggest first.
     * Categories that were deleted afterwards still show up with their old name.
     *
     * @return list<array{category_id: int, name: ?string, icon: ?string, color: ?string, limit_amount: ?int, paid: int, pending: int, total: int}>
     */
    public function expensesByCategory(User $user, CarbonImmutable $from, CarbonImmutable $to): array;

    /**
     * Pending installments due on or before $until (overdue ones included), oldest due date first,
     * with `transaction.category` loaded.
     */
    public function upcomingInstallments(User $user, CarbonImmutable $until, int $limit): Collection;

    /**
     * Newest transactions first, with `category` and `goal` loaded (either can be null: a transfer has
     * no category, most other transactions have no goal) and a `paid_installments_count` attribute.
     */
    public function recentTransactions(User $user, int $limit): Collection;

    /**
     * Every live goal, closest deadline first and open-ended ones last. `current_amount` is kept up
     * to date by Ledger's TransactionService, so nothing has to be summed here.
     */
    public function goals(User $user): Collection;

    public function unreadNotificationsCount(User $user): int;
}
