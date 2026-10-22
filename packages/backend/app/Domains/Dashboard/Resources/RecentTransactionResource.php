<?php

namespace App\Domains\Dashboard\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RecentTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'description' => $this->description,
            'date' => $this->date?->toDateString(),
            'total_amount' => $this->total_amount,
            'category' => $this->category === null ? null : [
                'icon' => $this->category->icon,
                'color' => $this->category->color,
            ],
        ];
    }
}
