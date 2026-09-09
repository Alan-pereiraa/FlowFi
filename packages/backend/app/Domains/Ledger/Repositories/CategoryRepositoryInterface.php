<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use Illuminate\Database\Eloquent\Collection;

interface CategoryRepositoryInterface
{
    /**
     * @return Collection<int, Category>
     */
    public function listFor(User $user): Collection;

    /**
     * Null when the id does not exist, is soft-deleted, or belongs to someone
     * else; the caller must not be able to tell those apart.
     */
    public function findFor(User $user, int $id): ?Category;

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(User $user, array $attributes): Category;

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(Category $category, array $attributes): Category;

    public function delete(Category $category): void;
}
