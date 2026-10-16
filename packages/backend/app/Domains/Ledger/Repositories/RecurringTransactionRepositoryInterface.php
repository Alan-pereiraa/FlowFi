<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\RecurringTransaction;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Collection;

interface RecurringTransactionRepositoryInterface
{
    public function listFor(User $user): Collection;

    public function findFor(User $user, int $id): ?RecurringTransaction;

    public function create(User $user, array $attributes): RecurringTransaction;

    public function update(RecurringTransaction $recurring, array $attributes): RecurringTransaction;

    public function delete(RecurringTransaction $recurring): void;

    public function dueOn(CarbonInterface $date): Collection;
}
