<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use Illuminate\Database\Eloquent\Collection;

interface InstallmentRepositoryInterface
{
    /**
     * Replace a transaction's whole schedule: soft-deletes whatever installments exist today
     * and creates fresh rows from the given plan (each a ['step', 'amount', 'date'] tuple).
     */
    public function replaceFor(Transaction $transaction, array $plan): Collection;

    public function findFor(Transaction $transaction, int $id): ?Installment;

    public function markPaid(Installment $installment): Installment;
}
