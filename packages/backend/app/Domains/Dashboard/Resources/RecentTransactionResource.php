<?php

namespace App\Domains\Dashboard\Resources;

use App\Domains\Dashboard\Resources\Concerns\FormatsCategory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RecentTransactionResource extends JsonResource
{
    use FormatsCategory;

    public function toArray(Request $request): array
    {
        $paid = (int) $this->paid_installments_count;

        return [
            'id' => $this->id,
            'type' => $this->type,
            'description' => $this->description,
            'date' => $this->date?->toDateString(),
            'total_amount' => $this->total_amount,
            'installments_count' => $this->installments_count,
            'paid_installments_count' => $paid,
            'status' => match (true) {
                $paid === 0 => 'pending',
                $paid >= $this->installments_count => 'paid',
                default => 'partial',
            },
            'category' => $this->category($this->category),
            'goal' => $this->goal === null ? null : [
                'id' => $this->goal->id,
                'name' => $this->goal->name,
                'icon' => $this->goal->icon,
                'color' => $this->goal->color,
            ],
        ];
    }
}
