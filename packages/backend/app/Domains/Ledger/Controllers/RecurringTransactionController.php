<?php

namespace App\Domains\Ledger\Controllers;

use App\Domains\Ledger\Requests\StoreRecurringTransactionRequest;
use App\Domains\Ledger\Requests\UpdateRecurringTransactionRequest;
use App\Domains\Ledger\Resources\RecurringTransactionResource;
use App\Domains\Ledger\Services\RecurringTransactionService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use OpenApi\Attributes as OA;

class RecurringTransactionController extends Controller
{
    public function __construct(
        private readonly RecurringTransactionService $recurring,
    ) {}

    #[OA\Get(
        path: '/recurring-transactions',
        operationId: 'listRecurringTransactions',
        tags: ['Recurring transactions'],
        summary: 'List recurring transactions',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'All recurring transactions of the authenticated user, active and ended',
                content: new OA\JsonContent(ref: '#/components/schemas/RecurringTransactionListResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
        ],
    )]
    public function index(Request $request): AnonymousResourceCollection
    {
        return RecurringTransactionResource::collection($this->recurring->list($request->user()));
    }

    #[OA\Post(
        path: '/recurring-transactions',
        operationId: 'createRecurringTransaction',
        tags: ['Recurring transactions'],
        summary: 'Create recurring transaction',
        description: 'Occurrences due on or before today are generated immediately as ordinary transactions.',
        security: [['sanctum' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/StoreRecurringTransactionRequest'),
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'Recurring transaction created',
                content: new OA\JsonContent(ref: '#/components/schemas/RecurringTransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function store(StoreRecurringTransactionRequest $request): JsonResponse
    {
        $recurring = $this->recurring->create($request->user(), $request->validated());

        return (new RecurringTransactionResource($recurring))->response()->setStatusCode(Response::HTTP_CREATED);
    }

    #[OA\Get(
        path: '/recurring-transactions/{id}',
        operationId: 'getRecurringTransaction',
        tags: ['Recurring transactions'],
        summary: 'Get recurring transaction',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Recurring transaction',
                content: new OA\JsonContent(ref: '#/components/schemas/RecurringTransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function show(Request $request, int $id): RecurringTransactionResource
    {
        return new RecurringTransactionResource($this->recurring->findOwned($request->user(), $id));
    }

    #[OA\Put(
        path: '/recurring-transactions/{id}',
        operationId: 'putRecurringTransaction',
        tags: ['Recurring transactions'],
        summary: 'Update recurring transaction (PUT)',
        description: 'Uses the same partial-update behavior as PATCH.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateRecurringTransactionRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Recurring transaction updated',
                content: new OA\JsonContent(ref: '#/components/schemas/RecurringTransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    #[OA\Patch(
        path: '/recurring-transactions/{id}',
        operationId: 'updateRecurringTransaction',
        tags: ['Recurring transactions'],
        summary: 'Update recurring transaction',
        description: 'Only future occurrences pick up the change; transactions already generated are not touched.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateRecurringTransactionRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Recurring transaction updated',
                content: new OA\JsonContent(ref: '#/components/schemas/RecurringTransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function update(UpdateRecurringTransactionRequest $request, int $id): RecurringTransactionResource
    {
        $recurring = $this->recurring->findOwned($request->user(), $id);

        return new RecurringTransactionResource($this->recurring->update($recurring, $request->validated()));
    }

    #[OA\Patch(
        path: '/recurring-transactions/{id}/end',
        operationId: 'endRecurringTransaction',
        tags: ['Recurring transactions'],
        summary: 'End recurring transaction',
        description: 'Stops generating occurrences from today on. Transactions already generated are kept. Idempotent.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Recurring transaction ended',
                content: new OA\JsonContent(ref: '#/components/schemas/RecurringTransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function end(Request $request, int $id): RecurringTransactionResource
    {
        $recurring = $this->recurring->findOwned($request->user(), $id);

        return new RecurringTransactionResource($this->recurring->end($recurring));
    }

    #[OA\Delete(
        path: '/recurring-transactions/{id}',
        operationId: 'deleteRecurringTransaction',
        tags: ['Recurring transactions'],
        summary: 'Delete recurring transaction',
        description: 'Transactions already generated are kept.',
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
        $this->recurring->delete($this->recurring->findOwned($request->user(), $id));

        return response()->noContent();
    }
}
