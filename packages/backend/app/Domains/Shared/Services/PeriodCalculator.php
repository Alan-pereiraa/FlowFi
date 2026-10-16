<?php

namespace App\Domains\Shared\Services;

use Carbon\CarbonImmutable;

/**
 * Calendar arithmetic for anything that repeats on a period (installments, recurring transactions).
 */
class PeriodCalculator
{
    /**
     * Date of the n-th occurrence (0-based), always counted from $start so month-end dates
     * don't drift: Jan 31 + 1 month is Feb 28, and + 2 months is back on Mar 31.
     */
    public function occurrenceDate(CarbonImmutable $start, string $unit, int $interval, int $n): CarbonImmutable
    {
        $amount = $interval * $n;

        return match ($unit) {
            'day' => $start->addDays($amount),
            'week' => $start->addWeeks($amount),
            'year' => $start->addYearsNoOverflow($amount),
            default => $start->addMonthsNoOverflow($amount),
        };
    }
}
