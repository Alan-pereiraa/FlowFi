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

class CategoryController extends Controller
{
    public function __construct(
        private readonly CategoryService $categories,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        return CategoryResource::collection($this->categories->list($request->user()));
    }

    public function store(StoreCategoryRequest $request): JsonResponse
    {
        $category = $this->categories->create($request->user(), $request->validated());

        return (new CategoryResource($category))->response()->setStatusCode(Response::HTTP_CREATED);
    }

    public function show(Request $request, int $id): CategoryResource
    {
        return new CategoryResource($this->categories->findOwned($request->user(), $id));
    }

    public function update(UpdateCategoryRequest $request, int $id): CategoryResource
    {
        $category = $this->categories->findOwned($request->user(), $id);

        return new CategoryResource($this->categories->update($category, $request->validated()));
    }

    public function destroy(Request $request, int $id): Response
    {
        $this->categories->delete($this->categories->findOwned($request->user(), $id));

        return response()->noContent();
    }
}
