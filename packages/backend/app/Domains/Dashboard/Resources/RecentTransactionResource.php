<?php

namespace App\Domains\Dashboard\Resources;

use App\Domains\Dashboard\Resources\Concerns\FormatsCategory;
use App\Domains\Dashboard\Services\DashboardService;
use App\Domains\Ledger\Models\Transaction;
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
            'status' => $this->status($paid),
            'category' => $this->category($this->category),
            'goal' => $this->goal === null ? null : [
                'id' => $this->goal->id,
                'name' => $this->goal->name,
                'icon' => $this->goal->icon,
                'color' => $this->goal->color,
            ],
        ];
    }

    private function status(int $paid): string
    {
        if ($this->type === Transaction::TYPE_TRANSFER) {
            return 'paid';
        }

        if ($this->type === Transaction::TYPE_INCOME) {
            return $this->date->toDateString() <= today(DashboardService::TIMEZONE)->toDateString() ? 'paid' : 'pending';
        }

        return match (true) {
            $paid === 0 => 'pending',
            $paid >= $this->installments_count => 'paid',
            default => 'partial',
        };
    }
}
