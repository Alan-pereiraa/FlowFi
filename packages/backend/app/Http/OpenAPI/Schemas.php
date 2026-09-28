<?php

namespace App\Http\OpenAPI;

use OpenApi\Attributes as OA;

/**
 * Global OpenAPI definitions: API info, server, security scheme, tags and reusable components.
 * Endpoint annotations live on the real controller methods (app/Domains/{Domain}/Controllers).
 */
#[OA\Info(
    title: 'FlowFi API',
    version: '1.0.0',
    description: 'Personal financial control API. Organize your money across goals, categories and transactions with flexible installment schedules.',
    contact: new OA\Contact(email: 'dev@flowfi.local'),
    license: new OA\License(name: 'MIT'),
)]
#[OA\Server(url: '/api/v1', description: 'FlowFi API v1')]
#[OA\SecurityScheme(
    securityScheme: 'sanctum',
    type: 'http',
    scheme: 'bearer',
    bearerFormat: 'Sanctum token',
    description: 'Token returned by POST /auth/otp/verify. Send it as `Authorization: Bearer <token>`.',
)]
#[OA\Tag(name: 'Authentication', description: 'Passwordless login with an emailed one-time code')]
#[OA\Tag(name: 'Users', description: 'Profile of the authenticated user')]
#[OA\Tag(name: 'Goals', description: 'Savings goals')]
#[OA\Tag(
    name: 'Categories',
    description: 'Transaction categories, optionally with a monthly spending limit',
)]
#[OA\Tag(
    name: 'Transactions',
    description: 'Income, expense and transfer transactions and their installments',
)]
#[OA\Tag(name: 'Notifications', description: 'In-app notifications')]
#[OA\Tag(name: 'Icons', description: 'Icon catalog usable by categories and goals')]
#[OA\Response(
    response: 'UnauthorizedResponse',
    description: 'Missing or invalid token',
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: 'message', type: 'string', example: 'Unauthenticated.'),
        ],
    ),
)]
#[OA\Response(
    response: 'NotFoundResponse',
    description: 'Resource not found (or not owned by the authenticated user)',
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: 'message', type: 'string', example: 'Not found.'),
        ],
    ),
)]
#[OA\Response(
    response: 'ValidationErrorResponse',
    description: 'Validation error',
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: 'message', type: 'string', example: 'The name field is required.'),
            new OA\Property(
                property: 'errors',
                type: 'object',
                additionalProperties: new OA\AdditionalProperties(type: 'array', items: new OA\Items(type: 'string')),
                example: ['name' => ['The name field is required.']],
            ),
        ],
    ),
)]
#[OA\Response(
    response: 'TooManyRequestsResponse',
    description: 'Rate limit exceeded',
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: 'message', type: 'string', example: 'Too Many Attempts.'),
        ],
    ),
)]
#[OA\Schema(
    schema: 'PaginationLinks',
    type: 'object',
    properties: [
        new OA\Property(property: 'first', type: 'string', nullable: true),
        new OA\Property(property: 'last', type: 'string', nullable: true),
        new OA\Property(property: 'prev', type: 'string', nullable: true),
        new OA\Property(property: 'next', type: 'string', nullable: true),
    ],
)]
#[OA\Schema(
    schema: 'PaginationMeta',
    type: 'object',
    properties: [
        new OA\Property(property: 'current_page', type: 'integer', example: 1),
        new OA\Property(property: 'from', type: 'integer', nullable: true, example: 1),
        new OA\Property(property: 'last_page', type: 'integer', example: 3),
        new OA\Property(
            property: 'links',
            type: 'array',
            items: new OA\Items(
                type: 'object',
                properties: [
                    new OA\Property(property: 'url', type: 'string', nullable: true),
                    new OA\Property(property: 'label', type: 'string'),
                    new OA\Property(property: 'active', type: 'boolean'),
                ],
            ),
        ),
        new OA\Property(property: 'path', type: 'string'),
        new OA\Property(property: 'per_page', type: 'integer', example: 20),
        new OA\Property(property: 'to', type: 'integer', nullable: true, example: 20),
        new OA\Property(property: 'total', type: 'integer', example: 42),
    ],
)]
#[OA\Schema(
    schema: 'User',
    type: 'object',
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'first_name', type: 'string', nullable: true),
        new OA\Property(property: 'last_name', type: 'string', nullable: true),
        new OA\Property(property: 'email', type: 'string', format: 'email'),
        new OA\Property(property: 'phone_number', type: 'string', nullable: true),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ],
)]
#[OA\Schema(
    schema: 'UpdateUserRequest',
    type: 'object',
    description: 'All fields optional. `email` cannot be null and must be unique.',
    properties: [
        new OA\Property(property: 'first_name', type: 'string', nullable: true, maxLength: 255),
        new OA\Property(property: 'last_name', type: 'string', nullable: true, maxLength: 255),
        new OA\Property(property: 'phone_number', type: 'string', nullable: true, maxLength: 20),
        new OA\Property(property: 'email', type: 'string', format: 'email', maxLength: 255),
    ],
)]
#[OA\Schema(
    schema: 'Category',
    type: 'object',
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'name', type: 'string', example: 'Groceries'),
        new OA\Property(
            property: 'icon',
            type: 'string',
            description: 'Name from GET /icons',
            example: 'shopping_cart',
        ),
        new OA\Property(property: 'color', type: 'string', pattern: '^#[0-9A-Fa-f]{6}$', example: '#4CAF50'),
        new OA\Property(
            property: 'limit_amount',
            type: 'string',
            format: 'decimal',
            nullable: true,
            description: 'Monthly spending limit',
            example: '1500.00',
        ),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ],
)]
#[OA\Schema(
    schema: 'StoreCategoryRequest',
    type: 'object',
    required: ['name', 'icon', 'color'],
    properties: [
        new OA\Property(
            property: 'name',
            type: 'string',
            maxLength: 255,
            description: 'Unique among the user\'s categories',
            example: 'Groceries',
        ),
        new OA\Property(
            property: 'icon',
            type: 'string',
            description: 'Name from GET /icons',
            example: 'shopping_cart',
        ),
        new OA\Property(
            property: 'color',
            type: 'string',
            pattern: '^#[0-9A-Fa-f]{6}$',
            description: '#RRGGBB, upper or lower case',
            example: '#4CAF50',
        ),
        new OA\Property(
            property: 'limit_amount',
            type: 'string',
            format: 'decimal',
            nullable: true,
            description: '0.01 to 99999999.99, up to 2 decimal places',
            example: '1500.00',
        ),
    ],
)]
#[OA\Schema(
    schema: 'UpdateCategoryRequest',
    type: 'object',
    description: 'All fields optional. `name`, `icon` and `color` cannot be null.',
    properties: [
        new OA\Property(property: 'name', type: 'string', maxLength: 255),
        new OA\Property(property: 'icon', type: 'string'),
        new OA\Property(property: 'color', type: 'string', pattern: '^#[0-9A-Fa-f]{6}$'),
        new OA\Property(property: 'limit_amount', type: 'string', format: 'decimal', nullable: true),
    ],
)]
#[OA\Schema(
    schema: 'Goal',
    type: 'object',
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'name', type: 'string', example: 'Trip to Japan'),
        new OA\Property(property: 'icon', type: 'string', example: 'flight'),
        new OA\Property(property: 'color', type: 'string', pattern: '^#[0-9A-Fa-f]{6}$', example: '#2196F3'),
        new OA\Property(property: 'target_amount', type: 'string', format: 'decimal', example: '10000.00'),
        new OA\Property(
            property: 'current_amount',
            type: 'string',
            format: 'decimal',
            description: 'Balance accumulated through transfers',
            example: '2500.00',
        ),
        new OA\Property(property: 'expires_at', type: 'string', format: 'date', nullable: true),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ],
)]
#[OA\Schema(
    schema: 'StoreGoalRequest',
    type: 'object',
    required: ['name', 'icon', 'color', 'target_amount'],
    properties: [
        new OA\Property(
            property: 'name',
            type: 'string',
            maxLength: 255,
            description: 'Unique among the user\'s goals',
            example: 'Trip to Japan',
        ),
        new OA\Property(
            property: 'icon',
            type: 'string',
            description: 'Name from GET /icons',
            example: 'flight',
        ),
        new OA\Property(property: 'color', type: 'string', pattern: '^#[0-9A-Fa-f]{6}$', example: '#2196F3'),
        new OA\Property(
            property: 'target_amount',
            type: 'string',
            format: 'decimal',
            description: '0.01 to 99999999.99, up to 2 decimal places',
            example: '10000.00',
        ),
        new OA\Property(
            property: 'expires_at',
            type: 'string',
            format: 'date',
            nullable: true,
            description: 'Y-m-d',
        ),
    ],
)]
#[OA\Schema(
    schema: 'UpdateGoalRequest',
    type: 'object',
    description: 'All fields optional. `name`, `icon`, `color` and `target_amount` cannot be null.',
    properties: [
        new OA\Property(property: 'name', type: 'string', maxLength: 255),
        new OA\Property(property: 'icon', type: 'string'),
        new OA\Property(property: 'color', type: 'string', pattern: '^#[0-9A-Fa-f]{6}$'),
        new OA\Property(property: 'target_amount', type: 'string', format: 'decimal'),
        new OA\Property(property: 'expires_at', type: 'string', format: 'date', nullable: true),
    ],
)]
#[OA\Schema(
    schema: 'Installment',
    type: 'object',
    description: 'A single payment within a transaction\'s schedule',
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(
            property: 'step',
            type: 'integer',
            description: 'Order in the schedule (1, 2, 3...)',
            example: 1,
        ),
        new OA\Property(property: 'amount', type: 'string', format: 'decimal', example: '50.17'),
        new OA\Property(property: 'status', type: 'string', enum: ['pending', 'paid'], example: 'pending'),
        new OA\Property(property: 'date', type: 'string', format: 'date', example: '2026-01-15'),
        new OA\Property(property: 'paid_at', type: 'string', format: 'date-time', nullable: true),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ],
)]
#[OA\Schema(
    schema: 'Transaction',
    type: 'object',
    description: 'A money movement with its payment schedule. `category_id` is null for transfers.',
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'category_id', type: 'integer', nullable: true, example: 5),
        new OA\Property(property: 'goal_id', type: 'integer', nullable: true),
        new OA\Property(
            property: 'type',
            type: 'string',
            enum: ['income', 'expense', 'transfer'],
            example: 'expense',
        ),
        new OA\Property(
            property: 'description',
            type: 'string',
            nullable: true,
            example: 'Groceries for the month',
        ),
        new OA\Property(property: 'date', type: 'string', format: 'date', example: '2026-01-15'),
        new OA\Property(property: 'total_amount', type: 'string', format: 'decimal', example: '150.50'),
        new OA\Property(property: 'installments_count', type: 'integer', example: 3),
        new OA\Property(
            property: 'schedule_type',
            type: 'string',
            enum: ['single', 'periodic', 'custom'],
            example: 'periodic',
        ),
        new OA\Property(
            property: 'period_unit',
            type: 'string',
            enum: ['day', 'week', 'month', 'year'],
            nullable: true,
            example: 'month',
        ),
        new OA\Property(property: 'period_interval', type: 'integer', nullable: true, example: 1),
        new OA\Property(
            property: 'installments',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/Installment'),
        ),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ],
)]
#[OA\Schema(
    schema: 'StoreTransactionRequest',
    type: 'object',
    required: ['type', 'date', 'total_amount'],
    description: 'Rules depend on `type`. expense: `category_id` required, `goal_id` optional. income: `category_id` required, `goal_id` forbidden. transfer: `goal_id` required, `category_id`, `installments`, `period_unit` and `period_interval` forbidden, and it cannot be split (`installments_count` must be 1). Send either `installments` (custom schedule) or `installments_count` + `period_*` (even split); mixing them returns 422.',
    properties: [
        new OA\Property(
            property: 'type',
            type: 'string',
            enum: ['income', 'expense', 'transfer'],
            example: 'expense',
        ),
        new OA\Property(
            property: 'category_id',
            type: 'integer',
            nullable: true,
            description: 'Required unless type=transfer; forbidden for transfer',
            example: 5,
        ),
        new OA\Property(
            property: 'goal_id',
            type: 'integer',
            nullable: true,
            description: 'Required for transfer; forbidden for income; optional for expense',
        ),
        new OA\Property(
            property: 'description',
            type: 'string',
            nullable: true,
            maxLength: 1000,
            example: 'Groceries',
        ),
        new OA\Property(
            property: 'date',
            type: 'string',
            format: 'date',
            description: 'Y-m-d',
            example: '2026-01-15',
        ),
        new OA\Property(
            property: 'total_amount',
            type: 'string',
            format: 'decimal',
            description: '0.01 to 99999999.99, up to 2 decimal places',
            example: '150.50',
        ),
        new OA\Property(
            property: 'installments',
            type: 'array',
            nullable: true,
            minItems: 1,
            maxItems: 120,
            description: 'Custom schedule. The amounts must add up to total_amount (422 otherwise). Mutually exclusive with installments_count, period_unit and period_interval (422). Forbidden for transfer.',
            items: new OA\Items(
                type: 'object',
                required: ['amount', 'date'],
                properties: [
                    new OA\Property(
                        property: 'amount',
                        type: 'string',
                        format: 'decimal',
                        description: '0.01 to 99999999.99',
                        example: '50.17',
                    ),
                    new OA\Property(property: 'date', type: 'string', format: 'date', example: '2026-01-15'),
                ],
            ),
        ),
        new OA\Property(
            property: 'installments_count',
            type: 'integer',
            nullable: true,
            minimum: 1,
            maximum: 120,
            description: 'Number of equal installments (default 1)',
            example: 3,
        ),
        new OA\Property(
            property: 'period_unit',
            type: 'string',
            enum: ['day', 'week', 'month', 'year'],
            nullable: true,
            description: 'Required when installments_count > 1. Forbidden for transfer.',
            example: 'month',
        ),
        new OA\Property(
            property: 'period_interval',
            type: 'integer',
            nullable: true,
            minimum: 1,
            maximum: 365,
            description: 'Units between installments (default 1). Forbidden for transfer.',
            example: 1,
        ),
    ],
)]
#[OA\Schema(
    schema: 'UpdateTransactionRequest',
    type: 'object',
    description: 'All fields optional. `type` cannot be changed (sending it returns 422). `category_id` is forbidden on transfers and `goal_id` is forbidden on income (required on transfers). Sending any schedule field (total_amount, installments, installments_count, period_unit, period_interval) regenerates the whole schedule, which returns 422 if the transaction already has a paid installment.',
    properties: [
        new OA\Property(property: 'category_id', type: 'integer', example: 5),
        new OA\Property(property: 'goal_id', type: 'integer', nullable: true),
        new OA\Property(property: 'description', type: 'string', nullable: true, maxLength: 1000),
        new OA\Property(property: 'date', type: 'string', format: 'date'),
        new OA\Property(property: 'total_amount', type: 'string', format: 'decimal'),
        new OA\Property(
            property: 'installments',
            type: 'array',
            minItems: 1,
            maxItems: 120,
            description: 'Custom schedule. Mutually exclusive with installments_count, period_unit and period_interval.',
            items: new OA\Items(
                type: 'object',
                required: ['amount', 'date'],
                properties: [
                    new OA\Property(property: 'amount', type: 'string', format: 'decimal'),
                    new OA\Property(property: 'date', type: 'string', format: 'date'),
                ],
            ),
        ),
        new OA\Property(
            property: 'installments_count',
            type: 'integer',
            nullable: true,
            minimum: 1,
            maximum: 120,
        ),
        new OA\Property(
            property: 'period_unit',
            type: 'string',
            enum: ['day', 'week', 'month', 'year'],
            nullable: true,
        ),
        new OA\Property(property: 'period_interval', type: 'integer', nullable: true, minimum: 1, maximum: 365),
    ],
)]
#[OA\Schema(
    schema: 'Notification',
    type: 'object',
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'title', type: 'string'),
        new OA\Property(property: 'message', type: 'string'),
        new OA\Property(property: 'type', type: 'string', enum: ['info', 'success', 'warning', 'error']),
        new OA\Property(
            property: 'subject',
            type: 'string',
            description: 'Kind of entity the notification refers to',
        ),
        new OA\Property(
            property: 'subject_id',
            type: 'integer',
            nullable: true,
            description: 'ID of that entity',
        ),
        new OA\Property(property: 'read_at', type: 'string', format: 'date-time', nullable: true),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ],
)]
#[OA\Schema(
    schema: 'IconCatalog',
    type: 'object',
    description: 'Icons of one group',
    properties: [
        new OA\Property(property: 'category', type: 'string', example: 'finance'),
        new OA\Property(
            property: 'icons',
            type: 'array',
            items: new OA\Items(type: 'string', example: 'savings'),
        ),
    ],
)]
#[OA\Schema(
    schema: 'RequestOtpRequest',
    type: 'object',
    required: ['email'],
    properties: [
        new OA\Property(
            property: 'email',
            type: 'string',
            format: 'email',
            maxLength: 255,
            example: 'user@example.com',
        ),
    ],
)]
#[OA\Schema(
    schema: 'VerifyOtpRequest',
    type: 'object',
    required: ['email', 'code'],
    properties: [
        new OA\Property(
            property: 'email',
            type: 'string',
            format: 'email',
            maxLength: 255,
            example: 'user@example.com',
        ),
        new OA\Property(
            property: 'code',
            type: 'string',
            description: 'Numeric code with exactly config(\'auth.otp.length\') digits (6 by default)',
            example: '123456',
        ),
    ],
)]
#[OA\Schema(
    schema: 'AuthTokenResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'user', ref: '#/components/schemas/User'),
        new OA\Property(property: 'token', type: 'string', example: '1|abc123...xyz'),
    ],
)]
#[OA\Schema(
    schema: 'MessageResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'message', type: 'string'),
    ],
)]
#[OA\Schema(
    schema: 'UserResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/User'),
    ],
)]
#[OA\Schema(
    schema: 'CategoryResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/Category'),
    ],
)]
#[OA\Schema(
    schema: 'GoalResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/Goal'),
    ],
)]
#[OA\Schema(
    schema: 'TransactionResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/Transaction'),
    ],
)]
#[OA\Schema(
    schema: 'InstallmentResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/Installment'),
    ],
)]
#[OA\Schema(
    schema: 'NotificationResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/Notification'),
    ],
)]
#[OA\Schema(
    schema: 'CategoryListResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/Category'),
        ),
    ],
)]
#[OA\Schema(
    schema: 'GoalListResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', type: 'array', items: new OA\Items(ref: '#/components/schemas/Goal')),
    ],
)]
#[OA\Schema(
    schema: 'IconCatalogResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/IconCatalog'),
        ),
    ],
)]
#[OA\Schema(
    schema: 'TransactionPageResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/Transaction'),
        ),
        new OA\Property(property: 'links', ref: '#/components/schemas/PaginationLinks'),
        new OA\Property(property: 'meta', ref: '#/components/schemas/PaginationMeta'),
    ],
)]
#[OA\Schema(
    schema: 'NotificationPageResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/Notification'),
        ),
        new OA\Property(property: 'links', ref: '#/components/schemas/PaginationLinks'),
        new OA\Property(property: 'meta', ref: '#/components/schemas/PaginationMeta'),
    ],
)]
class Schemas {}