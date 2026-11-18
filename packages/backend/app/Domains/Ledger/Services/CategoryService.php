<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Exceptions\CategoryLimitExceededException;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Repositories\CategoryRepositoryInterface;
use App\Domains\Notification\Enums\NotificationType;
use App\Domains\Notification\Service\NotificationService;
use App\Domains\Shared\Casts\Money;
use App\Domains\Shared\Services\AppearanceService;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\DB;

class CategoryService
{
    private const string TIMEZONE = 'America/Sao_Paulo';

    private const array LIMIT_SUBJECTS = ['category_limit_near', 'category_limit_reached', 'category_limit_exceeded'];

    public function __construct(
        private readonly CategoryRepositoryInterface $categories,
        private readonly AppearanceService $appearance,
        private readonly NotificationService $notifications
    ) {}

    public function list(User $user): Collection
    {
        return $this->categories->listFor($user);
    }

    public function create(User $user, array $data): Category
    {
        return $this->categories->create($user, $this->appearance->normalize($data));
    }

    public function findOwned(User $user, int $id): Category
    {
        return $this->categories->findFor($user, $id)
            ?? throw new ModelNotFoundException('Não encontrado.');
    }

    public function update(Category $category, array $data): Category
    {
        return DB::transaction(function () use ($category, $data): Category {
            $this->appearance->apply($category, $data);

            $rest = Arr::except($data, ['icon', 'color']);

            if ($rest !== []) {
                $this->categories->update($category, $rest);
            }

            if (array_key_exists('limit_amount', $data)) {
                $this->notifyLimitStatus($category->user, $category->id);
            }

            return $category;
        });
    }

    public function delete(Category $category): void
    {
        DB::transaction(function () use ($category): void {
            $this->categories->detachFromTransactions($category);
            $this->categories->delete($category);
        });
    }

    public function usageInMonth(User $user, ?string $month): array
    {
        $monthStart = $month === null
            ? CarbonImmutable::today(self::TIMEZONE)->startOfMonth()
            : CarbonImmutable::createFromFormat('!Y-m', $month);

        $used = $this->categories->usageInMonthCents($user, $monthStart);

        return [
            'month' => $monthStart->format('Y-m'),
            'categories' => $this->categories->listFor($user)->map(function (Category $category) use ($used): array {
                $usedCents = $used[$category->id] ?? 0;
                $limitCents = $category->limit_amount === null ? null : Money::toCents($category->limit_amount);

                return [
                    'category_id' => $category->id,
                    'type' => $category->type,
                    'limit' => $limitCents,
                    'used' => $usedCents,
                    'remaining' => $limitCents === null ? null : max(0, $limitCents - $usedCents),
                    'used_percent' => $limitCents === null ? null : intdiv($usedCents * 100, $limitCents),
                ];
            })->all(),
        ];
    }

    public function ensureInMonthLimit(?int $categoryId, array $installments, ?int $ignoreTransactionId = null, bool $confirmed = false): void
    {
        if ($categoryId === null || $confirmed) {
            return;
        }

        $category = $this->categories->findForLimitCheck($categoryId);

        if ($category->limit_amount === null || $category->isIncome()) {
            return;
        }

        $limit = Money::toCents($category->limit_amount);

        $installmentsByMonth = [];

        foreach ($installments as $installment) {
            $month = $installment['date']->format('Y-m');

            $installmentsByMonth[$month] = ($installmentsByMonth[$month] ?? 0) + $installment['amount'];
        }

        foreach ($installmentsByMonth as $month => $total) {
            $monthStart = CarbonImmutable::createFromFormat('!Y-m', $month);
            $used = $this->categories->usedInMonthCents($category, $monthStart, $ignoreTransactionId);

            if ($used + $total > $limit) {
                throw CategoryLimitExceededException::for($category, $monthStart, $limit, $used, $total);
            }
        }
    }

    public function notifyLimitStatus(User $user, ?int $categoryId): void
    {
        if ($categoryId === null) {
            return;
        }

        $category = $this->categories->findForLimitCheck($categoryId);

        if ($category->limit_amount === null) {
            return;
        }

        $limit = Money::toCents($category->limit_amount);
        $used = $this->categories->usedInMonthCents($category, CarbonImmutable::now());

        if ($category->isIncome()) {
            $this->notifyGoalReached($user, $category, $limit, $used);

            return;
        }

        $this->notifyExpenseLevel($user, $category, $limit, $used);
    }

    private function notifyGoalReached(User $user, Category $category, int $limit, int $used): void
    {
        if ($used < $limit) {
            return;
        }

        $this->notifications->notifyOnce(
            $user,
            'Meta da categoria atingida',
            sprintf('Você atingiu a meta de %s da categoria "%s" este mês.', Money::toBrl($limit), $category->name),
            NotificationType::Success,
            'category_goal_reached',
            $category->id,
            CarbonImmutable::now()->startOfMonth()
        );
    }

    private function notifyExpenseLevel(User $user, Category $category, int $limit, int $used): void
    {
        $level = match (true) {
            $used > $limit => 2,
            $used === $limit => 1,
            $used * 100 >= $limit * 80 => 0,
            default => null,
        };

        if ($level === null) {
            return;
        }

        $since = CarbonImmutable::now()->startOfMonth();

        foreach (array_slice(self::LIMIT_SUBJECTS, $level + 1) as $higher) {
            if ($this->notifications->wasNotified($user, $higher, $category->id, $since)) {
                return;
            }
        }

        [$title, $message] = match ($level) {
            2 => [
                'Limite da categoria estourado',
                sprintf('Você estourou o limite da categoria "%s" em %s.', $category->name, Money::toBrl($used - $limit)),
            ],
            1 => [
                'Limite da categoria atingido',
                sprintf('Você atingiu o limite de %s da categoria "%s" este mês.', Money::toBrl($limit), $category->name),
            ],
            0 => [
                'Limite da categoria quase atingido',
                sprintf(
                    'Você já usou %d%% do limite da categoria "%s". Restam %s.',
                    intdiv($used * 100, $limit),
                    $category->name,
                    Money::toBrl($limit - $used),
                ),
            ],
        };

        $this->notifications->notifyOnce(
            $user,
            $title,
            $message,
            NotificationType::Warning,
            self::LIMIT_SUBJECTS[$level],
            $category->id,
            $since
        );
    }
}
