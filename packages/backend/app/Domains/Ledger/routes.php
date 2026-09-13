<?php

use App\Domains\Ledger\Controllers\CategoryController;
use App\Domains\Ledger\Controllers\GoalController;
use App\Domains\Ledger\Controllers\InstallmentController;
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

    Route::patch('transactions/{transactionId}/installments/{installmentId}/pay', [InstallmentController::class, 'pay'])
        ->whereNumber(['transactionId', 'installmentId']);
});
