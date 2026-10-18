<?php

namespace App\Domains\Dashboard\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EloquentDashboardRepository implements DashboardRepositoryInterface
{
    public function installmentTotals(User $user, ?CarbonImmutable $from, ?CarbonImmutable $to): array
    {
        return $this->installmentsOf($user)
            ->when($from, fn ($query) => $query->whereDate('installments.date', '>=', $from->toDateString()))
            ->when($to, fn ($query) => $query->whereDate('installments.date', '<=', $to->toDateString()))
            ->selectRaw('transactions.type as type, installments.status as status, SUM(installments.amount) as total, COUNT(*) as count')
            ->groupBy('transactions.type', 'installments.status')
            ->toBase()
            ->get()
            ->map(fn ($row) => [
                'type' => $row->type,
                'status' => $row->status,
                'total' => (int) $row->total,
                'count' => (int) $row->count,
            ])
            ->all();
    }

    public function overdueTotals(User $user, CarbonImmutable $today): array
    {
        return $this->installmentsOf($user)
            ->where('installments.status', Installment::STATUS_PENDING)
            ->where('transactions.type', '!=', Transaction::TYPE_TRANSFER)
            ->whereDate('installments.date', '<', $today->toDateString())
            ->selectRaw('transactions.type as type, SUM(installments.amount) as total, COUNT(*) as count')
            ->groupBy('transactions.type')
            ->toBase()
            ->get()
            ->map(fn ($row) => [
                'type' => $row->type,
                'total' => (int) $row->total,
                'count' => (int) $row->count,
            ])
            ->all();
    }

    public function expensesByCategory(User $user, CarbonImmutable $from, CarbonImmutable $to): array
    {
        $paid = Installment::STATUS_PAID;
        $pending = Installment::STATUS_PENDING;

        return $this->installmentsOf($user)
            ->leftJoin('categories', 'categories.id', '=', 'transactions.category_id')
            ->where('transactions.type', Transaction::TYPE_EXPENSE)
            ->whereDate('installments.date', '>=', $from->toDateString())
            ->whereDate('installments.date', '<=', $to->toDateString())
            ->selectRaw(
                'transactions.category_id as category_id, categories.name as name, categories.icon as icon, '
                .'categories.color as color, categories.limit_amount as limit_amount, '
                ."SUM(CASE WHEN installments.status = '{$paid}' THEN installments.amount ELSE 0 END) as paid, "
                ."SUM(CASE WHEN installments.status = '{$pending}' THEN installments.amount ELSE 0 END) as pending, "
                .'SUM(installments.amount) as total'
            )
            ->groupBy(
                'transactions.category_id',
                'categories.name',
                'categories.icon',
                'categories.color',
                'categories.limit_amount',
            )
            ->orderByDesc('total')
            ->orderBy('transactions.category_id')
            ->toBase()
            ->get()
            ->map(fn ($row) => [
                'category_id' => (int) $row->category_id,
                'name' => $row->name,
                'icon' => $row->icon,
                'color' => $row->color,
                'limit_amount' => $row->limit_amount === null ? null : (int) $row->limit_amount,
                'paid' => (int) $row->paid,
                'pending' => (int) $row->pending,
                'total' => (int) $row->total,
            ])
            ->all();
    }

    public function upcomingInstallments(User $user, CarbonImmutable $until, int $limit): Collection
    {
        return Installment::query()
            ->whereIn('transaction_id', $user->transactions()
                ->where('type', '!=', Transaction::TYPE_TRANSFER)
                ->select('transactions.id'))
            ->where('status', Installment::STATUS_PENDING)
            ->whereDate('date', '<=', $until->toDateString())
            ->with(['transaction.category' => fn ($query) => $query->withTrashed()])
            ->orderBy('date')
            ->orderBy('id')
            ->limit($limit)
            ->get();
    }

    public function recentTransactions(User $user, int $limit): Collection
    {
        return $user->transactions()
            ->with([
                'category' => fn ($query) => $query->withTrashed(),
                'goal' => fn ($query) => $query->withTrashed(),
            ])
            ->withCount(['installments as paid_installments_count' => fn ($query) => $query->where('status', Installment::STATUS_PAID)])
            ->orderByDesc('date')
            ->orderByDesc('id')
            ->limit($limit)
            ->get();
    }

    public function goals(User $user): Collection
    {
        return $user->goals()
            ->orderByRaw('expires_at IS NULL')
            ->orderBy('expires_at')
            ->orderBy('id')
            ->get();
    }

    public function unreadNotificationsCount(User $user): int
    {
        return $user->notifications()->whereNull('read_at')->count();
    }

    /**
     * The caller's live transactions joined to their live installments. Scoping goes through
     * `User::transactions()`, so another account's rows can never leak into an aggregate; the
     * transactions' soft-delete scope is applied by Eloquent, the installments' by hand because
     * the join bypasses their model.
     */
    private function installmentsOf(User $user): HasMany
    {
        return $user->transactions()
            ->join('installments', 'installments.transaction_id', '=', 'transactions.id')
            ->whereNull('installments.deleted_at');
    }
}
