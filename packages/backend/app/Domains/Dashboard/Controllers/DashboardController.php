<?php

namespace App\Domains\Dashboard\Controllers;

use App\Domains\Dashboard\Requests\DashboardRequest;
use App\Domains\Dashboard\Requests\RecentTransactionsRequest;
use App\Domains\Dashboard\Requests\UpcomingInstallmentsRequest;
use App\Domains\Dashboard\Resources\DashboardResource;
use App\Domains\Dashboard\Resources\GoalProgressResource;
use App\Domains\Dashboard\Resources\RecentTransactionResource;
use App\Domains\Dashboard\Resources\SpendingByCategoryResource;
use App\Domains\Dashboard\Resources\SummaryResource;
use App\Domains\Dashboard\Resources\UpcomingInstallmentResource;
use App\Domains\Dashboard\Services\DashboardService;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class DashboardController extends Controller
{
    public function __construct(
        private readonly DashboardService $dashboard,
    ) {}

    public function index(DashboardRequest $request): DashboardResource
    {
        return new DashboardResource($this->dashboard->overview($request->user(), $request->validated('month')));
    }

    public function summary(DashboardRequest $request): SummaryResource
    {
        return new SummaryResource($this->dashboard->summary($request->user(), $request->validated('month')));
    }

    public function spendingByCategory(DashboardRequest $request): SpendingByCategoryResource
    {
        return new SpendingByCategoryResource($this->dashboard->spendingByCategory($request->user(), $request->validated('month')));
    }

    public function upcomingInstallments(UpcomingInstallmentsRequest $request): AnonymousResourceCollection
    {
        return UpcomingInstallmentResource::collection($this->dashboard->upcomingInstallments(
            $request->user(),
            $request->integer('days', DashboardService::DEFAULT_UPCOMING_DAYS),
            $request->integer('limit', DashboardService::DEFAULT_UPCOMING_LIMIT),
        ));
    }

    public function recentTransactions(RecentTransactionsRequest $request): AnonymousResourceCollection
    {
        return RecentTransactionResource::collection($this->dashboard->recentTransactions(
            $request->user(),
            $request->integer('limit', DashboardService::DEFAULT_RECENT_LIMIT),
        ));
    }

    public function goals(Request $request): AnonymousResourceCollection
    {
        return GoalProgressResource::collection($this->dashboard->goals($request->user()));
    }
}
