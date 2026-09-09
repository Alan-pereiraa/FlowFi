<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
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
}
