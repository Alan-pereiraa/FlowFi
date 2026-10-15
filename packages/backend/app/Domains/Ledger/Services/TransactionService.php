<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Repositories\TransactionRepositoryInterface;
use App\Domains\Shared\Casts\Money;
use App\Domains\Shared\Services\GeminiClient;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use DateTimeImmutable;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Arr;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use InvalidArgumentException;
use Symfony\Component\HttpKernel\Exception\HttpException;

class TransactionService
{
    private const array SCHEDULE_KEYS = ['total_amount', 'installments', 'installments_count', 'period_unit', 'period_interval'];

    private const array SIMPLE_KEYS = ['category_id', 'goal_id', 'description', 'date'];

    private const string DRAFT_INSTRUCTIONS = <<<'TEXT'
        You turn a short note, written or spoken in Brazilian Portuguese, into a draft transaction for a personal finance app. Amounts are in Brazilian reais (BRL).

        Fill in every field. Use null for anything the note does not state or clearly imply:
        - type: "expense" for money spent, "income" for money received, "transfer" for money put aside into one of the user's goals. Use "expense" when unsure.
        - total_amount: the full amount as a decimal string with a dot and two decimal places, e.g. "1250.90". For a split purchase it is the total, not the value of each installment.
        - date: YYYY-MM-DD. Resolve relative dates ("hoje", "ontem", "sexta passada") against the given today date; use today when no date is mentioned.
        - description: a short label for what was bought, paid or received, in Portuguese (e.g. "Celular", "Uber", "Salário"). Null only when the note names nothing.
        - category_id: the id of the best-matching category from the given list. Null for a transfer.
        - goal_id: the id of a goal from the given list. Required for a transfer; for an expense only when the money is taken out of that goal; null for income.
        - installments_count, period_unit, period_interval: set them whenever the note says the amount is split ("em 12x", "parcelado em 3 vezes", "3 parcelas a cada 15 dias"); otherwise null. installments_count is the number of installments. period_unit is day, week, month or year, "month" unless the note says otherwise. period_interval is how many period_units between installments, 1 unless the note says otherwise.

        Only use ids that appear in the given lists. If nothing matches, use null.
        TEXT;

    // Every key is required (nullable where it can be unknown): Gemini may skip optional properties.
    private const array DRAFT_SCHEMA = [
        'type' => 'object',
        'properties' => [
            'type' => ['type' => 'string', 'enum' => Transaction::TYPES],
            'total_amount' => ['type' => ['string', 'null'], 'description' => 'Decimal with a dot and two places, e.g. "50.00".'],
            'date' => ['type' => 'string', 'format' => 'date'],
            'description' => ['type' => ['string', 'null']],
            'category_id' => ['type' => ['integer', 'null']],
            'goal_id' => ['type' => ['integer', 'null']],
            'installments_count' => ['type' => ['integer', 'null'], 'minimum' => 1, 'maximum' => 120],
            'period_unit' => ['anyOf' => [['type' => 'string', 'enum' => Transaction::PERIOD_UNITS], ['type' => 'null']]],
            'period_interval' => ['type' => ['integer', 'null'], 'minimum' => 1, 'maximum' => 365],
        ],
        'required' => [
            'type', 'total_amount', 'date', 'description', 'category_id', 'goal_id',
            'installments_count', 'period_unit', 'period_interval',
        ],
        'additionalProperties' => false,
    ];

    public function __construct(
        private readonly TransactionRepositoryInterface $transactions,
        private readonly InstallmentPlanner $planner,
        private readonly GoalService $goals,
        private readonly CategoryService $categories,
        private readonly GeminiClient $gemini,
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

            if ($transaction->type === Transaction::TYPE_EXPENSE) {
                $this->categories->warnIfNearLimit($user, $transaction->category_id);
            }

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
                'status' => 'This installment is already paid.',
            ]);
        }

        return $this->transactions->markInstallmentPaid($installment);
    }

    /**
     * Suggests a POST /transactions body for the client to confirm; nothing is saved here, so
     * every rule (ownership, limits, goal balance) still runs when the client posts it.
     */
    public function draftFromRawContext(User $user, string $rawContext): array
    {
        $categories = $this->categories->list($user);
        $goals = $this->goals->list($user);
        $today = CarbonImmutable::now('America/Sao_Paulo')->toDateString();

        $output = $this->gemini->interact([
            'model' => config('services.gemini.draft_model'),
            'system_instruction' => self::DRAFT_INSTRUCTIONS,
            'input' => implode("\n\n", [
                "Today: {$today}",
                'Categories: '.$this->idNameList($categories),
                'Goals: '.$this->idNameList($goals),
                "Note:\n{$rawContext}",
            ]),
            'response_format' => [[
                'type' => 'text',
                'mime_type' => 'application/json',
                'schema' => self::DRAFT_SCHEMA,
            ]],
        ]);

        $draft = json_decode($output, true);

        if (! is_array($draft)) {
            throw new HttpException(502, 'The AI provider returned an invalid draft. Try again or fill in the transaction manually.');
        }

        return $this->normalizeDraft($draft, $categories->modelKeys(), $goals->modelKeys(), $today);
    }

    public function pendingExpenseInstallmentsDueBetween(CarbonInterface $from, CarbonInterface $to): Collection
    {
        return $this->transactions->pendingExpenseInstallmentsDueBetween($from, $to);
    }

    public function overduePendingExpenseInstallments(CarbonInterface $today): Collection
    {
        return $this->transactions->overduePendingExpenseInstallments($today);
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

    private function idNameList(Collection $models): string
    {
        return json_encode(
            $models->map(fn (Model $model): array => ['id' => $model->id, 'name' => $model->name])->values(),
            JSON_UNESCAPED_UNICODE,
        );
    }

    private function normalizeDraft(array $draft, array $categoryIds, array $goalIds, string $today): array
    {
        $type = in_array($draft['type'] ?? null, Transaction::TYPES, true) ? $draft['type'] : Transaction::TYPE_EXPENSE;

        try {
            $cents = isset($draft['total_amount']) ? Money::toCents($draft['total_amount']) : 0;
        } catch (InvalidArgumentException) {
            $cents = 0;
        }

        $date = $draft['date'] ?? null;
        $parsedDate = is_string($date) ? DateTimeImmutable::createFromFormat('!Y-m-d', $date) : false;

        $description = is_string($draft['description'] ?? null) ? Str::limit(trim($draft['description']), 1000, '') : '';

        $isSplit = $type !== Transaction::TYPE_TRANSFER && (int) ($draft['installments_count'] ?? 1) > 1;
        $periodInterval = (int) ($draft['period_interval'] ?? 0);

        return [
            'type' => $type,
            'total_amount' => $cents > 0 ? Money::toDecimal($cents) : null,
            'date' => $parsedDate && $parsedDate->format('Y-m-d') === $date ? $date : $today,
            'description' => $description === '' ? null : $description,
            'category_id' => $type !== Transaction::TYPE_TRANSFER && in_array($draft['category_id'] ?? null, $categoryIds, true)
                ? $draft['category_id']
                : null,
            'goal_id' => $type !== Transaction::TYPE_INCOME && in_array($draft['goal_id'] ?? null, $goalIds, true)
                ? $draft['goal_id']
                : null,
            'installments_count' => $isSplit ? min((int) $draft['installments_count'], 120) : null,
            'period_unit' => match (true) {
                ! $isSplit => null,
                in_array($draft['period_unit'] ?? null, Transaction::PERIOD_UNITS, true) => $draft['period_unit'],
                default => 'month',
            },
            'period_interval' => $isSplit && $periodInterval >= 1 && $periodInterval <= 365 ? $periodInterval : null,
        ];
    }
}
