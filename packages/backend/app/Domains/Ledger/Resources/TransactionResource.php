<?php

namespace App\Domains\Ledger\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'category_id' => $this->category_id,
            'goal_id' => $this->goal_id,
            'type' => $this->type,
            'description' => $this->description,
            'date' => $this->date?->toDateString(),
            'total_amount' => $this->total_amount,
            'installments_count' => $this->installments_count,
            'schedule_type' => $this->schedule_type,
            'period_unit' => $this->period_unit,
            'period_interval' => $this->period_interval,
            'installments' => InstallmentResource::collection($this->whenLoaded('installments')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
