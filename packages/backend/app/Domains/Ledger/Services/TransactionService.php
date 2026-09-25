<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Repositories\TransactionRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use App\Domains\Shared\Casts\Money;
use Carbon\CarbonImmutable;

class TransactionService
{
    private const array SCHEDULE_KEYS = ['total_amount', 'installments', 'installments_count', 'period_unit', 'period_interval'];

    private const array SIMPLE_KEYS = ['category_id', 'goal_id', 'type', 'description', 'date'];

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
                ...$this->planner->transactionScheduleAttributes($plan, $data),
            ]);

            $installments = $this->transactions->replaceInstallments($transaction, $plan['rows']);

            $effect = $this->goalEffect($transaction);

            $this->adjustGoalCurrentAmount($transaction->goal_id, $effect);

            if ($transaction->type === Transaction::TYPE_TRANSFER) {
                $this->transactions->markInstallmentPaid($installments->first());
            }

            return $transaction->load('installments');
        });
    }

    public function update(Transaction $transaction, array $data): Transaction
    {
        return DB::transaction(function () use ($transaction, $data): Transaction {
            $oldGoalId = $transaction->goal_id;
            $oldEffect = $this->goalEffect($transaction);

            $simple = Arr::only($data, self::SIMPLE_KEYS);

            if ($simple !== []) {
                $this->transactions->update($transaction, $simple);
            }

            if (Arr::hasAny($data, self::SCHEDULE_KEYS)) {
                $this->guardAgainstPaidInstallments($transaction);

                $planInput = $this->mergeForReplan($transaction, $data);
                $plan = $this->planner->planFromInput($planInput);

                $this->transactions->update($transaction, $this->planner->transactionScheduleAttributes($plan, $planInput));
                $this->transactions->replaceInstallments($transaction, $plan['rows']);
            }

            $transaction->refresh();

            if (Arr::hasAny($data, ['goal_id', ...self::SCHEDULE_KEYS])) {
                $this->adjustGoalCurrentAmount($oldGoalId, -$oldEffect);
                $this->adjustGoalCurrentAmount($transaction->goal_id, $this->goalEffect($transaction));
            }

            if ($transaction->type === Transaction::TYPE_EXPENSE && Arr::hasAny($data, ['category_id', ...self::SCHEDULE_KEYS])) {
                $rows = $transaction->installments->map(fn (Installment $installment) => [
                    'date' => CarbonImmutable::parse($installment->date),
                    'amount' => Money::toCents($installment->amount),
                ])->all();

                $this->categories->ensureInMonthLimit($transaction->category_id, $rows, $transaction->id);
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
                'status' => 'This installment is already paid.',
            ]);
        }

        return $this->transactions->markInstallmentPaid($installment);
    }

    private function guardAgainstPaidInstallments(Transaction $transaction): void
    {
        $hasPaidInstallment = $transaction->installments()
            ->where('status', Installment::STATUS_PAID)
            ->exists();

        if ($hasPaidInstallment) {
            throw ValidationException::withMessages([
                'installments' => 'This transaction already has paid installments; its payment plan can no longer be changed.',
            ]);
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

    private function adjustGoalCurrentAmount(?int $goalId, int $cents): void
    {
        if ($goalId === null || $cents === 0) {
            return;
        }

        $this->goals->adjustCurrentAmount($goalId, $cents);
    }

}
