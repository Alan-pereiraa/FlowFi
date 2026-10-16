<?php

use App\Domains\Ledger\Controllers\CategoryController;
use App\Domains\Ledger\Controllers\GoalController;
use App\Domains\Ledger\Controllers\RecurringTransactionController;
use App\Domains\Ledger\Controllers\TransactionController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('goals', GoalController::class)
        ->parameters(['goals' => 'id'])
        ->where(['id' => '[0-9]+']);

    Route::apiResource('categories', CategoryController::class)
        ->parameters(['categories' => 'id'])
        ->where(['id' => '[0-9]+']);

    Route::apiResource('transactions', TransactionController::class)
        ->parameters(['transactions' => 'id'])
        ->where(['id' => '[0-9]+']);

    // Installment is an auxiliary table of Transaction, not a resource of its own — no
    // dedicated controller, just this one action on TransactionController.
    Route::patch('transactions/{id}/installments/{installmentId}/pay', [TransactionController::class, 'payInstallment'])
        ->whereNumber(['id', 'installmentId']);

    Route::apiResource('recurring-transactions', RecurringTransactionController::class)
        ->parameters(['recurring-transactions' => 'id'])
        ->where(['id' => '[0-9]+']);

    Route::patch('recurring-transactions/{id}/end', [RecurringTransactionController::class, 'end'])
        ->whereNumber('id');

    // Read-only: returns a POST /transactions body for the client to confirm; nothing is saved.
    Route::post('transactions/draft', [TransactionController::class, 'draft'])
        ->middleware('throttle:transaction-draft');
});
