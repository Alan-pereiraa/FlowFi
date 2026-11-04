<?php

namespace App\Domains\Shared\Services;

use Carbon\CarbonImmutable;

class PeriodCalculator
{
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
