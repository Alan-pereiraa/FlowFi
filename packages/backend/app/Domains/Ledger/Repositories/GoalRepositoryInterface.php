<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use Illuminate\Database\Eloquent\Collection;

interface GoalRepositoryInterface
{
    public function listFor(User $user): Collection;

    public function findFor(User $user, int $id): ?Goal;

    public function create(User $user, array $attributes): Goal;

    public function update(Goal $goal, array $attributes): Goal;

    public function delete(Goal $goal): void;
}
