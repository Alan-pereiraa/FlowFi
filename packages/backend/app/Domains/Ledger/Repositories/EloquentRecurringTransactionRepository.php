<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\RecurringTransaction;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Collection;

class EloquentRecurringTransactionRepository implements RecurringTransactionRepositoryInterface
{
    public function listFor(User $user): Collection
    {
        return $user->recurringTransactions()->orderBy('start_date')->orderBy('id')->get();
    }

    public function findFor(User $user, int $id): ?RecurringTransaction
    {
        return $user->recurringTransactions()->find($id);
    }

    public function create(User $user, array $attributes): RecurringTransaction
    {
        return $user->recurringTransactions()->create($attributes);
    }

    public function update(RecurringTransaction $recurring, array $attributes): RecurringTransaction
    {
        $recurring->forceFill($attributes)->save();

        return $recurring;
    }

    public function delete(RecurringTransaction $recurring): void
    {
        $recurring->delete();
    }

    public function dueOn(CarbonInterface $date): Collection
    {
        return RecurringTransaction::query()
            ->whereNotNull('next_occurrence_on')
            ->whereDate('next_occurrence_on', '<=', $date->toDateString())
            ->whereHas('user')
            ->with(['user', 'goal'])
            ->orderBy('id')
            ->get();
    }
}
