<?php

namespace App\Domains\Shared\Controllers;

use App\Domains\Shared\Constants\IconCatalog;
use App\Domains\Shared\Resources\IconCatalogResource;
use App\Http\Controllers\Controller;
use OpenApi\Attributes as OA;

class IconController extends Controller
{
    #[OA\Get(
        path: '/icons',
        operationId: 'listIcons',
        tags: ['Icons'],
        summary: 'List available icons',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Icons grouped by category',
                content: new OA\JsonContent(ref: '#/components/schemas/IconCatalogResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
        ],
    )]
    public function index(): IconCatalogResource
    {
        return new IconCatalogResource(IconCatalog::CATEGORIES);
    }
}
