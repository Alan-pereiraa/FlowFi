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

    /**
     * @return Collection<int, Category>
     */
    public function list(User $user): Collection
    {
        return $this->categories->listFor($user);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function create(User $user, array $data): Category
    {
        return $this->categories->create($user, $this->appearance->normalize($data));
    }

    /**
     * Resolve the category a caller is entitled to act on.
     *
     * The repository scopes by owner, so a foreign id and a nonexistent id
     * both come back null and both answer 404: a 403 would confirm the
     * category exists. The message is deliberately generic; setModel() would
     * echo the internal class name and the id even with APP_DEBUG off.
     *
     * @throws ModelNotFoundException
     */
    public function findOwned(User $user, int $id): Category
    {
        return $this->categories->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    /**
     * Icon and color go through the shared AppearanceService; everything else
     * through this domain's repository. One transaction so a partial update
     * never lands.
     *
     * @param  array<string, mixed>  $data
     */
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
