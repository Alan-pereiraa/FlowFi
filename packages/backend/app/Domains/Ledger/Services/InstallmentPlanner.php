<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Ledger\Models\Transaction;
use App\Domains\Shared\Casts\Money;
use Carbon\CarbonImmutable;

class InstallmentPlanner
{
    public function planFromInput(array $input): array
    {
        $date = CarbonImmutable::createFromFormat('Y-m-d', $input['date'])->startOfDay();
        $explicit = $input['installments'] ?? null;

        if ($explicit !== null) {
            $rows = $this->plan(0, $date, $explicit, 1, null, null);

            return [
                'rows' => $rows,
                'total_amount_cents' => array_sum(array_column($rows, 'amount')),
                'schedule_type' => Transaction::SCHEDULE_CUSTOM,
            ];
        }

        $count = max(1, (int) ($input['installments_count'] ?? 1));
        $totalAmountCents = Money::toCents($input['total_amount'], 'total_amount');

        $rows = $this->plan(
            $totalAmountCents,
            $date,
            null,
            $count,
            $input['period_unit'] ?? null,
            isset($input['period_interval']) ? (int) $input['period_interval'] : null,
        );

        return [
            'rows' => $rows,
            'total_amount_cents' => $totalAmountCents,
            'schedule_type' => $count > 1 ? Transaction::SCHEDULE_PERIODIC : Transaction::SCHEDULE_SINGLE,
        ];
    }

    public function transactionScheduleAttributes(array $plan, array $input): array
    {
        $isPeriodic = $plan['schedule_type'] === Transaction::SCHEDULE_PERIODIC;

        return [
            'total_amount' => Money::toDecimal($plan['total_amount_cents']),
            'installments_count' => count($plan['rows']),
            'schedule_type' => $plan['schedule_type'],
            'period_unit' => $isPeriodic ? ($input['period_unit'] ?? 'month') : null,
            'period_interval' => $isPeriodic ? (int) ($input['period_interval'] ?? 1) : null,
        ];
    }

    public function plan(
        int $totalAmountCents,
        CarbonImmutable $transactionDate,
        ?array $explicitInstallments,
        int $installmentsCount,
        ?string $periodUnit,
        ?int $periodInterval,
    ): array {
        if ($explicitInstallments !== null) {
            return $this->fromExplicit($explicitInstallments);
        }

        if ($installmentsCount <= 1) {
            return [[
                'step' => 1,
                'amount' => $totalAmountCents,
                'date' => $transactionDate,
            ]];
        }

        return $this->evenSplit(
            $totalAmountCents,
            $transactionDate,
            $installmentsCount,
            $periodUnit ?? 'month',
            $periodInterval ?? 1,
        );
    }

    private function fromExplicit(array $installments): array
    {
        $rows = array_map(
            static fn (array $installment): array => [
                'amount' => Money::toCents($installment['amount'], 'installments.amount'),
                'date' => CarbonImmutable::createFromFormat('Y-m-d', $installment['date'])->startOfDay(),
            ],
            array_values($installments),
        );

        usort($rows, static fn (array $a, array $b): int => $a['date']->timestamp <=> $b['date']->timestamp);

        return array_values(array_map(
            static fn (array $row, int $index): array => [
                'step' => $index + 1,
                'amount' => $row['amount'],
                'date' => $row['date'],
            ],
            $rows,
            array_keys($rows),
        ));
    }

    private function evenSplit(
        int $totalAmountCents,
        CarbonImmutable $transactionDate,
        int $count,
        string $periodUnit,
        int $periodInterval,
    ): array {
        $base = intdiv($totalAmountCents, $count);
        $remainder = $totalAmountCents - ($base * $count);

        $plan = [];

        for ($step = 1; $step <= $count; $step++) {
            $plan[] = [
                'step' => $step,
                'amount' => $base + ($step <= $remainder ? 1 : 0),
                'date' => $this->addPeriod($transactionDate, $periodUnit, $periodInterval * ($step - 1)),
            ];
        }

        return $plan;
    }

    private function addPeriod(CarbonImmutable $date, string $unit, int $amount): CarbonImmutable
    {
        return match ($unit) {
            'day' => $date->addDays($amount),
            'week' => $date->addWeeks($amount),
            'year' => $date->addYears($amount),
            default => $date->addMonths($amount),
        };
    }
}
