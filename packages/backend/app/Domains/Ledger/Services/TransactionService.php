<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Repositories\TransactionRepositoryInterface;
use App\Domains\Shared\Casts\Money;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Arr;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TransactionService
{
    private const string TIMEZONE = 'America/Sao_Paulo';

    private const array SCHEDULE_KEYS = ['total_amount', 'installments', 'installments_count', 'period_unit', 'period_interval'];

    private const array SIMPLE_KEYS = ['category_id', 'goal_id', 'description', 'date'];

    public function __construct(
        private readonly TransactionRepositoryInterface $transactions,
        private readonly InstallmentPlanner $planner,
        private readonly GoalService $goals,
        private readonly CategoryService $categories,
    ) {}

    public function list(User $user, int $perPage, array $filters = []): LengthAwarePaginator
    {
        return $this->transactions->listFor($user, $perPage, $filters);
    }

    public function findOwned(User $user, int $id): Transaction
    {
        return $this->transactions->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function findOwnedInstallment(User $user, int $transactionId, int $installmentId): Installment
    {
        $transaction = $this->findOwned($user, $transactionId);

        return $this->transactions->findInstallmentFor($transaction, $installmentId)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function create(User $user, array $data): Transaction
    {
        return DB::transaction(function () use ($user, $data): Transaction {
            $plan = $this->planner->planFromInput($data);

            if ($data['type'] === Transaction::TYPE_EXPENSE) {
                $this->categories->ensureInMonthLimit($data['category_id'], $plan['rows'], null);
            }

            $transaction = $this->transactions->create($user, [
                'category_id' => $data['category_id'] ?? null,
                'goal_id' => $data['goal_id'] ?? null,
                'type' => $data['type'],
                'description' => $data['description'] ?? null,
                'date' => $data['date'],
                'recurring_transaction_id' => $data['recurring_transaction_id'] ?? null,
                ...$this->planner->transactionScheduleAttributes($plan, $data),
            ]);

            if ($transaction->type === Transaction::TYPE_EXPENSE) {
                $this->settleInstallments($this->transactions->replaceInstallments($transaction, $plan['rows']));
                $this->categories->warnIfNearLimit($user, $transaction->category_id);
            }

            $effect = $this->goalEffect($transaction);

            $this->adjustGoalCurrentAmount($transaction->goal_id, $effect);

            return $transaction->load('installments');
        });
    }

    public function update(Transaction $transaction, array $data): Transaction
    {
        $this->ensureRecurringIsNotSplit($transaction, $data);

        return DB::transaction(function () use ($transaction, $data): Transaction {
            $oldGoalId = $transaction->goal_id;
            $oldEffect = $this->goalEffect($transaction);
            $replan = $this->needsReplan($transaction, $data);

            $simple = Arr::only($data, self::SIMPLE_KEYS);

            if ($simple !== []) {
                $this->transactions->update($transaction, $simple);
            }

            if ($replan) {
                $planInput = $this->mergeForReplan($transaction, $data);
                $plan = $this->planner->planFromInput($planInput);

                $this->transactions->update($transaction, $this->planner->transactionScheduleAttributes($plan, $planInput));

                if ($transaction->type === Transaction::TYPE_EXPENSE) {
                    $this->settleInstallments($this->transactions->replaceInstallments($transaction, $plan['rows']));
                }
            }

            $transaction->refresh();

            if ($replan || array_key_exists('goal_id', $data)) {
                $this->moveGoalEffect($oldGoalId, $oldEffect, $transaction);
            }

            if ($transaction->type === Transaction::TYPE_EXPENSE && ($replan || array_key_exists('category_id', $data))) {
                $rows = $transaction->installments->map(fn (Installment $installment) => [
                    'date' => CarbonImmutable::parse($installment->date),
                    'amount' => Money::toCents($installment->amount),
                ])->all();

                $this->categories->ensureInMonthLimit($transaction->category_id, $rows, $transaction->id);

                $this->categories->warnIfNearLimit($transaction->user, $transaction->category_id);
            }

            return $transaction->load('installments');
        });
    }

    public function delete(Transaction $transaction): void
    {
        DB::transaction(function () use ($transaction): void {
            $transaction->installments()->delete();
            $this->transactions->delete($transaction);

            $effect = $this->goalEffect($transaction);

            $this->adjustGoalCurrentAmount($transaction->goal_id, -$effect);
        });
    }

    public function payInstallment(User $user, int $transactionId, int $installmentId): Installment
    {
        $installment = $this->findOwnedInstallment($user, $transactionId, $installmentId);

        if ($installment->status === Installment::STATUS_PAID) {
            throw ValidationException::withMessages([
                'status' => 'Esta parcela já está paga.',
            ]);
        }

        return $this->transactions->markInstallmentPaid($installment);
    }

    public function unpayInstallment(User $user, int $transactionId, int $installmentId): Installment
    {
        $installment = $this->findOwnedInstallment($user, $transactionId, $installmentId);

        if ($installment->status === Installment::STATUS_PENDING) {
            throw ValidationException::withMessages([
                'status' => 'Esta parcela já está pendente.',
            ]);
        }

        return $this->transactions->markInstallmentPending($installment);
    }

    public function pendingExpenseInstallmentsDueBetween(CarbonInterface $from, CarbonInterface $to): Collection
    {
        return $this->transactions->pendingExpenseInstallmentsDueBetween($from, $to);
    }

    public function overduePendingExpenseInstallments(CarbonInterface $today): Collection
    {
        return $this->transactions->overduePendingExpenseInstallments($today);
    }

    private function ensureRecurringIsNotSplit(Transaction $transaction, array $data): void
    {
        if ($transaction->recurring_transaction_id === null) {
            return;
        }

        $message = 'Transações geradas por recorrência não podem ser parceladas.';
        $count = (int) ($data['installments_count'] ?? 1);

        if ($count > 1 && $count !== $transaction->installments_count) {
            throw ValidationException::withMessages(['installments_count' => $message]);
        }

        if (count($data['installments'] ?? []) > 1) {
            throw ValidationException::withMessages(['installments' => $message]);
        }
    }

    private function needsReplan(Transaction $transaction, array $data): bool
    {
        if (Arr::hasAny($data, self::SCHEDULE_KEYS)) {
            return true;
        }

        return isset($data['date'])
            && $data['date'] !== $transaction->date->toDateString()
            && $transaction->schedule_type !== Transaction::SCHEDULE_CUSTOM;
    }

    private function settleInstallments(Collection $installments): void
    {
        $today = CarbonImmutable::today(self::TIMEZONE)->toDateString();

        foreach ($installments as $installment) {
            if ($installment->date->toDateString() <= $today) {
                $this->transactions->markInstallmentPaid($installment);
            }
        }
    }

    private function mergeForReplan(Transaction $transaction, array $data): array
    {
        $date = $data['date'] ?? $transaction->date->toDateString();

        if (array_key_exists('installments', $data) && $data['installments'] !== null) {
            return [
                'date' => $date,
                'installments' => $data['installments'],
            ];
        }

        return [
            'date' => $date,
            'total_amount' => $data['total_amount'] ?? $transaction->total_amount,
            'installments_count' => $data['installments_count'] ?? $transaction->installments_count,
            'period_unit' => array_key_exists('period_unit', $data) ? $data['period_unit'] : $transaction->period_unit,
            'period_interval' => array_key_exists('period_interval', $data) ? $data['period_interval'] : $transaction->period_interval,
        ];
    }

    private function goalEffect(Transaction $transaction): int
    {
        if ($transaction->goal_id === null) {
            return 0;
        }

        $cents = Money::toCents($transaction->total_amount);

        return match ($transaction->type) {
            Transaction::TYPE_TRANSFER => $cents,
            Transaction::TYPE_EXPENSE => -$cents,
            default => 0,
        };
    }

    private function moveGoalEffect(?int $oldGoalId, int $oldEffect, Transaction $transaction): void
    {
        $effect = $this->goalEffect($transaction);

        if ($oldGoalId === $transaction->goal_id) {
            $this->adjustGoalCurrentAmount($oldGoalId, $effect - $oldEffect);

            return;
        }

        $this->adjustGoalCurrentAmount($oldGoalId, -$oldEffect);
        $this->adjustGoalCurrentAmount($transaction->goal_id, $effect);
    }

    private function adjustGoalCurrentAmount(?int $goalId, int $cents): void
    {
        if ($goalId === null || $cents === 0) {
            return;
        }

        $this->goals->adjustCurrentAmount($goalId, $cents);
    }
}
