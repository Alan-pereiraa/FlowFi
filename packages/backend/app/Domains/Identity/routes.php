<?php

use App\Domains\Identity\Controllers\AuthController;
use App\Domains\Identity\Controllers\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/otp/request', [AuthController::class, 'requestOtp'])
        ->middleware('throttle:otp-request');
    Route::post('/otp/verify', [AuthController::class, 'verifyOtp'])
        ->middleware('throttle:otp-verify');

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

// These must stay inside the auth:sanctum group: UserService::findOwned()
// type-hints a non-nullable User, so a guest reaching the controller would be
// a 500 instead of a 401. The numeric constraint means a non-numeric id never
// matches a route, so the router answers 404 before any code runs.
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('users', UserController::class)
        ->only(['show', 'update', 'destroy'])
        ->parameters(['users' => 'id'])
        ->where(['id' => '[0-9]+']);
});
