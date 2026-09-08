<?php

namespace App\Domains\Ledger\Controllers;

use App\Domains\Ledger\Requests\StoreGoalRequest;
use App\Domains\Ledger\Requests\UpdateGoalRequest;
use App\Domains\Ledger\Resources\GoalResource;
use App\Domains\Ledger\Services\GoalService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;

class GoalController extends Controller
{
    public function __construct(
        private readonly GoalService $goals,
    ) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        return GoalResource::collection($this->goals->list($request->user()));
    }

    public function store(StoreGoalRequest $request): JsonResponse
    {
        $goal = $this->goals->create($request->user(), $request->validated());

        return (new GoalResource($goal))->response()->setStatusCode(Response::HTTP_CREATED);
    }

    public function show(Request $request, int $id): GoalResource
    {
        return new GoalResource($this->goals->findOwned($request->user(), $id));
    }

    public function update(UpdateGoalRequest $request, int $id): GoalResource
    {
        $goal = $this->goals->findOwned($request->user(), $id);

        return new GoalResource($this->goals->update($goal, $request->validated()));
    }

    public function destroy(Request $request, int $id): Response
    {
        $this->goals->delete($this->goals->findOwned($request->user(), $id));

        return response()->noContent();
    }
}
