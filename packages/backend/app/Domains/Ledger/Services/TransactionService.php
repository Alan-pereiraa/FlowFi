<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Repositories\InstallmentRepositoryInterface;
use App\Domains\Ledger\Repositories\TransactionRepositoryInterface;
use App\Domains\Shared\Casts\Money;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class TransactionService
{
    /** Fields that, when present, require the installment schedule to be rebuilt. */
    private const array SCHEDULE_KEYS = ['total_amount', 'installments', 'installments_count', 'period_unit', 'period_interval'];

    /** Plain transaction fields applied as-is, independent of the payment schedule. */
    private const array SIMPLE_KEYS = ['category_id', 'goal_id', 'type', 'description', 'date'];

    public function __construct(
        private readonly TransactionRepositoryInterface $transactions,
        private readonly InstallmentRepositoryInterface $installments,
        private readonly InstallmentPlanner $planner,
    ) {}

    public function list(User $user): Collection
    {
        return $this->transactions->listFor($user);
    }

    public function findOwned(User $user, int $id): Transaction
    {
        return $this->transactions->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function findOwnedInstallment(User $user, int $transactionId, int $installmentId): Installment
    {
        $transaction = $this->findOwned($user, $transactionId);

        return $this->installments->findFor($transaction, $installmentId)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function create(User $user, array $data): Transaction
    {
        return DB::transaction(function () use ($user, $data): Transaction {
            $plan = $this->buildPlan($data);

            $transaction = $this->transactions->create($user, [
                'category_id' => $data['category_id'],
                'goal_id' => $data['goal_id'] ?? null,
                'type' => $data['type'],
                'description' => $data['description'] ?? null,
                'date' => $data['date'],
                ...$this->scheduleAttributes($plan, $data),
            ]);

            $this->installments->replaceFor($transaction, $plan['rows']);

            return $transaction->load('installments');
        });
    }

    public function update(Transaction $transaction, array $data): Transaction
    {
        return DB::transaction(function () use ($transaction, $data): Transaction {
            $simple = Arr::only($data, self::SIMPLE_KEYS);

            if ($simple !== []) {
                $this->transactions->update($transaction, $simple);
            }

            if (Arr::hasAny($data, self::SCHEDULE_KEYS)) {
                $this->guardAgainstPaidInstallments($transaction);

                $planInput = $this->mergeForReplan($transaction, $data);
                $plan = $this->buildPlan($planInput);

                $this->transactions->update($transaction, $this->scheduleAttributes($plan, $planInput));
                $this->installments->replaceFor($transaction, $plan['rows']);
            }

            return $transaction->refresh()->load('installments');
        });
    }

    public function delete(Transaction $transaction): void
    {
        // Installment is an auxiliary table of Transaction, not its own module: deleting
        // the parent must soft-delete every installment that belongs to it. The FK's
        // cascadeOnDelete() never fires for this — SoftDeletes turns delete() into an
        // UPDATE (deleted_at), not a real SQL DELETE, so cascade it explicitly here.
        DB::transaction(function () use ($transaction): void {
            $transaction->installments()->delete();
            $this->transactions->delete($transaction);
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

        return $this->installments->markPaid($installment);
    }

    /**
     * A transaction's payment plan is locked in once money has actually moved: allowing an
     * edit to silently reshuffle amounts/dates after an installment is paid would desync the
     * schedule from what really happened.
     */
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

    /**
     * Fills in whatever schedule fields the update omitted with the transaction's current
     * values, so e.g. sending only `period_unit`/`period_interval` re-plans using the
     * existing total and installment count.
     */
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

    private function buildPlan(array $data): array
    {
        $date = CarbonImmutable::createFromFormat('Y-m-d', $data['date'])->startOfDay();
        $explicit = $data['installments'] ?? null;

        if ($explicit !== null) {
            $rows = $this->planner->plan(0, $date, $explicit, 1, null, null);

            return [
                'rows' => $rows,
                'total_amount_cents' => array_sum(array_column($rows, 'amount')),
                'schedule_type' => Transaction::SCHEDULE_CUSTOM,
            ];
        }

        $count = max(1, (int) ($data['installments_count'] ?? 1));
        $totalAmountCents = Money::toCents($data['total_amount'], 'total_amount');

        $rows = $this->planner->plan(
            $totalAmountCents,
            $date,
            null,
            $count,
            $data['period_unit'] ?? null,
            isset($data['period_interval']) ? (int) $data['period_interval'] : null,
        );

        return [
            'rows' => $rows,
            'total_amount_cents' => $totalAmountCents,
            'schedule_type' => $count > 1 ? Transaction::SCHEDULE_PERIODIC : Transaction::SCHEDULE_SINGLE,
        ];
    }

    private function scheduleAttributes(array $plan, array $planInput): array
    {
        $isPeriodic = $plan['schedule_type'] === Transaction::SCHEDULE_PERIODIC;

        return [
            // Money::set() expects a decimal string (like every other money field in the app),
            // not raw cents — the planner works in cents internally, so convert back here.
            'total_amount' => Money::toDecimal($plan['total_amount_cents']),
            'installments_count' => count($plan['rows']),
            'schedule_type' => $plan['schedule_type'],
            'period_unit' => $isPeriodic ? ($planInput['period_unit'] ?? 'month') : null,
            'period_interval' => $isPeriodic ? (int) ($planInput['period_interval'] ?? 1) : null,
        ];
    }
}
