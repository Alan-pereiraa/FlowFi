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
    description: 'Resource ID',
    schema: new OA\Schema(type: 'integer', minimum: 1),
)]
class Parameters {}
