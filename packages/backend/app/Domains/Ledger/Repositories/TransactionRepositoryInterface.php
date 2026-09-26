<?php

namespace App\Domains\Ledger\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use Carbon\CarbonInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Collection;

interface TransactionRepositoryInterface
{
    public function listFor(User $user, int $perPage, ?array $filters): LengthAwarePaginator;

    public function findFor(User $user, int $id): ?Transaction;

    public function create(User $user, array $attributes): Transaction;

    public function update(Transaction $transaction, array $attributes): Transaction;

    public function delete(Transaction $transaction): void;

    public function replaceInstallments(Transaction $transaction, array $installments): Collection;

    public function findInstallmentFor(Transaction $transaction, int $installmentId): ?Installment;

    public function markInstallmentPaid(Installment $installment): Installment;

    public function pendingExpenseInstallmentsDueBetween(CarbonInterface $from, CarbonInterface $to): Collection;

    public function overduePendingExpenseInstallments(CarbonInterface $today): Collection;
}
