<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Shared\Casts\Money;
use Carbon\CarbonInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;

class EloquentTransactionRepository implements TransactionRepositoryInterface
{
    public function listFor(User $user, int $perPage, ?array $filters): LengthAwarePaginator
    {
        $from = $filters['date_from'] ?? null;
        $to = $filters['date_to'] ?? null;

        return $user->transactions()
            ->with('installments')
            ->when($filters['type'] ?? null, fn ($query, $type) => $query->where('type', $type))
            ->when($filters['category_id'] ?? null, fn ($query, $categoryId) => $query->where('category_id', $categoryId))
            ->when(
                $from || $to,
                fn ($query) => $this->whereDatedInside($query, $from, $to),
            )
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

    public function markInstallmentPending(Installment $installment): Installment
    {
        $installment->forceFill([
            'status' => Installment::STATUS_PENDING,
            'paid_at' => null,
        ])->save();

        return $installment;
    }

    public function pendingExpenseInstallmentsDueBetween(CarbonInterface $from, CarbonInterface $to): Collection
    {
        return $this->pendingExpenseInstallments()
            ->whereDate('date', '>=', $from->toDateString())
            ->whereDate('date', '<=', $to->toDateString())
            ->get();
    }

    public function overduePendingExpenseInstallments(CarbonInterface $today): Collection
    {
        return $this->pendingExpenseInstallments()
            ->whereDate('date', '<', $today->toDateString())
            ->get();
    }

    private function whereDatedInside(Builder $query, ?string $from, ?string $to): Builder
    {
        $inRange = fn ($query) => $this->whereInRange($query, $from, $to);

        return $query->where(fn ($query) => $query
            ->where(fn ($query) => $inRange($query->where('type', '!=', Transaction::TYPE_EXPENSE)))
            ->orWhere(fn ($query) => $query
                ->where('type', Transaction::TYPE_EXPENSE)
                ->whereHas('installments', $inRange)));
    }

    private function whereInRange(Builder $query, ?string $from, ?string $to): Builder
    {
        return $query
            ->when($from, fn ($query) => $query->whereDate('date', '>=', $from))
            ->when($to, fn ($query) => $query->whereDate('date', '<=', $to));
    }

    private function pendingExpenseInstallments(): Builder
    {
        return Installment::query()
            ->where('status', Installment::STATUS_PENDING)
            ->whereHas('transaction', fn ($query) => $query->where('type', Transaction::TYPE_EXPENSE))
            ->with(['transaction.user', 'transaction.category']);
    }
}
