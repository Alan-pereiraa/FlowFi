<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use Illuminate\Database\Eloquent\Collection;

class EloquentGoalRepository implements GoalRepositoryInterface
{
    public function listFor(User $user): Collection
    {
        return $user->goals()->orderBy('created_at')->orderBy('id')->get();
    }

    public function findFor(User $user, int $id): ?Goal
    {
        return $user->goals()->find($id);
    }

    public function create(User $user, array $attributes): Goal
    {
        return $user->goals()->create($attributes);
    }

    public function update(Goal $goal, array $attributes): Goal
    {
        $goal->forceFill($attributes)->save();

        return $goal;
    }

    public function delete(Goal $goal): void
    {
        $goal->delete();
    }
}
