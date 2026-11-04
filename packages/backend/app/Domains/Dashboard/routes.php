<?php

use App\Domains\Dashboard\Controllers\DashboardController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->prefix('dashboard')->group(function () {
    Route::get('/', [DashboardController::class, 'index']);

    Route::get('summary', [DashboardController::class, 'summary']);
    Route::get('spending-by-category', [DashboardController::class, 'spendingByCategory']);
    Route::get('upcoming-installments', [DashboardController::class, 'upcomingInstallments']);
    Route::get('recent-transactions', [DashboardController::class, 'recentTransactions']);
    Route::get('goals', [DashboardController::class, 'goals']);
});
