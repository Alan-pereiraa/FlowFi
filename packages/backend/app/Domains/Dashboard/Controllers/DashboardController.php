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
        summary: 'Tela inicial em uma só chamada',
        description: 'Todos os blocos do dashboard em uma só resposta, para a abertura do app. Cada chave é exatamente o que a rota /dashboard/* correspondente retorna, mais unread_notifications. Saídas contam pelas parcelas: pertencem ao mês de vencimento, e só parcelas pagas são dinheiro realizado. Entradas contam pela data: até hoje são realizadas, e futuras são previstas.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/DashboardMonth'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'O dashboard completo',
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
        summary: 'Entradas, saídas e saldo do mês',
        description: 'Entradas e saídas do mês divididas em pago, pendente e total, o saldo (realizado e previsto), o saldo de todo o período, o valor enviado para metas e as parcelas de saídas atrasadas. Transferências para metas não são entrada nem saída.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/DashboardMonth'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Resumo do mês',
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
        summary: 'Gastos do mês por categoria',
        description: 'Saídas com vencimento no mês agrupadas por categoria, da maior para a menor, com o quanto usam do limite da categoria. O limite é lido como um teto mensal.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/DashboardMonth'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Gastos por categoria',
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
        summary: 'Parcelas pendentes de saídas',
        description: 'Parcelas pendentes de saídas que vencem nos próximos dias, da data mais antiga para a mais nova. As parcelas já vencidas vêm primeiro, marcadas com overdue.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'days',
                in: 'query',
                description: 'Quantos dias à frente considerar. Parcelas pendentes já vencidas sempre são incluídas.',
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
                description: 'Parcelas pendentes, das mais próximas para as mais distantes',
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
        summary: 'Últimas transações',
        description: 'As transações mais recentes com a categoria (null em transferências), a meta vinculada e quantas parcelas estão pagas. Entradas e transferências não têm parcelas: o status de uma entrada vem da data, e o de uma transferência é sempre paid.',
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
                description: 'Transações mais recentes primeiro',
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
        summary: 'Progresso das metas',
        description: 'Todas as metas com o valor guardado (current_amount) e o progresso até o objetivo. Prazo mais próximo primeiro; metas sem prazo por último.',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Metas com o progresso',
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
