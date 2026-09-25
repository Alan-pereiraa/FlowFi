<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;

interface CategoryRepositoryInterface
{
    public function listFor(User $user): Collection;

    public function findFor(User $user, int $id): ?Category;

    public function create(User $user, array $attributes): Category;

    public function update(Category $category, array $attributes): Category;

    public function delete(Category $category): void;

    public function findForLimitCheck(int $categoryId): Category;

    public function spentInMonthCents(Category $category, CarbonImmutable $month, ?int $ignoreTransactionId = null): int;
}
