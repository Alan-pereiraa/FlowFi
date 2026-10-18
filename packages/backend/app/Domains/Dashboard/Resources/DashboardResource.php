<?php

namespace App\Domains\Dashboard\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The home screen in one payload: each key is exactly what the matching `/dashboard/*` route returns.
 */
class DashboardResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $dashboard = $this->resource;

        return [
            'summary' => new SummaryResource($dashboard['summary']),
            'spending_by_category' => new SpendingByCategoryResource($dashboard['spending_by_category']),
            'upcoming_installments' => UpcomingInstallmentResource::collection($dashboard['upcoming_installments']),
            'recent_transactions' => RecentTransactionResource::collection($dashboard['recent_transactions']),
            'goals' => GoalProgressResource::collection($dashboard['goals']),
            'unread_notifications' => $dashboard['unread_notifications'],
        ];
    }
}
