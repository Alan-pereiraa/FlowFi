<?php

namespace App\Domains\Dashboard\Resources;

use App\Domains\Shared\Casts\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SummaryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $summary = $this->resource;

        return [
            'period' => $summary['period'],
            'income' => $this->flow($summary['income']),
            'expense' => $this->flow($summary['expense']),
            'balance' => Money::toDecimal($summary['balance']),
            'projected_balance' => Money::toDecimal($summary['projected_balance']),
            'balance_to_date' => Money::toDecimal($summary['balance_to_date']),
            'transferred_to_goals' => Money::toDecimal($summary['transferred_to_goals']),
            'overdue' => [
                'expense' => $this->overdue($summary['overdue']['expense']),
                'income' => $this->overdue($summary['overdue']['income']),
            ],
        ];
    }

    private function flow(array $flow): array
    {
        return [
            'paid' => Money::toDecimal($flow['paid']),
            'pending' => Money::toDecimal($flow['pending']),
            'total' => Money::toDecimal($flow['total']),
        ];
    }

    private function overdue(array $overdue): array
    {
        return [
            'count' => $overdue['count'],
            'amount' => Money::toDecimal($overdue['total']),
        ];
    }
}
