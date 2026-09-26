<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Ledger\Repositories\GoalRepositoryInterface;
use App\Domains\Shared\Services\AppearanceService;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class GoalService
{
    public function __construct(
        private readonly GoalRepositoryInterface $goals,
        private readonly AppearanceService $appearance,
    ) {}

    public function list(User $user): Collection
    {
        return $this->goals->listFor($user);
    }

    public function create(User $user, array $data): Goal
    {
        return $this->goals->create($user, $this->appearance->normalize($data));
    }

    public function findOwned(User $user, int $id): Goal
    {
        return $this->goals->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function update(Goal $goal, array $data): Goal
    {
        return DB::transaction(function () use ($goal, $data): Goal {
            $this->appearance->apply($goal, $data);

            $rest = Arr::except($data, ['icon', 'color']);

            if ($rest !== []) {
                $this->goals->update($goal, $rest);
            }

            return $goal;
        });
    }

    public function delete(Goal $goal): void
    {
        if ($this->goals->hasTransactions($goal)) {
            throw ValidationException::withMessages([
                'goal' => 'Cannot delete a goal that has transactions.',
            ]);
        }

        $this->goals->delete($goal);
    }

    public function adjustCurrentAmount(int $goalId, int $cents): void
    {
        if ($cents === 0) {
            return;
        }

        if (! $this->goals->adjustCurrentAmount($goalId, $cents)) {
            throw ValidationException::withMessages([
                'goal_id' => 'The goal does not have enough balance for this transaction.',
            ]);
        }
    }

    public function unreachedExpiringBetween(CarbonInterface $from, CarbonInterface $to): Collection
    {
        return $this->goals->unreachedExpiringBetween($from, $to);
    }
}
