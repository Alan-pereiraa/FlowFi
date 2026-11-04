<?php

namespace App\Http\OpenAPI;

use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: 'DashboardPeriod',
    type: 'object',
    description: 'O mês a que um bloco se refere. As duas pontas estão incluídas.',
    required: ['month', 'from', 'to'],
    properties: [
        new OA\Property(property: 'month', type: 'string', pattern: '^\d{4}-(0[1-9]|1[0-2])$', example: '2026-09'),
        new OA\Property(property: 'from', type: 'string', format: 'date', example: '2026-09-01'),
        new OA\Property(property: 'to', type: 'string', format: 'date', example: '2026-09-30'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardFlow',
    type: 'object',
    description: 'Valores do período. Em saídas, `paid` são parcelas pagas e `pending` são parcelas pendentes. Em entradas, `paid` tem data até hoje e `pending` tem data futura.',
    required: ['paid', 'pending', 'total'],
    properties: [
        new OA\Property(property: 'paid', type: 'string', format: 'decimal', example: '4500.00'),
        new OA\Property(property: 'pending', type: 'string', format: 'decimal', example: '0.00'),
        new OA\Property(property: 'total', type: 'string', format: 'decimal', example: '4500.00'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardOverdue',
    type: 'object',
    description: 'Parcelas de saídas pendentes e já vencidas, de qualquer mês. A que vence hoje não está atrasada.',
    required: ['count', 'amount'],
    properties: [
        new OA\Property(property: 'count', type: 'integer', example: 1),
        new OA\Property(property: 'amount', type: 'string', format: 'decimal', example: '89.90'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardSummary',
    type: 'object',
    description: 'Entradas e saídas de um mês. Transferências para metas não são nenhuma das duas: aparecem só em `transferred_to_goals`.',
    required: [
        'period', 'income', 'expense', 'balance', 'projected_balance',
        'balance_to_date', 'transferred_to_goals', 'overdue',
    ],
    properties: [
        new OA\Property(property: 'period', ref: '#/components/schemas/DashboardPeriod'),
        new OA\Property(property: 'income', ref: '#/components/schemas/DashboardFlow'),
        new OA\Property(property: 'expense', ref: '#/components/schemas/DashboardFlow'),
        new OA\Property(
            property: 'balance',
            type: 'string',
            format: 'decimal',
            description: 'Entradas realizadas menos saídas pagas no período. Pode ser negativo.',
            example: '4029.60',
        ),
        new OA\Property(
            property: 'projected_balance',
            type: 'string',
            format: 'decimal',
            description: 'Igual a `balance`, contando também entradas previstas e parcelas pendentes.',
            example: '3729.70',
        ),
        new OA\Property(
            property: 'balance_to_date',
            type: 'string',
            format: 'decimal',
            description: 'Entradas realizadas menos saídas pagas em todo o período. Ignora `month`.',
            example: '4029.60',
        ),
        new OA\Property(
            property: 'transferred_to_goals',
            type: 'string',
            format: 'decimal',
            description: 'Transferências feitas para metas no período.',
            example: '250.00',
        ),
        new OA\Property(
            property: 'overdue',
            type: 'object',
            required: ['expense'],
            properties: [
                new OA\Property(property: 'expense', ref: '#/components/schemas/DashboardOverdue'),
            ],
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardCategoryRef',
    type: 'object',
    nullable: true,
    description: 'O necessário para desenhar a categoria, ou null quando não há categoria (transferências não têm). Uma categoria excluída depois mantém nome, ícone e cor.',
    required: ['id', 'name', 'icon', 'color'],
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'name', type: 'string', example: 'Groceries'),
        new OA\Property(property: 'icon', type: 'string', example: 'shopping_cart'),
        new OA\Property(property: 'color', type: 'string', example: '#4CAF50'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardGoalRef',
    type: 'object',
    nullable: true,
    description: 'O necessário para desenhar a meta, ou null quando a transação não está vinculada a uma meta.',
    required: ['id', 'name', 'icon', 'color'],
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'name', type: 'string', example: 'Trip to Japan'),
        new OA\Property(property: 'icon', type: 'string', example: 'flight'),
        new OA\Property(property: 'color', type: 'string', example: '#FF9800'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardCategorySpending',
    type: 'object',
    required: ['category', 'paid', 'pending', 'total', 'limit_amount', 'limit_used_percent'],
    properties: [
        new OA\Property(property: 'category', ref: '#/components/schemas/DashboardCategoryRef'),
        new OA\Property(property: 'paid', type: 'string', format: 'decimal', example: '470.40'),
        new OA\Property(property: 'pending', type: 'string', format: 'decimal', example: '299.90'),
        new OA\Property(property: 'total', type: 'string', format: 'decimal', example: '770.30'),
        new OA\Property(
            property: 'limit_amount',
            type: 'string',
            format: 'decimal',
            nullable: true,
            description: 'O teto mensal da categoria. Null quando não há limite.',
            example: '800.00',
        ),
        new OA\Property(
            property: 'limit_used_percent',
            type: 'number',
            format: 'float',
            nullable: true,
            description: '`total` como percentual de `limit_amount`, com uma casa decimal. Pode passar de 100. Null quando não há limite.',
            example: 96.3,
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardSpendingByCategory',
    type: 'object',
    description: 'Saídas com vencimento no mês, agrupadas por categoria, da maior para a menor. Entradas e transferências não entram.',
    required: ['period', 'categories'],
    properties: [
        new OA\Property(property: 'period', ref: '#/components/schemas/DashboardPeriod'),
        new OA\Property(
            property: 'categories',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/DashboardCategorySpending'),
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardUpcomingInstallment',
    type: 'object',
    description: 'Uma parcela pendente de uma saída, com a transação a que pertence.',
    required: [
        'id', 'transaction_id', 'step', 'installments_count', 'type',
        'description', 'amount', 'date', 'overdue', 'category',
    ],
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 5),
        new OA\Property(property: 'transaction_id', type: 'integer', example: 4),
        new OA\Property(property: 'step', type: 'integer', description: 'Posição no cronograma (1, 2, 3...).', example: 1),
        new OA\Property(
            property: 'installments_count',
            type: 'integer',
            description: 'Quantas parcelas a transação tem no total.',
            example: 3,
        ),
        new OA\Property(property: 'type', type: 'string', enum: ['expense'], example: 'expense'),
        new OA\Property(property: 'description', type: 'string', nullable: true, example: 'Internet bill'),
        new OA\Property(property: 'amount', type: 'string', format: 'decimal', example: '89.90'),
        new OA\Property(property: 'date', type: 'string', format: 'date', example: '2026-09-10'),
        new OA\Property(property: 'overdue', type: 'boolean', description: 'Verdadeiro quando `date` é anterior a hoje.', example: true),
        new OA\Property(property: 'category', ref: '#/components/schemas/DashboardCategoryRef'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardRecentTransaction',
    type: 'object',
    required: [
        'id', 'type', 'description', 'date', 'total_amount', 'installments_count',
        'paid_installments_count', 'status', 'category', 'goal',
    ],
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 5),
        new OA\Property(property: 'type', type: 'string', enum: ['income', 'expense', 'transfer'], example: 'expense'),
        new OA\Property(property: 'description', type: 'string', nullable: true, example: 'Dinner party'),
        new OA\Property(property: 'date', type: 'string', format: 'date', example: '2026-09-22'),
        new OA\Property(property: 'total_amount', type: 'string', format: 'decimal', example: '210.00'),
        new OA\Property(property: 'installments_count', type: 'integer', example: 1),
        new OA\Property(property: 'paid_installments_count', type: 'integer', example: 0),
        new OA\Property(
            property: 'status',
            type: 'string',
            enum: ['pending', 'partial', 'paid'],
            description: 'Saída: nenhuma parcela paga, algumas pagas ou todas pagas. Entrada: paid com data até hoje e pending com data futura. Transferência: sempre paid.',
            example: 'pending',
        ),
        new OA\Property(property: 'category', ref: '#/components/schemas/DashboardCategoryRef'),
        new OA\Property(property: 'goal', ref: '#/components/schemas/DashboardGoalRef'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardGoalProgress',
    type: 'object',
    required: ['id', 'name', 'icon', 'color', 'target_amount', 'current_amount', 'progress_percent', 'expires_at'],
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'name', type: 'string', example: 'Trip to Japan'),
        new OA\Property(property: 'icon', type: 'string', example: 'flight'),
        new OA\Property(property: 'color', type: 'string', example: '#FF9800'),
        new OA\Property(property: 'target_amount', type: 'string', format: 'decimal', example: '10000.00'),
        new OA\Property(property: 'current_amount', type: 'string', format: 'decimal', example: '2500.00'),
        new OA\Property(
            property: 'progress_percent',
            type: 'number',
            format: 'float',
            description: '`current_amount` como percentual de `target_amount`, com uma casa decimal.',
            example: 25.0,
        ),
        new OA\Property(property: 'expires_at', type: 'string', format: 'date', nullable: true, example: '2027-03-01'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardOverview',
    type: 'object',
    description: 'A tela inicial em uma só resposta. Cada bloco é exatamente o que a rota `/dashboard/*` correspondente retorna em `data`.',
    required: [
        'summary', 'spending_by_category', 'upcoming_installments',
        'recent_transactions', 'goals', 'unread_notifications',
    ],
    properties: [
        new OA\Property(property: 'summary', ref: '#/components/schemas/DashboardSummary'),
        new OA\Property(property: 'spending_by_category', ref: '#/components/schemas/DashboardSpendingByCategory'),
        new OA\Property(
            property: 'upcoming_installments',
            type: 'array',
            description: 'As próximas 10 parcelas pendentes em até 30 dias, com as atrasadas primeiro.',
            items: new OA\Items(ref: '#/components/schemas/DashboardUpcomingInstallment'),
        ),
        new OA\Property(
            property: 'recent_transactions',
            type: 'array',
            description: 'As 5 transações mais recentes.',
            items: new OA\Items(ref: '#/components/schemas/DashboardRecentTransaction'),
        ),
        new OA\Property(
            property: 'goals',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/DashboardGoalProgress'),
        ),
        new OA\Property(
            property: 'unread_notifications',
            type: 'integer',
            description: 'Quantas notificações ainda não foram lidas. A lista em si está em `GET /notifications?status=unread`.',
            example: 3,
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardOverviewResponse',
    type: 'object',
    properties: [new OA\Property(property: 'data', ref: '#/components/schemas/DashboardOverview')],
)]
#[OA\Schema(
    schema: 'DashboardSummaryResponse',
    type: 'object',
    properties: [new OA\Property(property: 'data', ref: '#/components/schemas/DashboardSummary')],
)]
#[OA\Schema(
    schema: 'DashboardSpendingByCategoryResponse',
    type: 'object',
    properties: [new OA\Property(property: 'data', ref: '#/components/schemas/DashboardSpendingByCategory')],
)]
#[OA\Schema(
    schema: 'DashboardUpcomingInstallmentListResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/DashboardUpcomingInstallment'),
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardRecentTransactionListResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/DashboardRecentTransaction'),
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardGoalProgressListResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/DashboardGoalProgress'),
        ),
    ],
)]
class DashboardSchemas {}
