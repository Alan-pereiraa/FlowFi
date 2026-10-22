<?php

namespace App\Http\OpenAPI;

use OpenApi\Attributes as OA;

/**
 * Schemas of the `/dashboard` endpoints (app/Domains/Dashboard). Kept apart from Schemas.php so the
 * home screen's contract can evolve on its own. Amounts are decimal strings, like everywhere else.
 */
#[OA\Schema(
    schema: 'DashboardSummary',
    type: 'object',
    description: 'Só parcelas pagas contam. Transferências para metas não são entrada nem saída.',
    required: ['balance', 'income', 'expense'],
    properties: [
        new OA\Property(
            property: 'balance',
            type: 'string',
            format: 'decimal',
            description: 'Entradas pagas menos saídas pagas de todo o histórico. Ignora `month` e pode ser negativo.',
            example: '4250.00',
        ),
        new OA\Property(
            property: 'income',
            type: 'string',
            format: 'decimal',
            description: 'Entradas pagas com parcelas que vencem no mês.',
            example: '3100.00',
        ),
        new OA\Property(
            property: 'expense',
            type: 'string',
            format: 'decimal',
            description: 'Saídas pagas com parcelas que vencem no mês.',
            example: '1850.00',
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardRecentGoal',
    type: 'object',
    required: ['id', 'name', 'icon', 'color', 'current_amount', 'target_amount'],
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'name', type: 'string', example: 'Viagem Férias'),
        new OA\Property(property: 'icon', type: 'string', example: 'flight'),
        new OA\Property(property: 'color', type: 'string', example: '#FF9800'),
        new OA\Property(property: 'current_amount', type: 'string', format: 'decimal', example: '1200.00'),
        new OA\Property(property: 'target_amount', type: 'string', format: 'decimal', example: '3000.00'),
    ],
)]
#[OA\Schema(
    schema: 'DashboardRecentTransaction',
    type: 'object',
    required: ['id', 'type', 'description', 'date', 'total_amount', 'category'],
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 5),
        new OA\Property(property: 'type', type: 'string', enum: ['income', 'expense', 'transfer'], example: 'expense'),
        new OA\Property(property: 'description', type: 'string', nullable: true, example: 'Almoço RU'),
        new OA\Property(property: 'date', type: 'string', format: 'date', example: '2026-10-22'),
        new OA\Property(property: 'total_amount', type: 'string', format: 'decimal', example: '15.00'),
        new OA\Property(
            property: 'category',
            type: 'object',
            nullable: true,
            description: 'Nulo em transferências.',
            required: ['icon', 'color'],
            properties: [
                new OA\Property(property: 'icon', type: 'string', example: 'restaurant'),
                new OA\Property(property: 'color', type: 'string', example: '#4CAF50'),
            ],
        ),
    ],
)]
#[OA\Schema(
    schema: 'DashboardSummaryResponse',
    type: 'object',
    properties: [new OA\Property(property: 'data', ref: '#/components/schemas/DashboardSummary')],
)]
#[OA\Schema(
    schema: 'DashboardRecentGoalListResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/DashboardRecentGoal'),
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
class DashboardSchemas {}
