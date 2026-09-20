<?php

use App\Domains\Ledger\Controllers\CategoryController;
use App\Domains\Ledger\Controllers\GoalController;
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
});
