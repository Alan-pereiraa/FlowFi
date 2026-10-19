<?php

namespace App\Domains\Ledger\Controllers;

use App\Domains\Ledger\Requests\DraftTransactionRequest;
use App\Domains\Ledger\Requests\ListTransactionRequest;
use App\Domains\Ledger\Requests\StoreTransactionRequest;
use App\Domains\Ledger\Requests\UpdateTransactionRequest;
use App\Domains\Ledger\Resources\InstallmentResource;
use App\Domains\Ledger\Resources\TransactionDraftResource;
use App\Domains\Ledger\Resources\TransactionResource;
use App\Domains\Ledger\Services\TransactionService;
use App\Domains\Shared\Services\TranscriptionService;
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
        private readonly TranscriptionService $transcriptions,
    ) {}

    #[OA\Get(
        path: '/transactions',
        operationId: 'listTransactions',
        tags: ['Transações'],
        summary: 'Listar transações (paginado)',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'per_page',
                in: 'query',
                description: 'Tamanho da página; valores fora de 1 a 100 são ajustados ao limite',
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
                description: 'Só transações com todas as parcelas nesta data ou depois',
                schema: new OA\Schema(type: 'string', format: 'date'),
            ),
            new OA\Parameter(
                name: 'date_to',
                in: 'query',
                description: 'Só transações com todas as parcelas nesta data ou antes; deve ser >= date_from',
                schema: new OA\Schema(type: 'string', format: 'date'),
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Transações paginadas, das mais recentes para as mais antigas',
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
        tags: ['Transações'],
        summary: 'Criar transação',
        description: 'Também retorna 422 quando uma despesa ultrapassaria o limite mensal da categoria, ou quando a meta não tem saldo suficiente para a transação.',
        security: [['sanctum' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/StoreTransactionRequest'),
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: 'Transação criada com suas parcelas',
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
        tags: ['Transações'],
        summary: 'Buscar transação',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Transação com as parcelas',
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
        tags: ['Transações'],
        summary: 'Atualizar transação (PUT)',
        description: 'Mesmo comportamento de atualização parcial do PATCH.',
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
                description: 'Transação atualizada',
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
        tags: ['Transações'],
        summary: 'Atualizar transação',
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
                description: 'Transação atualizada',
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
        tags: ['Transações'],
        summary: 'Apagar transação',
        description: 'Faz soft delete da transação e das parcelas e desfaz o efeito dela no saldo da meta.',
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
        $this->transactions->delete($this->transactions->findOwned($request->user(), $id));

        return response()->noContent();
    }

    #[OA\Patch(
        path: '/transactions/{id}/installments/{installmentId}/pay',
        operationId: 'payInstallment',
        tags: ['Transações'],
        summary: 'Marcar parcela como paga',
        description: 'Retorna 422 quando a parcela já está paga.',
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
                description: 'Parcela marcada como paga',
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

    #[OA\Post(
        path: '/transactions/draft',
        operationId: 'draftTransaction',
        tags: ['Transações'],
        summary: 'Gerar rascunho de transação a partir de áudio ou texto',
        description: 'Transcreve `audio` (ou usa `raw_context` como veio) e pede ao provedor de IA um rascunho no formato do corpo de POST /transactions. Nada é salvo: mostre o rascunho ao usuário, peça que preencha os campos obrigatórios que vieram null e então envie para POST /transactions.',
        security: [['sanctum' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: [
                new OA\MediaType(
                    mediaType: 'multipart/form-data',
                    schema: new OA\Schema(
                        required: ['audio'],
                        properties: [
                            new OA\Property(
                                property: 'audio',
                                type: 'string',
                                format: 'binary',
                                description: 'Áudio de até 2 MB: m4a, mp4, webm, ogg, mp3, wav, flac ou aac',
                            ),
                        ],
                    ),
                ),
                new OA\JsonContent(
                    required: ['raw_context'],
                    properties: [
                        new OA\Property(
                            property: 'raw_context',
                            type: 'string',
                            maxLength: 1000,
                            example: 'gastei 50 reais no mercado hoje',
                        ),
                    ],
                ),
            ],
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Rascunho pronto para o usuário confirmar',
                content: new OA\JsonContent(ref: '#/components/schemas/TransactionDraftResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
            new OA\Response(response: 429, ref: '#/components/responses/TooManyRequestsResponse'),
            new OA\Response(response: 502, ref: '#/components/responses/UpstreamErrorResponse'),
            new OA\Response(response: 503, ref: '#/components/responses/UpstreamErrorResponse'),
        ],
    )]
    public function draft(DraftTransactionRequest $request): TransactionDraftResource
    {
        $rawContext = $request->hasFile('audio')
            ? $this->transcriptions->transcribe($request->file('audio'))
            : $request->validated('raw_context');

        return new TransactionDraftResource([
            'transcript' => $rawContext,
            'transaction' => $this->transactions->draftFromRawContext($request->user(), $rawContext),
        ]);
    }
}
