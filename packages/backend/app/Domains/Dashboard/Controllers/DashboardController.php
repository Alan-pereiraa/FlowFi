<?php

namespace App\Domains\Dashboard\Controllers;

use App\Domains\Dashboard\Requests\DashboardRequest;
use App\Domains\Dashboard\Requests\RecentGoalsRequest;
use App\Domains\Dashboard\Requests\RecentTransactionsRequest;
use App\Domains\Dashboard\Resources\RecentGoalResource;
use App\Domains\Dashboard\Resources\RecentTransactionResource;
use App\Domains\Dashboard\Resources\SummaryResource;
use App\Domains\Dashboard\Services\DashboardService;
use App\Http\Controllers\Controller;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use OpenApi\Attributes as OA;

class DashboardController extends Controller
{
    public function __construct(
        private readonly DashboardService $dashboard,
    ) {}

    #[OA\Get(
        path: '/dashboard/summary',
        operationId: 'getDashboardSummary',
        tags: ['Dashboard'],
        summary: 'Saldo, entradas e saídas',
        description: 'Saldo disponível (entradas pagas menos saídas pagas, de todo o histórico) e o total de entradas e saídas pagas cujas parcelas vencem no mês. Transferências para metas não entram em nenhum dos valores.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/DashboardMonth'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Resumo financeiro',
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
        path: '/dashboard/goals',
        operationId: 'listDashboardRecentGoals',
        tags: ['Dashboard'],
        summary: 'Metas recentes',
        description: 'As metas criadas mais recentemente, da mais nova para a mais antiga.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'limit',
                in: 'query',
                schema: new OA\Schema(type: 'integer', minimum: 1, maximum: 10, default: 2),
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Metas mais recentes',
                content: new OA\JsonContent(ref: '#/components/schemas/DashboardRecentGoalListResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function goals(RecentGoalsRequest $request): AnonymousResourceCollection
    {
        return RecentGoalResource::collection($this->dashboard->recentGoals(
            $request->user(),
            $request->integer('limit', DashboardService::DEFAULT_GOALS_LIMIT),
        ));
    }

    #[OA\Get(
        path: '/dashboard/recent-transactions',
        operationId: 'listDashboardRecentTransactions',
        tags: ['Dashboard'],
        summary: 'Últimas transações',
        description: 'As transações mais recentes pela data, da mais nova para a mais antiga.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'limit',
                in: 'query',
                schema: new OA\Schema(type: 'integer', minimum: 1, maximum: 20, default: 3),
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Transações mais recentes',
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
}
