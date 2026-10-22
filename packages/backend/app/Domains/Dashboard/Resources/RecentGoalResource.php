<?php

namespace App\Domains\Dashboard\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RecentGoalResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'icon' => $this->icon,
            'color' => $this->color,
            'current_amount' => $this->current_amount,
            'target_amount' => $this->target_amount,
        ];
    }
}
