<?php

namespace App\Domains\Dashboard\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class GoalProgressResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $goal = $this->resource['goal'];

        return [
            'id' => $goal->id,
            'name' => $goal->name,
            'icon' => $goal->icon,
            'color' => $goal->color,
            'target_amount' => $goal->target_amount,
            'current_amount' => $goal->current_amount,
            'progress_percent' => $this->resource['progress_percent'],
            'expires_at' => $goal->expires_at?->toDateString(),
        ];
    }
}
