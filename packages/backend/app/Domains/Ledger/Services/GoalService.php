<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Ledger\Repositories\GoalRepositoryInterface;
use App\Domains\Shared\Services\AppearanceService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class GoalService
{
    public function __construct(
        private readonly GoalRepositoryInterface $goals,
        private readonly AppearanceService $appearance,
    ) {}

    /**
     * @return Collection<int, Goal>
     */
    public function list(User $user): Collection
    {
        return $this->goals->listFor($user);
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function create(User $user, array $data): Goal
    {
        return $this->goals->create($user, $this->appearance->normalize($data));
    }

    /**
     * Resolve the goal a caller is entitled to act on.
     *
     * The repository scopes by owner, so a foreign id and a nonexistent id
     * both come back null and both answer 404: a 403 would confirm the goal
     * exists. The message is deliberately generic; setModel() would echo the
     * internal class name and the id even with APP_DEBUG off.
     *
     * @throws ModelNotFoundException
     */
    public function findOwned(User $user, int $id): Goal
    {
        return $this->goals->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    /**
     * Icon and color go through the shared AppearanceService; everything else
     * through this domain's repository. One transaction so a partial update
     * never lands.
     *
     * @param  array<string, mixed>  $data
     */
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
        $this->goals->delete($goal);
    }
}
