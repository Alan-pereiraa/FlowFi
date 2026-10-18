<?php

use App\Domains\Dashboard\Controllers\DashboardController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->prefix('dashboard')->group(function () {
    // Everything the home screen needs in one round trip.
    Route::get('/', [DashboardController::class, 'index']);

    // The same blocks, one by one, for pull-to-refresh on a single card.
    Route::get('summary', [DashboardController::class, 'summary']);
    Route::get('spending-by-category', [DashboardController::class, 'spendingByCategory']);
    Route::get('upcoming-installments', [DashboardController::class, 'upcomingInstallments']);
    Route::get('recent-transactions', [DashboardController::class, 'recentTransactions']);
    Route::get('goals', [DashboardController::class, 'goals']);
});
