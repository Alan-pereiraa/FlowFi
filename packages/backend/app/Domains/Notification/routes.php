<?php

use App\Domains\Notification\Controllers\NotificationController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('notifications', NotificationController::class)
        ->only(['index', 'destroy'])
        ->parameters(['notifications' => 'id'])
        ->where(['id' => '[0-9]+']);

    Route::patch('notifications/{id}/read', [NotificationController::class, 'markAsRead'])
        ->whereNumber('id');
});