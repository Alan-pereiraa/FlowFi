<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Shared\Casts\Money;
use App\Domains\Shared\Services\GeminiClient;
use Carbon\CarbonImmutable;
use DateTimeImmutable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;
use InvalidArgumentException;
use Symfony\Component\HttpKernel\Exception\HttpException;

class TransactionDraftService
{
    public const string KIND_TRANSACTION = 'transaction';

    public const string KIND_RECURRING = 'recurring';

    private const array TYPES = [Transaction::TYPE_INCOME, Transaction::TYPE_EXPENSE, Transaction::TYPE_TRANSFER];

    private const string TIMEZONE = 'America/Sao_Paulo';

    private const int MIN_OCCURRENCES = 2;

    private const int MAX_OCCURRENCES = 120;

    private const string INSTRUCTIONS = <<<'TEXT'
        You turn a short note, written or spoken in Brazilian Portuguese, into a draft transaction for a personal finance app. Amounts are in Brazilian reais (BRL).

        Fill in every field. Use null for anything the note does not state or clearly imply:
        - kind: "recurring" when the full amount repeats every period ("todo mês", "por mês", "toda semana", "todo dia 5", "mensalidade"). "transaction" for a one-off, or for one amount split into installments ("em 12x", "12x de 100", "parcelado em 3 vezes"). Use "transaction" when unsure.
        - type: "expense" for money spent, "income" for money received, "transfer" for money put aside into one of the user's goals. Use "expense" when unsure.
        - total_amount: the amount as a decimal string with a dot and two decimal places, e.g. "1250.90". For a split purchase it is the total, not the value of each installment ("12x de 100" is "1200.00"). For kind "recurring" it is the value of one occurrence, never multiplied ("100 por mês durante 6 meses" is "100.00").
        - date: YYYY-MM-DD. Resolve relative dates ("hoje", "ontem", "sexta passada") against the given today date; use today when no date is mentioned. For kind "recurring" it is the first occurrence: the next matching date for "todo dia 5" (today counts), the named past date for "desde janeiro".
        - description: a short label for what was bought, paid or received, in Portuguese (e.g. "Celular", "Uber", "Salário"). Null only when the note names nothing.
        - category_id: the id of the best-matching category from the given list. Null for a transfer.
        - goal_id: the id of a goal from the given list. Required for a transfer; for an expense only when the money is taken out of that goal; null for income.
        - installments_count: the number of installments, only for an expense of kind "transaction" whose amount is split ("em 12x", "parcelado em 3 vezes", "3 parcelas a cada 15 dias"). Otherwise null. Always null for income, transfer and kind "recurring".
        - period_unit, period_interval: for a split, the time between installments; for kind "recurring", the time between occurrences. Otherwise null. period_unit is day, week, month or year, "month" unless the note says otherwise. period_interval is how many period_units, 1 unless the note says otherwise.
        - occurrences: only for kind "recurring", how many times it repeats in total when the note limits it ("durante 6 meses" is 6). Otherwise null.
        - end_date: YYYY-MM-DD. Only for kind "recurring", the last day it can repeat when the note names one ("até dezembro" is the last day of that month). Null when occurrences is set.

        Only use ids that appear in the given lists. If nothing matches, use null.
        TEXT;

    private const array SCHEMA = [
        'type' => 'object',
        'properties' => [
            'kind' => ['type' => 'string', 'enum' => [self::KIND_TRANSACTION, self::KIND_RECURRING]],
            'type' => ['type' => 'string', 'enum' => self::TYPES],
            'total_amount' => ['type' => ['string', 'null'], 'description' => 'Decimal with a dot and two places, e.g. "50.00".'],
            'date' => ['type' => 'string', 'format' => 'date'],
            'description' => ['type' => ['string', 'null']],
            'category_id' => ['type' => ['integer', 'null']],
            'goal_id' => ['type' => ['integer', 'null']],
            'installments_count' => ['type' => ['integer', 'null'], 'minimum' => 1, 'maximum' => 120],
            'period_unit' => ['anyOf' => [['type' => 'string', 'enum' => Transaction::PERIOD_UNITS], ['type' => 'null']]],
            'period_interval' => ['type' => ['integer', 'null'], 'minimum' => 1, 'maximum' => 365],
            'occurrences' => ['type' => ['integer', 'null'], 'minimum' => self::MIN_OCCURRENCES, 'maximum' => self::MAX_OCCURRENCES],
            'end_date' => ['anyOf' => [['type' => 'string', 'format' => 'date'], ['type' => 'null']]],
        ],
        'required' => [
            'kind', 'type', 'total_amount', 'date', 'description', 'category_id', 'goal_id',
            'installments_count', 'period_unit', 'period_interval', 'occurrences', 'end_date',
        ],
        'additionalProperties' => false,
    ];

    public function __construct(
        private readonly GeminiClient $gemini,
        private readonly CategoryService $categories,
        private readonly GoalService $goals,
    ) {}

    public function fromRawContext(User $user, string $rawContext): array
    {
        $categories = $this->categories->list($user);
        $goals = $this->goals->list($user);
        $today = CarbonImmutable::now(self::TIMEZONE)->toDateString();

        $output = $this->gemini->interact([
            'model' => config('services.gemini.draft_model'),
            'system_instruction' => self::INSTRUCTIONS,
            'input' => implode("\n\n", [
                "Today: {$today}",
                'Categories: '.$this->idNameList($categories),
                'Goals: '.$this->idNameList($goals),
                "Note:\n{$rawContext}",
            ]),
            'response_format' => [[
                'type' => 'text',
                'mime_type' => 'application/json',
                'schema' => self::SCHEMA,
            ]],
        ]);

        $draft = json_decode($output, true);

        if (! is_array($draft)) {
            throw new HttpException(502, 'O provedor de IA retornou um rascunho inválido. Tente novamente ou preencha a transação manualmente.');
        }

        $categoryIds = $categories->modelKeys();
        $goalIds = $goals->modelKeys();

        if (($draft['kind'] ?? null) === self::KIND_RECURRING) {
            return [
                'kind' => self::KIND_RECURRING,
                'draft' => $this->normalizeRecurring($draft, $categoryIds, $goalIds, $today),
            ];
        }

        return [
            'kind' => self::KIND_TRANSACTION,
            'draft' => $this->normalizeTransaction($draft, $categoryIds, $goalIds, $today),
        ];
    }

    private function normalizeTransaction(array $draft, array $categoryIds, array $goalIds, string $today): array
    {
        $type = $this->type($draft);
        $isSplit = $type === Transaction::TYPE_EXPENSE && (int) ($draft['installments_count'] ?? 1) > 1;

        return [
            'type' => $type,
            'total_amount' => $this->amount($draft),
            'date' => $this->date($draft['date'] ?? null) ?? $today,
            'description' => $this->description($draft),
            'category_id' => $this->categoryId($draft, $type, $categoryIds),
            'goal_id' => $this->goalId($draft, $type, $goalIds),
            'installments_count' => $isSplit ? min((int) $draft['installments_count'], 120) : null,
            'period_unit' => $isSplit ? $this->periodUnit($draft) : null,
            'period_interval' => $isSplit ? $this->periodInterval($draft) : null,
        ];
    }

    private function normalizeRecurring(array $draft, array $categoryIds, array $goalIds, string $today): array
    {
        $type = $this->type($draft);
        $startDate = $this->startDate($draft, $today);
        $occurrences = $this->occurrences($draft);

        return [
            'type' => $type,
            'category_id' => $this->categoryId($draft, $type, $categoryIds),
            'goal_id' => $this->goalId($draft, $type, $goalIds),
            'description' => $this->description($draft),
            'amount' => $this->amount($draft),
            'period_unit' => $this->periodUnit($draft),
            'period_interval' => $this->periodInterval($draft),
            'start_date' => $startDate,
            'end_date' => $occurrences === null ? $this->endDate($draft, $startDate) : null,
            'occurrences' => $occurrences,
        ];
    }

    private function type(array $draft): string
    {
        return in_array($draft['type'] ?? null, self::TYPES, true) ? $draft['type'] : Transaction::TYPE_EXPENSE;
    }

    private function amount(array $draft): ?string
    {
        try {
            $cents = isset($draft['total_amount']) ? Money::toCents($draft['total_amount']) : 0;
        } catch (InvalidArgumentException) {
            $cents = 0;
        }

        return $cents > 0 ? Money::toDecimal($cents) : null;
    }

    private function date(mixed $date): ?string
    {
        $parsed = is_string($date) ? DateTimeImmutable::createFromFormat('!Y-m-d', $date) : false;

        return $parsed && $parsed->format('Y-m-d') === $date ? $date : null;
    }

    private function startDate(array $draft, string $today): string
    {
        $date = $this->date($draft['date'] ?? null);
        $oldest = CarbonImmutable::parse($today)->subYear()->toDateString();

        return $date !== null && $date >= $oldest ? $date : $today;
    }

    private function endDate(array $draft, string $startDate): ?string
    {
        $date = $this->date($draft['end_date'] ?? null);

        return $date !== null && $date >= $startDate ? $date : null;
    }

    private function occurrences(array $draft): ?int
    {
        $occurrences = (int) ($draft['occurrences'] ?? 0);

        return $occurrences >= self::MIN_OCCURRENCES ? min($occurrences, self::MAX_OCCURRENCES) : null;
    }

    private function description(array $draft): ?string
    {
        $description = is_string($draft['description'] ?? null) ? Str::limit(trim($draft['description']), 1000, '') : '';

        return $description === '' ? null : $description;
    }

    private function categoryId(array $draft, string $type, array $categoryIds): ?int
    {
        return $type !== Transaction::TYPE_TRANSFER && in_array($draft['category_id'] ?? null, $categoryIds, true)
            ? $draft['category_id']
            : null;
    }

    private function goalId(array $draft, string $type, array $goalIds): ?int
    {
        return $type !== Transaction::TYPE_INCOME && in_array($draft['goal_id'] ?? null, $goalIds, true)
            ? $draft['goal_id']
            : null;
    }

    private function periodUnit(array $draft): string
    {
        return in_array($draft['period_unit'] ?? null, Transaction::PERIOD_UNITS, true) ? $draft['period_unit'] : 'month';
    }

    private function periodInterval(array $draft): ?int
    {
        $interval = (int) ($draft['period_interval'] ?? 0);

        return $interval >= 1 && $interval <= 365 ? $interval : null;
    }

    private function idNameList(Collection $models): string
    {
        return json_encode(
            $models->map(fn (Model $model): array => ['id' => $model->id, 'name' => $model->name])->values(),
            JSON_UNESCAPED_UNICODE,
        );
    }
}
