<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\RecurringTransaction;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Repositories\RecurringTransactionRepositoryInterface;
use App\Domains\Notification\Enums\NotificationType;
use App\Domains\Notification\Service\NotificationService;
use App\Domains\Shared\Services\PeriodCalculator;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Throwable;

class RecurringTransactionService
{
    private const string TIMEZONE = 'America/Sao_Paulo';

    private const array EDITABLE_KEYS = ['amount', 'description', 'category_id', 'goal_id'];

    public function __construct(
        private readonly RecurringTransactionRepositoryInterface $recurring,
        private readonly TransactionService $transactions,
        private readonly PeriodCalculator $periods,
        private readonly NotificationService $notifications,
    ) {}

    public function list(User $user): Collection
    {
        return $this->recurring->listFor($user);
    }

    public function findOwned(User $user, int $id): RecurringTransaction
    {
        return $this->recurring->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function create(User $user, array $data): RecurringTransaction
    {
        return DB::transaction(function () use ($user, $data): RecurringTransaction {
            $recurring = $this->recurring->create($user, [
                ...Arr::only($data, [
                    'category_id', 'goal_id', 'type', 'amount', 'description',
                    'period_unit', 'start_date', 'end_date', 'occurrences',
                ]),
                'period_interval' => $data['period_interval'] ?? 1,
                'generated_count' => 0,
                'next_occurrence_on' => $data['start_date'],
            ]);

            $today = $this->today();

            while ($this->isDue($recurring, $today)) {
                $this->generateNext($recurring);
            }

            return $recurring->refresh();
        });
    }

    public function update(RecurringTransaction $recurring, array $data): RecurringTransaction
    {
        $changes = Arr::only($data, self::EDITABLE_KEYS);

        if ($changes !== []) {
            $this->recurring->update($recurring, $changes);
        }

        return $recurring;
    }

    public function end(RecurringTransaction $recurring): RecurringTransaction
    {
        if ($recurring->next_occurrence_on === null) {
            return $recurring;
        }

        $today = $this->today()->toDateString();
        $endDate = $recurring->end_date?->toDateString();

        return $this->recurring->update($recurring, [
            'end_date' => $endDate !== null && $endDate < $today ? $endDate : $today,
            'next_occurrence_on' => null,
        ]);
    }

    public function delete(RecurringTransaction $recurring): void
    {
        $this->recurring->delete($recurring);
    }

    public function generateDue(): array
    {
        $today = $this->today();
        $counts = ['generated' => 0, 'skipped' => 0, 'ended' => 0, 'failed' => 0];

        foreach ($this->recurring->dueOn($today) as $recurring) {
            try {
                $this->generateDueFor($recurring, $today, $counts);
            } catch (Throwable $e) {
                report($e);
                $counts['failed']++;
            }
        }

        return $counts;
    }

    private function generateDueFor(RecurringTransaction $recurring, CarbonImmutable $today, array &$counts): void
    {
        while ($this->isDue($recurring, $today)) {
            if ($this->lostItsGoal($recurring)) {
                $this->endBecauseGoalIsGone($recurring);
                $counts['ended']++;

                return;
            }

            $date = $recurring->next_occurrence_on;

            try {
                DB::transaction(fn () => $this->generateNext($recurring));
                $counts['generated']++;
            } catch (UniqueConstraintViolationException) {
                $this->advance($recurring);
            } catch (ValidationException $e) {
                $this->advance($recurring);
                $this->notifySkipped($recurring, $date, $e, $today);
                $counts['skipped']++;
            }
        }
    }

    private function generateNext(RecurringTransaction $recurring): void
    {
        $this->transactions->create($recurring->user, [
            'type' => $recurring->type,
            'category_id' => $recurring->category_id,
            'goal_id' => $recurring->goal_id,
            'description' => $recurring->description,
            'total_amount' => $recurring->amount,
            'date' => $recurring->next_occurrence_on->toDateString(),
            'recurring_transaction_id' => $recurring->id,
        ]);

        $this->advance($recurring);
    }

    private function advance(RecurringTransaction $recurring): void
    {
        $count = $recurring->generated_count + 1;

        $this->recurring->update($recurring, [
            'generated_count' => $count,
            'next_occurrence_on' => $this->occurrenceAfter($recurring, $count)?->toDateString(),
        ]);
    }

    private function occurrenceAfter(RecurringTransaction $recurring, int $count): ?CarbonImmutable
    {
        if ($recurring->occurrences !== null && $count >= $recurring->occurrences) {
            return null;
        }

        $date = $this->periods->occurrenceDate(
            $recurring->start_date,
            $recurring->period_unit,
            $recurring->period_interval,
            $count,
        );

        if ($recurring->end_date !== null && $date->gt($recurring->end_date)) {
            return null;
        }

        return $date;
    }

    private function isDue(RecurringTransaction $recurring, CarbonImmutable $today): bool
    {
        return $recurring->next_occurrence_on !== null
            && $recurring->next_occurrence_on->toDateString() <= $today->toDateString();
    }

    private function lostItsGoal(RecurringTransaction $recurring): bool
    {
        if ($recurring->goal_id !== null) {
            return $recurring->goal === null;
        }

        return $recurring->type === Transaction::TYPE_TRANSFER;
    }

    private function endBecauseGoalIsGone(RecurringTransaction $recurring): void
    {
        $this->end($recurring);

        $this->notifications->notifyOnce(
            $recurring->user,
            'Recorrência encerrada',
            "A {$this->describe($recurring)} foi encerrada porque a meta dela foi apagada.",
            NotificationType::Warning,
            'recurring_transaction_ended',
            $recurring->id,
        );
    }

    private function notifySkipped(
        RecurringTransaction $recurring,
        CarbonImmutable $date,
        ValidationException $e,
        CarbonImmutable $today,
    ): void {
        $reason = Arr::first(Arr::flatten($e->errors())) ?? 'uma regra foi violada';

        $this->notifications->notifyOnce(
            $recurring->user,
            'Transação recorrente não criada',
            "A transação de {$date->format('d/m/Y')} da {$this->describe($recurring)} não foi criada: {$reason}",
            NotificationType::Warning,
            'recurring_transaction_skipped',
            $recurring->id,
            $today->startOfDay(),
        );
    }

    private function describe(RecurringTransaction $recurring): string
    {
        if ($recurring->description !== null) {
            return "recorrência \"{$recurring->description}\"";
        }

        return match ($recurring->type) {
            Transaction::TYPE_INCOME => 'sua receita recorrente',
            Transaction::TYPE_TRANSFER => 'sua transferência recorrente',
            default => 'sua despesa recorrente',
        };
    }

    private function today(): CarbonImmutable
    {
        return CarbonImmutable::today(self::TIMEZONE);
    }
}
