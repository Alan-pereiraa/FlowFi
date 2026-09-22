<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Transaction;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Shared\Casts\Money;

class EloquentTransactionRepository implements TransactionRepositoryInterface
{
    public function listFor(User $user, int $perPage, ?array $filters): LengthAwarePaginator
    {
        return $user->transactions()
            ->with('installments')
            ->when($filters['type'] ?? null, fn ($query, $type) => $query->where('type', $type))
            ->when($filters['category_id'] ?? null, fn ($query, $categoryId) => $query->where('category_id', $categoryId))
            ->when($filters['date_from'] ?? null, fn ($query, $from) => $query->whereDoesntHave(
                'installments', fn ($query) => $query->where('date', '<', $from)
            ))
            ->when($filters['date_to'] ?? null, fn ($query, $to) => $query->whereDoesntHave(
                'installments', fn ($query) => $query->where('date', '>', $to)
            ))
            ->orderBy('date', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($perPage);
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

    public function replaceInstallments(Transaction $transaction, array $installments): Collection
    {
        $transaction->installments()->forceDelete();

        $rows = new Collection;

        foreach ($installments as $row) {
            $rows->push($transaction->installments()->create([
                'step' => $row['step'],
                'amount' => Money::toDecimal($row['amount']),
                'date' => $row['date']->toDateString(),
                'status' => Installment::STATUS_PENDING,
            ]));
        }

        return $rows;
    }

    public function findInstallmentFor(Transaction $transaction, int $installmentId): ?Installment
    {
        return $transaction->installments()->find($installmentId);
    }

    public function markInstallmentPaid(Installment $installment): Installment
    {
        $installment->forceFill([
            'status' => Installment::STATUS_PAID,
            'paid_at' => now(),
        ])->save();

        return $installment;
    }
}
