<?php

namespace App\Http\OpenAPI;

use OpenApi\Attributes as OA;

/**
 * Reusable path/query parameters. Kept apart from Schemas.php because swagger-php attaches
 * sibling #[OA\Schema] attributes of the same class to a #[OA\Parameter] instead of to components.
 */
#[OA\Parameter(
    parameter: 'IdPath',
    name: 'id',
    in: 'path',
    required: true,
    description: 'ID do recurso',
    schema: new OA\Schema(type: 'integer', minimum: 1),
)]
#[OA\Parameter(
    parameter: 'DashboardMonth',
    name: 'month',
    in: 'query',
    description: 'Mês de referência das entradas e saídas. Por padrão, considera o mês atual.',
    schema: new OA\Schema(
        type: 'string',
        pattern: '^\d{4}-(0[1-9]|1[0-2])$',
        example: '2026-09',
    ),
)]
class Parameters {}
