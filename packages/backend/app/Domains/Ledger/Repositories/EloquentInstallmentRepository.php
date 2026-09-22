<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Shared\Casts\Money;
use Illuminate\Database\Eloquent\Collection;

class EloquentInstallmentRepository implements InstallmentRepositoryInterface
{
    public function replaceFor(Transaction $transaction, array $plan): Collection
    {
        $transaction->installments()->delete();

        $rows = new Collection;

        foreach ($plan as $row) {
            $rows->push($transaction->installments()->create([
                'step' => $row['step'],
                // The planner works in cents; Money::set() expects a decimal string like
                // every other money field, so convert back at this Eloquent boundary.
                'amount' => Money::toDecimal($row['amount']),
                'date' => $row['date']->toDateString(),
                'status' => Installment::STATUS_PENDING,
            ]));
        }

        return $rows;
    }

    public function findFor(Transaction $transaction, int $id): ?Installment
    {
        return $transaction->installments()->find($id);
    }

    public function markPaid(Installment $installment): Installment
    {
        $installment->forceFill([
            'status' => Installment::STATUS_PAID,
            'paid_at' => now(),
        ])->save();

        return $installment;
    }
}
