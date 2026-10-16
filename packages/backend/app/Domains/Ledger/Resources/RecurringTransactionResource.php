<?php

namespace App\Domains\Ledger\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RecurringTransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'category_id' => $this->category_id,
            'goal_id' => $this->goal_id,
            'type' => $this->type,
            'description' => $this->description,
            'amount' => $this->amount,
            'period_unit' => $this->period_unit,
            'period_interval' => $this->period_interval,
            'start_date' => $this->start_date?->toDateString(),
            'end_date' => $this->end_date?->toDateString(),
            'occurrences' => $this->occurrences,
            'generated_count' => $this->generated_count,
            'next_occurrence_on' => $this->next_occurrence_on?->toDateString(),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
