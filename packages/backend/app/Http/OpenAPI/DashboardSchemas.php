<?php

namespace App\Http\OpenAPI;

use OpenApi\Attributes as OA;

/**
 * Schemas of the `/dashboard` endpoints (app/Domains/Dashboard). Kept apart from Schemas.php so the
 * home screen's contract can evolve on its own. Amounts are decimal strings, like everywhere else.
 */
#[OA\Schema(
    schema: 'DashboardPeriod',
    type: 'object',
    description: 'The calendar month a block refers to. Both ends are inclusive.',
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
    description: 'Installments due in the period: `paid` is money that really moved, `pending` is still scheduled.',
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
    description: 'Pending installments already past their due date, from any month. One due today is not overdue.',
    required: ['count', 'amount'],
    properties: [
        new OA\Property(property: 'count', type: 'integer', example: 1),
        new OA\Property(property: 'amount', type: 'string', format: 'decimal', example: '89.90'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardSummary',
    type: 'object',
    description: 'Income and expense for one month. Transfers to goals are neither: they only show up in `transferred_to_goals`.',
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
            description: 'Paid income minus paid expense in the period. Can be negative.',
            example: '4029.60',
        ),
        new OA\Property(
            property: 'projected_balance',
            type: 'string',
            format: 'decimal',
            description: 'Same as `balance`, counting pending installments too.',
            example: '3729.70',
        ),
        new OA\Property(
            property: 'balance_to_date',
            type: 'string',
            format: 'decimal',
            description: 'Paid income minus paid expense across all time. Ignores `month`.',
            example: '4029.60',
        ),
        new OA\Property(
            property: 'transferred_to_goals',
            type: 'string',
            format: 'decimal',
            description: 'Transfers made to goals in the period.',
            example: '250.00',
        ),
        new OA\Property(
            property: 'overdue',
            type: 'object',
            required: ['expense', 'income'],
            properties: [
                new OA\Property(property: 'expense', ref: '#/components/schemas/DashboardOverdue'),
                new OA\Property(property: 'income', ref: '#/components/schemas/DashboardOverdue'),
            ],
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardCategoryRef',
    type: 'object',
    nullable: true,
    description: 'Just enough to draw a category chip, or null when there is no category (transfers have none). A category deleted later keeps its old name, icon and color.',
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
    description: 'Just enough to draw a goal chip, or null when the transaction is not linked to a goal.',
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
            description: 'The category\'s monthly cap. Null when it has none.',
            example: '800.00',
        ),
        new OA\Property(
            property: 'limit_used_percent',
            type: 'number',
            format: 'float',
            nullable: true,
            description: '`total` as a percentage of `limit_amount`, one decimal place. It can pass 100. Null when there is no limit.',
            example: 96.3,
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardSpendingByCategory',
    type: 'object',
    description: 'Expenses due in the month, grouped by category, biggest first. Income and transfers are not included.',
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
    description: 'A pending installment, with what it belongs to.',
    required: [
        'id', 'transaction_id', 'step', 'installments_count', 'type',
        'description', 'amount', 'date', 'overdue', 'category',
    ],
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 5),
        new OA\Property(property: 'transaction_id', type: 'integer', example: 4),
        new OA\Property(property: 'step', type: 'integer', description: 'Position in the schedule (1, 2, 3...).', example: 1),
        new OA\Property(
            property: 'installments_count',
            type: 'integer',
            description: 'How many installments the transaction has in total.',
            example: 3,
        ),
        new OA\Property(property: 'type', type: 'string', enum: ['income', 'expense'], example: 'expense'),
        new OA\Property(property: 'description', type: 'string', nullable: true, example: 'Internet bill'),
        new OA\Property(property: 'amount', type: 'string', format: 'decimal', example: '89.90'),
        new OA\Property(property: 'date', type: 'string', format: 'date', example: '2026-09-10'),
        new OA\Property(property: 'overdue', type: 'boolean', description: 'True when `date` is before today.', example: true),
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
            description: 'No installment paid yet, some paid, or all paid.',
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
            description: '`current_amount` as a percentage of `target_amount`, one decimal place.',
            example: 25.0,
        ),
        new OA\Property(property: 'expires_at', type: 'string', format: 'date', nullable: true, example: '2027-03-01'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardOverview',
    type: 'object',
    description: 'The home screen in one payload. Each block is exactly what its own `/dashboard/*` route returns under `data`.',
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
            description: 'The next 10 pending installments within 30 days, overdue ones first.',
            items: new OA\Items(ref: '#/components/schemas/DashboardUpcomingInstallment'),
        ),
        new OA\Property(
            property: 'recent_transactions',
            type: 'array',
            description: 'The 5 newest transactions.',
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
            description: 'How many notifications are still unread. The list itself is `GET /notifications?status=unread`.',
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
