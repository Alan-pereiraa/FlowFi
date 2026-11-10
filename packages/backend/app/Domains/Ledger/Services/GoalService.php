<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use App\Domains\Ledger\Repositories\GoalRepositoryInterface;
use App\Domains\Shared\Casts\Money;
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
            ?? throw new ModelNotFoundException('Não encontrado.');
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
        if (Money::toCents($goal->current_amount) > 0) {
            throw ValidationException::withMessages([
                'goal' => 'Resgate o saldo da meta antes de excluí-la.',
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
            if ($this->goals->isDeleted($goalId)) {
                throw ValidationException::withMessages([
                    'goal_id' => 'A meta desta transação foi excluída.',
                ]);
            }

            throw ValidationException::withMessages([
                'goal_id' => 'A meta não tem saldo suficiente para esta transação.',
            ]);
        }
    }

    public function ensureCanWithdraw(User $user, int $goalId, int $cents): void
    {
        $saved = Money::toCents($this->findOwned($user, $goalId)->current_amount);

        if ($cents > $saved) {
            throw ValidationException::withMessages([
                'total_amount' => 'O resgate não pode ser maior que o valor guardado na meta ('.Money::toBrl($saved).').',
            ]);
        }
    }

    public function unreachedExpiringBetween(CarbonInterface $from, CarbonInterface $to): Collection
    {
        return $this->goals->unreachedExpiringBetween($from, $to);
    }
}
