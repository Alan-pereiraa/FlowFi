<?php

namespace App\Domains\Ledger\Exceptions;

use App\Domains\Ledger\Models\Category;
use App\Domains\Shared\Casts\Money;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class CategoryLimitExceededException extends ValidationException
{
    public const string CODE = 'category_limit_exceeded';

    private array $details = [];

    public static function for(Category $category, CarbonImmutable $month, int $limitCents, int $usedCents, int $amountCents): static
    {
        $exceededBy = $usedCents + $amountCents - $limitCents;

        $exception = static::withMessages([
            'total_amount' => sprintf(
                'Esta transação ultrapassa o limite da categoria "%s" em %s em %s.',
                $category->name,
                Money::toBrl($exceededBy),
                $month->format('m/Y'),
            ),
        ]);

        $exception->details = [
            'category_id' => $category->id,
            'month' => $month->format('Y-m'),
            'limit_amount' => Money::toDecimal($limitCents),
            'used_amount' => Money::toDecimal($usedCents),
            'remaining_amount' => Money::toDecimal(max(0, $limitCents - $usedCents)),
            'exceeded_by' => Money::toDecimal($exceededBy),
        ];

        return $exception;
    }

    public function render(): JsonResponse
    {
        return response()->json([
            'message' => $this->getMessage(),
            'code' => self::CODE,
            'errors' => $this->errors(),
            'limit' => $this->details,
        ], $this->status);
    }
}
