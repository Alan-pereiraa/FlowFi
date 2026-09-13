<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Shared\Casts\Money;
use Carbon\CarbonImmutable;

/**
 * Pure scheduling logic for a transaction's installments — no persistence, no ownership
 * checks. Given either an explicit list of installments or a count + period, it returns
 * an ordered list of ['step' => int, 'amount' => int cents, 'date' => CarbonImmutable].
 */
class InstallmentPlanner
{
    /**
     * @param  array<int, array{amount: string, date: string}>|null  $explicitInstallments
     * @return list<array{step: int, amount: int, date: CarbonImmutable}>
     */
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

    /**
     * @param  array<int, array{amount: string, date: string}>  $installments
     * @return list<array{step: int, amount: int, date: CarbonImmutable}>
     */
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

    /**
     * @return list<array{step: int, amount: int, date: CarbonImmutable}>
     */
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
                // Front-load the leftover cents so the schedule always sums back to the exact total.
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
