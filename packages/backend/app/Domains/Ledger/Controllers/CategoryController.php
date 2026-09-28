<?php

namespace App\Domains\Ledger\Controllers;

use App\Domains\Ledger\Requests\StoreCategoryRequest;
use App\Domains\Ledger\Requests\UpdateCategoryRequest;
use App\Domains\Ledger\Resources\CategoryResource;
use App\Domains\Ledger\Services\CategoryService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use OpenApi\Attributes as OA;

class CategoryController extends Controller
{
    public function __construct(
        private readonly CategoryService $categories,
    ) {}

    #[OA\Get(
        path: '/categories',
        operationId: 'listCategories',
        tags: ['Categories'],
        summary: 'List categories',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'All categories of the authenticated user',
                content: new OA\JsonContent(ref: '#/components/schemas/CategoryListResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
        ],
    )]
    public function index(Request $request): AnonymousResourceCollection
    {
        return CategoryResource::collection($this->categories->list($request->user()));
    }

    #[OA\Post(
        path: '/categories',
        operationId: 'createCategory',
        tags: ['Categories'],
        summary: 'Create category',
        security: [['sanctum' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/StoreCategoryRequest'),
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'Category created',
                content: new OA\JsonContent(ref: '#/components/schemas/CategoryResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function store(StoreCategoryRequest $request): JsonResponse
    {
        $category = $this->categories->create($request->user(), $request->validated());

        return (new CategoryResource($category))->response()->setStatusCode(Response::HTTP_CREATED);
    }

    #[OA\Get(
        path: '/categories/{id}',
        operationId: 'getCategory',
        tags: ['Categories'],
        summary: 'Get category',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Category',
                content: new OA\JsonContent(ref: '#/components/schemas/CategoryResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function show(Request $request, int $id): CategoryResource
    {
        return new CategoryResource($this->categories->findOwned($request->user(), $id));
    }

    #[OA\Put(
        path: '/categories/{id}',
        operationId: 'putCategory',
        tags: ['Categories'],
        summary: 'Update category (PUT)',
        description: 'Uses the same partial-update behavior as PATCH.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateCategoryRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Category updated',
                content: new OA\JsonContent(ref: '#/components/schemas/CategoryResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    #[OA\Patch(
        path: '/categories/{id}',
        operationId: 'updateCategory',
        tags: ['Categories'],
        summary: 'Update category',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateCategoryRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Category updated',
                content: new OA\JsonContent(ref: '#/components/schemas/CategoryResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function update(UpdateCategoryRequest $request, int $id): CategoryResource
    {
        $category = $this->categories->findOwned($request->user(), $id);

        return new CategoryResource($this->categories->update($category, $request->validated()));
    }

    #[OA\Delete(
        path: '/categories/{id}',
        operationId: 'deleteCategory',
        tags: ['Categories'],
        summary: 'Delete category',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(response: 204, description: 'Deleted'),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function destroy(Request $request, int $id): Response
    {
        $this->categories->delete($this->categories->findOwned($request->user(), $id));

        return response()->noContent();
    }
}
