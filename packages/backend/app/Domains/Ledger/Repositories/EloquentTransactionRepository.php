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

    public function paidTotalsFor(User $user, ?CarbonInterface $from = null, ?CarbonInterface $to = null): array
    {
        // The join skips the installments' soft-delete scope, so it is applied by hand.
        $totals = $user->transactions()
            ->join('installments', 'installments.transaction_id', '=', 'transactions.id')
            ->whereNull('installments.deleted_at')
            ->where('installments.status', Installment::STATUS_PAID)
            ->whereIn('transactions.type', [Transaction::TYPE_INCOME, Transaction::TYPE_EXPENSE])
            ->when($from, fn ($query) => $query->whereDate('installments.date', '>=', $from->toDateString()))
            ->when($to, fn ($query) => $query->whereDate('installments.date', '<=', $to->toDateString()))
            ->groupBy('transactions.type')
            ->selectRaw('transactions.type as type, SUM(installments.amount) as total')
            ->toBase()
            ->pluck('total', 'type');

        return [
            'income' => (int) ($totals[Transaction::TYPE_INCOME] ?? 0),
            'expense' => (int) ($totals[Transaction::TYPE_EXPENSE] ?? 0),
        ];
    }

    public function latestFor(User $user, int $limit): Collection
    {
        return $user->transactions()
            ->with(['category' => fn ($query) => $query->withTrashed()])
            ->orderBy('date', 'desc')
            ->orderBy('id', 'desc')
            ->limit($limit)
            ->get();
    }

    private function pendingExpenseInstallments(): Builder
    {
        return Installment::query()
            ->where('status', Installment::STATUS_PENDING)
            ->whereHas('transaction', fn ($query) => $query->where('type', Transaction::TYPE_EXPENSE))
            ->with(['transaction.user', 'transaction.category']);
    }
}
