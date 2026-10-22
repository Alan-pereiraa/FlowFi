<?php

namespace App\Domains\Dashboard\Resources;

use App\Domains\Shared\Casts\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SummaryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'balance' => Money::toDecimal($this->resource['balance']),
            'income' => Money::toDecimal($this->resource['income']),
            'expense' => Money::toDecimal($this->resource['expense']),
        ];
    }
}
