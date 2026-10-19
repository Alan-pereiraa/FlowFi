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
    description: 'API de controle financeiro pessoal. Organize seu dinheiro em metas, categorias e transações com parcelamentos flexíveis.',
    contact: new OA\Contact(email: 'dev@flowfi.local'),
    license: new OA\License(name: 'MIT'),
)]
#[OA\Server(url: '/api/v1', description: 'FlowFi API v1')]
#[OA\SecurityScheme(
    securityScheme: 'sanctum',
    type: 'http',
    scheme: 'bearer',
    bearerFormat: 'Token Sanctum',
    description: 'Token devolvido por POST /auth/otp/verify. Envie como `Authorization: Bearer <token>`.',
)]
#[OA\Tag(name: 'Autenticação', description: 'Login sem senha com um código de uso único enviado por e-mail')]
#[OA\Tag(name: 'Usuários', description: 'Perfil do usuário autenticado')]
#[OA\Tag(name: 'Metas', description: 'Metas de economia')]
#[OA\Tag(
    name: 'Categorias',
    description: 'Categorias de transação, opcionalmente com um limite mensal de gastos',
)]
#[OA\Tag(
    name: 'Transações',
    description: 'Transações de receita, despesa e transferência e suas parcelas',
)]
#[OA\Tag(
    name: 'Transações recorrentes',
    description: 'Moldes que criam uma transação comum a cada ocorrência (salário, aluguel, um depósito mensal numa meta)',
)]
#[OA\Tag(name: 'Notificações', description: 'Notificações dentro do app')]
#[OA\Tag(name: 'Ícones', description: 'Catálogo de ícones usados por categorias e metas')]
#[OA\Response(
    response: 'UnauthorizedResponse',
    description: 'Token ausente ou inválido',
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: 'message', type: 'string', example: 'Unauthenticated.'),
        ],
    ),
)]
#[OA\Response(
    response: 'NotFoundResponse',
    description: 'Recurso não encontrado (ou não pertence ao usuário autenticado)',
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: 'message', type: 'string', example: 'Not found.'),
        ],
    ),
)]
#[OA\Response(
    response: 'ValidationErrorResponse',
    description: 'Erro de validação',
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
    description: 'Limite de requisições excedido',
    content: new OA\JsonContent(
        properties: [
            new OA\Property(property: 'message', type: 'string', example: 'Too Many Attempts.'),
        ],
    ),
)]
#[OA\Response(
    response: 'UpstreamErrorResponse',
    description: 'O provedor de IA falhou (502) ou está sobrecarregado (503); tente de novo ou preencha a transação manualmente',
    content: new OA\JsonContent(
        properties: [
            new OA\Property(
                property: 'message',
                type: 'string',
                example: 'The AI provider could not process this request. Try again or fill in the transaction manually.',
            ),
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
    description: 'Todos os campos são opcionais. `email` não pode ser null e deve ser único.',
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
        new OA\Property(property: 'name', type: 'string', example: 'Mercado'),
        new OA\Property(
            property: 'icon',
            type: 'string',
            description: 'Nome vindo de GET /icons',
            example: 'shopping_cart',
        ),
        new OA\Property(property: 'color', type: 'string', pattern: '^#[0-9A-Fa-f]{6}$', example: '#4CAF50'),
        new OA\Property(
            property: 'limit_amount',
            type: 'string',
            format: 'decimal',
            nullable: true,
            description: 'Limite mensal de gastos',
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
            description: 'Único entre as categorias do usuário',
            example: 'Mercado',
        ),
        new OA\Property(
            property: 'icon',
            type: 'string',
            description: 'Nome vindo de GET /icons',
            example: 'shopping_cart',
        ),
        new OA\Property(
            property: 'color',
            type: 'string',
            pattern: '^#[0-9A-Fa-f]{6}$',
            description: '#RRGGBB, maiúsculas ou minúsculas',
            example: '#4CAF50',
        ),
        new OA\Property(
            property: 'limit_amount',
            type: 'string',
            format: 'decimal',
            nullable: true,
            description: 'De 0.01 a 99999999.99, com até 2 casas decimais',
            example: '1500.00',
        ),
    ],
)]
#[OA\Schema(
    schema: 'UpdateCategoryRequest',
    type: 'object',
    description: 'Todos os campos são opcionais. `name`, `icon` e `color` não podem ser null.',
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
        new OA\Property(property: 'name', type: 'string', example: 'Viagem ao Japão'),
        new OA\Property(property: 'icon', type: 'string', example: 'flight'),
        new OA\Property(property: 'color', type: 'string', pattern: '^#[0-9A-Fa-f]{6}$', example: '#2196F3'),
        new OA\Property(property: 'target_amount', type: 'string', format: 'decimal', example: '10000.00'),
        new OA\Property(
            property: 'current_amount',
            type: 'string',
            format: 'decimal',
            description: 'Saldo acumulado por meio de transferências',
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
            description: 'Único entre as metas do usuário',
            example: 'Viagem ao Japão',
        ),
        new OA\Property(
            property: 'icon',
            type: 'string',
            description: 'Nome vindo de GET /icons',
            example: 'flight',
        ),
        new OA\Property(property: 'color', type: 'string', pattern: '^#[0-9A-Fa-f]{6}$', example: '#2196F3'),
        new OA\Property(
            property: 'target_amount',
            type: 'string',
            format: 'decimal',
            description: 'De 0.01 a 99999999.99, com até 2 casas decimais',
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
    description: 'Todos os campos são opcionais. `name`, `icon`, `color` e `target_amount` não podem ser null.',
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
    description: 'Um pagamento do cronograma de uma transação',
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(
            property: 'step',
            type: 'integer',
            description: 'Posição no cronograma (1, 2, 3...)',
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
    description: 'Uma movimentação de dinheiro com seu cronograma de pagamento. `category_id` é null em transferências.',
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
            example: 'Compras do mês',
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
            property: 'recurring_transaction_id',
            type: 'integer',
            nullable: true,
            description: 'Transação recorrente que gerou esta; null para transações criadas diretamente',
        ),
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
    description: 'As regras dependem de `type`. expense: `category_id` obrigatório, `goal_id` opcional. income: `category_id` obrigatório, `goal_id` proibido. transfer: `goal_id` obrigatório; `category_id`, `installments`, `period_unit` e `period_interval` proibidos; e não pode ser parcelada (`installments_count` deve ser 1). Envie `installments` (cronograma personalizado) ou `installments_count` + `period_*` (divisão igual); misturar os dois retorna 422.',
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
            description: 'Obrigatório, exceto quando type=transfer; proibido em transfer',
            example: 5,
        ),
        new OA\Property(
            property: 'goal_id',
            type: 'integer',
            nullable: true,
            description: 'Obrigatório em transfer; proibido em income; opcional em expense',
        ),
        new OA\Property(
            property: 'description',
            type: 'string',
            nullable: true,
            maxLength: 1000,
            example: 'Mercado',
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
            description: 'De 0.01 a 99999999.99, com até 2 casas decimais',
            example: '150.50',
        ),
        new OA\Property(
            property: 'installments',
            type: 'array',
            nullable: true,
            minItems: 1,
            maxItems: 120,
            description: 'Cronograma personalizado. A soma dos valores deve ser igual a total_amount (senão, 422). Não pode ser combinado com installments_count, period_unit e period_interval (422). Proibido em transfer.',
            items: new OA\Items(
                type: 'object',
                required: ['amount', 'date'],
                properties: [
                    new OA\Property(
                        property: 'amount',
                        type: 'string',
                        format: 'decimal',
                        description: 'De 0.01 a 99999999.99',
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
            description: 'Quantidade de parcelas iguais (padrão 1)',
            example: 3,
        ),
        new OA\Property(
            property: 'period_unit',
            type: 'string',
            enum: ['day', 'week', 'month', 'year'],
            nullable: true,
            description: 'Obrigatório quando installments_count > 1. Proibido em transfer.',
            example: 'month',
        ),
        new OA\Property(
            property: 'period_interval',
            type: 'integer',
            nullable: true,
            minimum: 1,
            maximum: 365,
            description: 'Unidades de período entre as parcelas (padrão 1). Proibido em transfer.',
            example: 1,
        ),
    ],
)]
#[OA\Schema(
    schema: 'UpdateTransactionRequest',
    type: 'object',
    description: 'Todos os campos são opcionais. `type` não pode ser alterado (enviá-lo retorna 422). `category_id` é proibido em transferências e `goal_id` é proibido em receitas (obrigatório em transferências). Enviar qualquer campo do cronograma (total_amount, installments, installments_count, period_unit, period_interval) gera o cronograma inteiro de novo, o que retorna 422 se a transação já tiver alguma parcela paga.',
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
            description: 'Cronograma personalizado. Não pode ser combinado com installments_count, period_unit e period_interval.',
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
    schema: 'RecurringTransaction',
    type: 'object',
    description: 'Molde repetido integralmente a cada período. `next_occurrence_on` fica null depois que ela é encerrada ou gera todas as ocorrências.',
    properties: [
        new OA\Property(property: 'id', type: 'integer', example: 1),
        new OA\Property(property: 'category_id', type: 'integer', nullable: true, example: 5),
        new OA\Property(property: 'goal_id', type: 'integer', nullable: true),
        new OA\Property(
            property: 'type',
            type: 'string',
            enum: ['income', 'expense', 'transfer'],
            example: 'income',
        ),
        new OA\Property(property: 'description', type: 'string', nullable: true, example: 'Salário'),
        new OA\Property(
            property: 'amount',
            type: 'string',
            format: 'decimal',
            description: 'Valor de cada ocorrência (não é dividido)',
            example: '5000.00',
        ),
        new OA\Property(
            property: 'period_unit',
            type: 'string',
            enum: ['day', 'week', 'month', 'year'],
            example: 'month',
        ),
        new OA\Property(property: 'period_interval', type: 'integer', example: 1),
        new OA\Property(property: 'start_date', type: 'string', format: 'date', example: '2027-01-05'),
        new OA\Property(property: 'end_date', type: 'string', format: 'date', nullable: true),
        new OA\Property(property: 'occurrences', type: 'integer', nullable: true),
        new OA\Property(property: 'generated_count', type: 'integer', example: 3),
        new OA\Property(
            property: 'next_occurrence_on',
            type: 'string',
            format: 'date',
            nullable: true,
            example: '2027-04-05',
        ),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ],
)]
#[OA\Schema(
    schema: 'StoreRecurringTransactionRequest',
    type: 'object',
    required: ['type', 'amount', 'period_unit', 'start_date'],
    description: 'Mesmas regras de `type` do StoreTransactionRequest para `category_id` e `goal_id`. Envie `end_date` ou `occurrences` para definir o fim, ou nenhum dos dois para repetir até ser encerrada; enviar os dois retorna 422.',
    properties: [
        new OA\Property(
            property: 'type',
            type: 'string',
            enum: ['income', 'expense', 'transfer'],
            example: 'income',
        ),
        new OA\Property(
            property: 'category_id',
            type: 'integer',
            nullable: true,
            description: 'Obrigatório, exceto quando type=transfer; proibido em transfer',
            example: 5,
        ),
        new OA\Property(
            property: 'goal_id',
            type: 'integer',
            nullable: true,
            description: 'Obrigatório em transfer; proibido em income; opcional em expense',
        ),
        new OA\Property(property: 'description', type: 'string', nullable: true, maxLength: 1000, example: 'Salário'),
        new OA\Property(
            property: 'amount',
            type: 'string',
            format: 'decimal',
            description: 'De 0.01 a 99999999.99, repetido integralmente em cada ocorrência',
            example: '5000.00',
        ),
        new OA\Property(
            property: 'period_unit',
            type: 'string',
            enum: ['day', 'week', 'month', 'year'],
            example: 'month',
        ),
        new OA\Property(
            property: 'period_interval',
            type: 'integer',
            nullable: true,
            minimum: 1,
            maximum: 365,
            description: 'Unidades de período entre as ocorrências (padrão 1)',
            example: 1,
        ),
        new OA\Property(
            property: 'start_date',
            type: 'string',
            format: 'date',
            description: 'Primeira ocorrência. Pode estar até um ano no passado; as ocorrências passadas são criadas ao salvar.',
            example: '2027-01-05',
        ),
        new OA\Property(
            property: 'end_date',
            type: 'string',
            format: 'date',
            nullable: true,
            description: 'Opcional. Até quando repetir: a última ocorrência cai no máximo nesta data, que não pode ser antes de start_date. Não pode ser enviado junto com occurrences (422).',
            example: '2027-06-30',
        ),
        new OA\Property(
            property: 'occurrences',
            type: 'integer',
            nullable: true,
            minimum: 2,
            maximum: 120,
            description: 'Opcional. Quantas vezes a transação se repete no total; depois da última, a recorrência para sozinha (ex.: 6 = de 16/10/2026 a 16/03/2027, mensal). Não pode ser enviado junto com end_date (422). Sem end_date e sem occurrences, repete até ser encerrada.',
            example: 6,
        ),
    ],
)]
#[OA\Schema(
    schema: 'UpdateRecurringTransactionRequest',
    type: 'object',
    description: 'Todos os campos são opcionais; só as próximas ocorrências recebem a alteração. `type`, `period_unit`, `period_interval`, `start_date`, `end_date` e `occurrences` não podem ser alterados (422): encerre esta e crie outra.',
    properties: [
        new OA\Property(property: 'category_id', type: 'integer', example: 5),
        new OA\Property(property: 'goal_id', type: 'integer', nullable: true),
        new OA\Property(property: 'description', type: 'string', nullable: true, maxLength: 1000),
        new OA\Property(property: 'amount', type: 'string', format: 'decimal', example: '5500.00'),
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
            description: 'Tipo de evento ou entidade a que a notificação se refere',
        ),
        new OA\Property(
            property: 'subject_id',
            type: 'integer',
            nullable: true,
            description: 'ID dessa entidade',
        ),
        new OA\Property(property: 'read_at', type: 'string', format: 'date-time', nullable: true),
        new OA\Property(property: 'created_at', type: 'string', format: 'date-time'),
        new OA\Property(property: 'updated_at', type: 'string', format: 'date-time'),
    ],
)]
#[OA\Schema(
    schema: 'IconCatalog',
    type: 'object',
    description: 'Ícones de um grupo',
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
            description: 'Código numérico com exatamente config(\'auth.otp.length\') dígitos (6 por padrão)',
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
    schema: 'RecurringTransactionResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/RecurringTransaction'),
    ],
)]
#[OA\Schema(
    schema: 'RecurringTransactionListResponse',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'data',
            type: 'array',
            items: new OA\Items(ref: '#/components/schemas/RecurringTransaction'),
        ),
    ],
)]
#[OA\Schema(
    schema: 'TransactionDraft',
    type: 'object',
    properties: [
        new OA\Property(
            property: 'transcript',
            type: 'string',
            description: 'Texto usado para montar o rascunho: a transcrição de `audio`, ou `raw_context` como foi enviado',
            example: 'gastei 50 reais no mercado hoje',
        ),
        new OA\Property(
            property: 'transaction',
            ref: '#/components/schemas/StoreTransactionRequest',
            description: 'Corpo para POST /transactions. Todas as chaves estão presentes; null significa que a IA não conseguiu identificar. `installments` nunca é preenchido no rascunho.',
        ),
    ],
)]
#[OA\Schema(
    schema: 'TransactionDraftResponse',
    type: 'object',
    properties: [
        new OA\Property(property: 'data', ref: '#/components/schemas/TransactionDraft'),
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
