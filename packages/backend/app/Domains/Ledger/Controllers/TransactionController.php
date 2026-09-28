<?php

namespace App\Domains\Ledger\Controllers;

use App\Domains\Ledger\Requests\ListTransactionRequest;
use App\Domains\Ledger\Requests\StoreTransactionRequest;
use App\Domains\Ledger\Requests\UpdateTransactionRequest;
use App\Domains\Ledger\Resources\InstallmentResource;
use App\Domains\Ledger\Resources\TransactionResource;
use App\Domains\Ledger\Services\TransactionService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use OpenApi\Attributes as OA;

class TransactionController extends Controller
{
    public function __construct(
        private readonly TransactionService $transactions,
    ) {}

    #[OA\Get(
        path: '/transactions',
        operationId: 'listTransactions',
        tags: ['Transactions'],
        summary: 'List transactions (paginated)',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'per_page',
                in: 'query',
                description: 'Page size; values outside 1-100 are clamped',
                schema: new OA\Schema(type: 'integer', minimum: 1, maximum: 100, default: 20),
            ),
            new OA\Parameter(
                name: 'type',
                in: 'query',
                schema: new OA\Schema(type: 'string', enum: ['income', 'expense', 'transfer']),
            ),
            new OA\Parameter(name: 'category_id', in: 'query', schema: new OA\Schema(type: 'integer')),
            new OA\Parameter(
                name: 'date_from',
                in: 'query',
                description: 'Only transactions whose installments are all on or after this date',
                schema: new OA\Schema(type: 'string', format: 'date'),
            ),
            new OA\Parameter(
                name: 'date_to',
                in: 'query',
                description: 'Only transactions whose installments are all on or before this date; must be >= date_from',
                schema: new OA\Schema(type: 'string', format: 'date'),
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Paginated transactions, newest first',
                content: new OA\JsonContent(ref: '#/components/schemas/TransactionPageResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function index(ListTransactionRequest $request): AnonymousResourceCollection
    {
        return TransactionResource::collection($this->transactions->list(
            $request->user(),
            min(max($request->integer('per_page', 20), 1), 100),
            $request->only(['type', 'category_id', 'date_from', 'date_to'])
        ));
    }

    #[OA\Post(
        path: '/transactions',
        operationId: 'createTransaction',
        tags: ['Transactions'],
        summary: 'Create transaction',
        description: 'Also returns 422 when an expense would exceed the category\'s monthly limit, or when the goal does not have enough balance for the transaction.',
        security: [['sanctum' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/StoreTransactionRequest'),
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'Transaction created with its installments',
                content: new OA\JsonContent(ref: '#/components/schemas/TransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function store(StoreTransactionRequest $request): JsonResponse
    {
        $transaction = $this->transactions->create($request->user(), $request->validated());

        return (new TransactionResource($transaction))->response()->setStatusCode(Response::HTTP_CREATED);
    }

    #[OA\Get(
        path: '/transactions/{id}',
        operationId: 'getTransaction',
        tags: ['Transactions'],
        summary: 'Get transaction',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Transaction with installments',
                content: new OA\JsonContent(ref: '#/components/schemas/TransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function show(Request $request, int $id): TransactionResource
    {
        return new TransactionResource($this->transactions->findOwned($request->user(), $id));
    }

    #[OA\Put(
        path: '/transactions/{id}',
        operationId: 'putTransaction',
        tags: ['Transactions'],
        summary: 'Update transaction (PUT)',
        description: 'Uses the same partial-update behavior as PATCH.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateTransactionRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Transaction updated',
                content: new OA\JsonContent(ref: '#/components/schemas/TransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    #[OA\Patch(
        path: '/transactions/{id}',
        operationId: 'updateTransaction',
        tags: ['Transactions'],
        summary: 'Update transaction',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateTransactionRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Transaction updated',
                content: new OA\JsonContent(ref: '#/components/schemas/TransactionResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function update(UpdateTransactionRequest $request, int $id): TransactionResource
    {
        $transaction = $this->transactions->findOwned($request->user(), $id);

        return new TransactionResource($this->transactions->update($transaction, $request->validated()));
    }

    #[OA\Delete(
        path: '/transactions/{id}',
        operationId: 'deleteTransaction',
        tags: ['Transactions'],
        summary: 'Delete transaction',
        description: 'Soft-deletes the transaction and its installments and reverts its effect on the goal balance.',
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
        $this->transactions->delete($this->transactions->findOwned($request->user(), $id));

        return response()->noContent();
    }

    #[OA\Patch(
        path: '/transactions/{id}/installments/{installmentId}/pay',
        operationId: 'payInstallment',
        tags: ['Transactions'],
        summary: 'Mark installment as paid',
        description: 'Returns 422 when the installment is already paid.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
            new OA\Parameter(
                name: 'installmentId',
                in: 'path',
                required: true,
                schema: new OA\Schema(type: 'integer', minimum: 1),
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Installment marked as paid',
                content: new OA\JsonContent(ref: '#/components/schemas/InstallmentResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function payInstallment(Request $request, int $id, int $installmentId): InstallmentResource
    {
        return new InstallmentResource(
            $this->transactions->payInstallment($request->user(), $id, $installmentId),
        );
    }
}
