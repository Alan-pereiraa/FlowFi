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
        tags: ['Transações recorrentes'],
        summary: 'Listar transações recorrentes',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Todas as transações recorrentes do usuário autenticado, ativas e encerradas',
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
        tags: ['Transações recorrentes'],
        summary: 'Criar transação recorrente',
        description: 'As ocorrências com data até hoje são geradas na hora como transações comuns.',
        security: [['sanctum' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                ref: '#/components/schemas/StoreRecurringTransactionRequest',
                examples: [
                    new OA\Examples(
                        example: 'ate_cancelar',
                        summary: 'Até cancelar (sem end_date nem occurrences)',
                        value: [
                            'type' => 'income',
                            'category_id' => 5,
                            'amount' => '5000.00',
                            'description' => 'Salário',
                            'period_unit' => 'month',
                            'start_date' => '2026-10-16',
                        ],
                    ),
                    new OA\Examples(
                        example: 'n_vezes',
                        summary: 'Por um número de vezes (occurrences)',
                        value: [
                            'type' => 'income',
                            'category_id' => 5,
                            'amount' => '2000.00',
                            'description' => 'Freela',
                            'period_unit' => 'month',
                            'start_date' => '2026-10-16',
                            'occurrences' => 6,
                        ],
                    ),
                    new OA\Examples(
                        example: 'ate_uma_data',
                        summary: 'Até uma data (end_date)',
                        value: [
                            'type' => 'transfer',
                            'goal_id' => 2,
                            'amount' => '200.00',
                            'description' => 'Viagem',
                            'period_unit' => 'month',
                            'start_date' => '2026-10-16',
                            'end_date' => '2027-06-30',
                        ],
                    ),
                ],
            ),
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'Transação recorrente criada',
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
        tags: ['Transações recorrentes'],
        summary: 'Buscar transação recorrente',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Transação recorrente',
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

    #[OA\Patch(
        path: '/recurring-transactions/{id}',
        operationId: 'updateRecurringTransaction',
        tags: ['Transações recorrentes'],
        summary: 'Atualizar transação recorrente',
        description: 'Só as próximas ocorrências recebem a alteração; as transações já geradas não mudam.',
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
                description: 'Transação recorrente atualizada',
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
        tags: ['Transações recorrentes'],
        summary: 'Encerrar transação recorrente',
        description: 'Para de gerar ocorrências a partir de hoje. As transações já geradas são mantidas. Pode ser chamada mais de uma vez sem efeito extra.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Transação recorrente encerrada',
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
        tags: ['Transações recorrentes'],
        summary: 'Apagar transação recorrente',
        description: 'As transações já geradas são mantidas.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(response: 204, description: 'Apagada'),
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
