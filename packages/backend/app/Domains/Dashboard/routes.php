<?php

use App\Domains\Dashboard\Controllers\DashboardController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->prefix('dashboard')->group(function () {
    Route::get('summary', [DashboardController::class, 'summary']);
    Route::get('goals', [DashboardController::class, 'goals']);
    Route::get('recent-transactions', [DashboardController::class, 'recentTransactions']);
});
