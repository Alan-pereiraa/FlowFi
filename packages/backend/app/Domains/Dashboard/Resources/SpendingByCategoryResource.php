<?php

namespace App\Domains\Dashboard\Resources;

use App\Domains\Shared\Casts\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SpendingByCategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'period' => $this->resource['period'],
            'categories' => array_map(fn (array $row): array => [
                'category' => [
                    'id' => $row['category_id'],
                    'name' => $row['name'],
                    'icon' => $row['icon'],
                    'color' => $row['color'],
                ],
                'paid' => Money::toDecimal($row['paid']),
                'pending' => Money::toDecimal($row['pending']),
                'total' => Money::toDecimal($row['total']),
                'limit_amount' => $row['limit_amount'] === null ? null : Money::toDecimal($row['limit_amount']),
                'limit_used_percent' => $row['limit_used_percent'],
            ], $this->resource['categories']),
        ];
    }
}
