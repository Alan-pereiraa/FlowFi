<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Transaction;
use Illuminate\Database\Eloquent\Collection;

class EloquentTransactionRepository implements TransactionRepositoryInterface
{
    public function listFor(User $user): Collection
    {
        return $user->transactions()
            ->with('installments')
            ->orderBy('date', 'desc')
            ->orderBy('id', 'desc')
            ->get();
    }

    public function findFor(User $user, int $id): ?Transaction
    {
        return $user->transactions()->with('installments')->find($id);
    }

    public function create(User $user, array $attributes): Transaction
    {
        return $user->transactions()->create($attributes);
    }

    public function update(Transaction $transaction, array $attributes): Transaction
    {
        $transaction->forceFill($attributes)->save();

        return $transaction;
    }

    public function delete(Transaction $transaction): void
    {
        $transaction->delete();
    }
}
