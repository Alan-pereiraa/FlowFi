<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Repositories\CategoryRepositoryInterface;
use App\Domains\Shared\Services\AppearanceService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class CategoryService
{
    public function __construct(
        private readonly CategoryRepositoryInterface $categories,
        private readonly AppearanceService $appearance,
    ) {}

    public function list(User $user): Collection
    {
        return $this->categories->listFor($user);
    }

    public function create(User $user, array $data): Category
    {
        return $this->categories->create($user, $this->appearance->normalize($data));
    }

    public function findOwned(User $user, int $id): Category
    {
        return $this->categories->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function update(Category $category, array $data): Category
    {
        return DB::transaction(function () use ($category, $data): Category {
            $this->appearance->apply($category, $data);

            $rest = Arr::except($data, ['icon', 'color']);

            if ($rest !== []) {
                $this->categories->update($category, $rest);
            }

            return $category;
        });
    }

    public function delete(Category $category): void
    {
        $this->categories->delete($category);
    }
}
