<?php

namespace App\Domains\Ledger\Controllers;

use App\Domains\Ledger\Resources\InstallmentResource;
use App\Domains\Ledger\Services\TransactionService;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class InstallmentController extends Controller
{
    public function __construct(
        private readonly TransactionService $transactions,
    ) {}

    /** Installments are transaction-scoped (docs/erd.md), so they have no owning-Service of their own. */
    public function pay(Request $request, int $transactionId, int $installmentId): InstallmentResource
    {
        return new InstallmentResource(
            $this->transactions->payInstallment($request->user(), $transactionId, $installmentId),
        );
    }
}
