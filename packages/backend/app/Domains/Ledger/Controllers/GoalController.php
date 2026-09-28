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
use OpenApi\Attributes as OA;

class GoalController extends Controller
{
    public function __construct(
        private readonly GoalService $goals,
    ) {}

    #[OA\Get(
        path: '/goals',
        operationId: 'listGoals',
        tags: ['Goals'],
        summary: 'List goals',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'All goals of the authenticated user',
                content: new OA\JsonContent(ref: '#/components/schemas/GoalListResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
        ],
    )]
    public function index(Request $request): AnonymousResourceCollection
    {
        return GoalResource::collection($this->goals->list($request->user()));
    }

    #[OA\Post(
        path: '/goals',
        operationId: 'createGoal',
        tags: ['Goals'],
        summary: 'Create goal',
        security: [['sanctum' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/StoreGoalRequest'),
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'Goal created',
                content: new OA\JsonContent(ref: '#/components/schemas/GoalResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function store(StoreGoalRequest $request): JsonResponse
    {
        $goal = $this->goals->create($request->user(), $request->validated());

        return (new GoalResource($goal))->response()->setStatusCode(Response::HTTP_CREATED);
    }

    #[OA\Get(
        path: '/goals/{id}',
        operationId: 'getGoal',
        tags: ['Goals'],
        summary: 'Get goal',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Goal',
                content: new OA\JsonContent(ref: '#/components/schemas/GoalResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function show(Request $request, int $id): GoalResource
    {
        return new GoalResource($this->goals->findOwned($request->user(), $id));
    }

    #[OA\Put(
        path: '/goals/{id}',
        operationId: 'putGoal',
        tags: ['Goals'],
        summary: 'Update goal (PUT)',
        description: 'Uses the same partial-update behavior as PATCH.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateGoalRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Goal updated',
                content: new OA\JsonContent(ref: '#/components/schemas/GoalResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    #[OA\Patch(
        path: '/goals/{id}',
        operationId: 'updateGoal',
        tags: ['Goals'],
        summary: 'Update goal',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateGoalRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Goal updated',
                content: new OA\JsonContent(ref: '#/components/schemas/GoalResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function update(UpdateGoalRequest $request, int $id): GoalResource
    {
        $goal = $this->goals->findOwned($request->user(), $id);

        return new GoalResource($this->goals->update($goal, $request->validated()));
    }

    #[OA\Delete(
        path: '/goals/{id}',
        operationId: 'deleteGoal',
        tags: ['Goals'],
        summary: 'Delete goal',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(response: 204, description: 'Deleted'),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function destroy(Request $request, int $id): Response
    {
        $this->goals->delete($this->goals->findOwned($request->user(), $id));

        return response()->noContent();
    }
}
