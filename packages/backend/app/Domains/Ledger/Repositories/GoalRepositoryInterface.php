<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use Illuminate\Database\Eloquent\Collection;

interface GoalRepositoryInterface
{
    /**
     * @return Collection<int, Goal>
     */
    public function listFor(User $user): Collection;

    /**
     * Null when the id does not exist, is soft-deleted, or belongs to someone
     * else; the caller must not be able to tell those apart.
     */
    public function findFor(User $user, int $id): ?Goal;

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function create(User $user, array $attributes): Goal;

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(Goal $goal, array $attributes): Goal;

    public function delete(Goal $goal): void;
}
