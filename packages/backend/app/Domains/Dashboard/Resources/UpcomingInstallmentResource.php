<?php

namespace App\Domains\Dashboard\Resources;

use App\Domains\Dashboard\Resources\Concerns\FormatsCategory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UpcomingInstallmentResource extends JsonResource
{
    use FormatsCategory;

    public function toArray(Request $request): array
    {
        $transaction = $this->transaction;

        return [
            'id' => $this->id,
            'transaction_id' => $this->transaction_id,
            'step' => $this->step,
            'installments_count' => $transaction->installments_count,
            'type' => $transaction->type,
            'description' => $transaction->description,
            'amount' => $this->amount,
            'date' => $this->date?->toDateString(),
            'overdue' => $this->date->lt(today()),
            'category' => $this->category($transaction->category),
        ];
    }
}
