<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Transaction;
use Illuminate\Database\Eloquent\Collection;

interface TransactionRepositoryInterface
{
    public function listFor(User $user): Collection;

    public function findFor(User $user, int $id): ?Transaction;

    public function create(User $user, array $attributes): Transaction;

    public function update(Transaction $transaction, array $attributes): Transaction;

    public function delete(Transaction $transaction): void;
}
