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
use OpenApi\Attributes as OA;

class DashboardController extends Controller
{
    public function __construct(
        private readonly DashboardService $dashboard,
    ) {}

    #[OA\Get(
        path: '/dashboard',
        operationId: 'getDashboard',
        tags: ['Dashboard'],
        summary: 'Home screen in one call',
        description: 'Every block of the dashboard in one payload, for app launch. Each key is exactly what the matching /dashboard/* route returns, plus unread_notifications. Money counts through installments: a transaction belongs to the month its installments are due, and only paid installments are real money.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/DashboardMonth'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'The whole dashboard',
                content: new OA\JsonContent(ref: '#/components/schemas/DashboardOverviewResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function index(DashboardRequest $request): DashboardResource
    {
        return new DashboardResource($this->dashboard->overview($request->user(), $request->validated('month')));
    }

    #[OA\Get(
        path: '/dashboard/summary',
        operationId: 'getDashboardSummary',
        tags: ['Dashboard'],
        summary: 'Monthly income, expense and balance',
        description: 'Income and expense of the month split into paid, pending and total, the balance (realized and projected), the all-time balance, how much went to goals and what is overdue. Transfers to goals are not income or expense.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/DashboardMonth'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Summary of the month',
                content: new OA\JsonContent(ref: '#/components/schemas/DashboardSummaryResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function summary(DashboardRequest $request): SummaryResource
    {
        return new SummaryResource($this->dashboard->summary($request->user(), $request->validated('month')));
    }

    #[OA\Get(
        path: '/dashboard/spending-by-category',
        operationId: 'getDashboardSpendingByCategory',
        tags: ['Dashboard'],
        summary: 'Spending of the month by category',
        description: 'Expenses due in the month grouped by category, biggest first, with how much of the category limit they use. The category limit is read as a monthly cap.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/DashboardMonth'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Spending by category',
                content: new OA\JsonContent(ref: '#/components/schemas/DashboardSpendingByCategoryResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function spendingByCategory(DashboardRequest $request): SpendingByCategoryResource
    {
        return new SpendingByCategoryResource($this->dashboard->spendingByCategory($request->user(), $request->validated('month')));
    }

    #[OA\Get(
        path: '/dashboard/upcoming-installments',
        operationId: 'listDashboardUpcomingInstallments',
        tags: ['Dashboard'],
        summary: 'Pending installments to pay or receive',
        description: 'Pending installments due within the next days, oldest due date first. Installments already past due come first, flagged with overdue.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'days',
                in: 'query',
                description: 'How many days ahead to look. Pending installments already past due are always included.',
                schema: new OA\Schema(type: 'integer', minimum: 1, maximum: 365, default: 30),
            ),
            new OA\Parameter(
                name: 'limit',
                in: 'query',
                schema: new OA\Schema(type: 'integer', minimum: 1, maximum: 50, default: 10),
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Pending installments, soonest first',
                content: new OA\JsonContent(ref: '#/components/schemas/DashboardUpcomingInstallmentListResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function upcomingInstallments(UpcomingInstallmentsRequest $request): AnonymousResourceCollection
    {
        return UpcomingInstallmentResource::collection($this->dashboard->upcomingInstallments(
            $request->user(),
            $request->integer('days', DashboardService::DEFAULT_UPCOMING_DAYS),
            $request->integer('limit', DashboardService::DEFAULT_UPCOMING_LIMIT),
        ));
    }

    #[OA\Get(
        path: '/dashboard/recent-transactions',
        operationId: 'listDashboardRecentTransactions',
        tags: ['Dashboard'],
        summary: 'Latest transactions',
        description: 'The newest transactions with their category (null for transfers), linked goal and how many installments are paid.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'limit',
                in: 'query',
                schema: new OA\Schema(type: 'integer', minimum: 1, maximum: 20, default: 5),
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Newest transactions first',
                content: new OA\JsonContent(ref: '#/components/schemas/DashboardRecentTransactionListResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function recentTransactions(RecentTransactionsRequest $request): AnonymousResourceCollection
    {
        return RecentTransactionResource::collection($this->dashboard->recentTransactions(
            $request->user(),
            $request->integer('limit', DashboardService::DEFAULT_RECENT_LIMIT),
        ));
    }

    #[OA\Get(
        path: '/dashboard/goals',
        operationId: 'listDashboardGoals',
        tags: ['Dashboard'],
        summary: 'Goal progress',
        description: 'Every goal with its saved balance (current_amount) and progress toward the target. Closest deadline first, goals without one last.',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Goals with progress',
                content: new OA\JsonContent(ref: '#/components/schemas/DashboardGoalProgressListResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
        ],
    )]
    public function goals(Request $request): AnonymousResourceCollection
    {
        return GoalProgressResource::collection($this->dashboard->goals($request->user()));
    }
}
