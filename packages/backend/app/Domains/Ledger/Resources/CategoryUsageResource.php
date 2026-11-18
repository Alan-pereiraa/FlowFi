<?php

namespace App\Domains\Ledger\Resources;

use App\Domains\Shared\Casts\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryUsageResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'month' => $this->resource['month'],
            'categories' => array_map(fn (array $row): array => [
                'category_id' => $row['category_id'],
                'type' => $row['type'],
                'limit_amount' => $row['limit'] === null ? null : Money::toDecimal($row['limit']),
                'used_amount' => Money::toDecimal($row['used']),
                'remaining_amount' => $row['remaining'] === null ? null : Money::toDecimal($row['remaining']),
                'used_percent' => $row['used_percent'],
            ], $this->resource['categories']),
        ];
    }
}
