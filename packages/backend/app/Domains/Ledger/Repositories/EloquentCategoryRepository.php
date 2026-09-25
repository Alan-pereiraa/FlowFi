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

    public function spentInMonthCents(Category $category, CarbonImmutable $month, ?int $ignoreTransactionId = null): int
    {
        return (int) Installment::query()
            ->whereBetween('date', [$month->startOfMonth()->toDateString(), $month->endOfMonth()->toDateString()])
            ->whereHas('transaction', fn ($query) => $query
                ->where('category_id', $category->id)
                ->where('type', Transaction::TYPE_EXPENSE)
                ->when($ignoreTransactionId, fn ($query, $id) => $query->whereKeyNot($id)))
            ->sum('amount');
    }
}
