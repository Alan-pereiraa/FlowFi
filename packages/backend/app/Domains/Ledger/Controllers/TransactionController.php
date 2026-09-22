<?php

namespace App\Domains\Ledger\Controllers;

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
use App\Domains\Ledger\Requests\ListTransactionRequest;

class TransactionController extends Controller
{
    public function __construct(
        private readonly TransactionService $transactions,
    ) {}

    public function index(ListTransactionRequest $request): AnonymousResourceCollection
    {
        return TransactionResource::collection($this->transactions->list(
            $request->user(),
            min(max($request->integer('per_page', 20), 1), 100),
            $request->only(['type', 'category_id', 'date_from', 'date_to'])
        ));
    }

    public function store(StoreTransactionRequest $request): JsonResponse
    {
        $transaction = $this->transactions->create($request->user(), $request->validated());

        return (new TransactionResource($transaction))->response()->setStatusCode(Response::HTTP_CREATED);
    }

    public function show(Request $request, int $id): TransactionResource
    {
        return new TransactionResource($this->transactions->findOwned($request->user(), $id));
    }

    public function update(UpdateTransactionRequest $request, int $id): TransactionResource
    {
        $transaction = $this->transactions->findOwned($request->user(), $id);

        return new TransactionResource($this->transactions->update($transaction, $request->validated()));
    }

    public function destroy(Request $request, int $id): Response
    {
        $this->transactions->delete($this->transactions->findOwned($request->user(), $id));

        return response()->noContent();
    }

    public function payInstallment(Request $request, int $id, int $installmentId): InstallmentResource
    {
        return new InstallmentResource(
            $this->transactions->payInstallment($request->user(), $id, $installmentId),
        );
    }
}
