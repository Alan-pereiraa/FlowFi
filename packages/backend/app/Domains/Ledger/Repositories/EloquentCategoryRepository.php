<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;

class EloquentCategoryRepository implements CategoryRepositoryInterface
{
    public function listFor(User $user): Collection
    {
        return $user->categories()->orderBy('created_at')->orderBy('id')->get();
    }

    public function findFor(User $user, int $id): ?Category
    {
        return $user->categories()->find($id);
    }

    public function create(User $user, array $attributes): Category
    {
        return $user->categories()->create($attributes);
    }

    public function update(Category $category, array $attributes): Category
    {
        $category->forceFill($attributes)->save();

        return $category;
    }

    public function delete(Category $category): void
    {
        $category->delete();
    }

    public function findForLimitCheck(int $categoryId): Category
    {
        return Category::whereKey($categoryId)
            ->lockForUpdate()
            ->firstOrfail();
    }

    public function recordLimitAlert(Category $category, ?int $level, string $month): void
    {
        $category->forceFill(['limit_alert_level' => $level, 'limit_alert_month' => $month])->save();
    }

    public function detachFromTransactions(Category $category): void
    {
        $category->transactions()->withTrashed()->update(['category_id' => null]);
        $category->recurringTransactions()->withTrashed()->update(['category_id' => null]);
    }

    public function usedInMonthCents(Category $category, CarbonImmutable $month, ?int $ignoreTransactionId = null): int
    {
        [$from, $to] = $this->monthBounds($month);

        if ($category->isIncome()) {
            return (int) Transaction::query()
                ->where('category_id', $category->id)
                ->where('type', Transaction::TYPE_INCOME)
                ->whereDate('date', '>=', $from)
                ->whereDate('date', '<=', $to)
                ->when($ignoreTransactionId, fn ($query, $id) => $query->whereKeyNot($id))
                ->sum('total_amount');
        }

        return (int) Installment::query()
            ->whereDate('date', '>=', $from)
            ->whereDate('date', '<=', $to)
            ->whereHas('transaction', fn ($query) => $query
                ->where('category_id', $category->id)
                ->where('type', Transaction::TYPE_EXPENSE)
                ->when($ignoreTransactionId, fn ($query, $id) => $query->whereKeyNot($id)))
            ->sum('amount');
    }

    public function usageInMonthCents(User $user, CarbonImmutable $month): array
    {
        [$from, $to] = $this->monthBounds($month);

        $expenses = Installment::query()
            ->join('transactions', 'transactions.id', '=', 'installments.transaction_id')
            ->join('categories', 'categories.id', '=', 'transactions.category_id')
            ->where('transactions.user_id', $user->id)
            ->where('transactions.type', Transaction::TYPE_EXPENSE)
            ->where('categories.type', Category::TYPE_EXPENSE)
            ->whereNull('transactions.deleted_at')
            ->whereDate('installments.date', '>=', $from)
            ->whereDate('installments.date', '<=', $to)
            ->groupBy('transactions.category_id')
            ->selectRaw('transactions.category_id as category_id, SUM(installments.amount) as total')
            ->toBase()
            ->pluck('total', 'category_id');

        $incomes = $user->transactions()
            ->join('categories', 'categories.id', '=', 'transactions.category_id')
            ->where('transactions.type', Transaction::TYPE_INCOME)
            ->where('categories.type', Category::TYPE_INCOME)
            ->whereDate('transactions.date', '>=', $from)
            ->whereDate('transactions.date', '<=', $to)
            ->groupBy('transactions.category_id')
            ->selectRaw('transactions.category_id as category_id, SUM(transactions.total_amount) as total')
            ->toBase()
            ->pluck('total', 'category_id');

        return $expenses->union($incomes)
            ->mapWithKeys(fn ($total, $categoryId) => [(int) $categoryId => (int) $total])
            ->all();
    }

    private function monthBounds(CarbonImmutable $month): array
    {
        return [$month->startOfMonth()->toDateString(), $month->endOfMonth()->toDateString()];
    }
}
