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

Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('users', UserController::class)
        ->only(['show', 'update', 'destroy'])
        ->parameters(['users' => 'id'])
        ->where(['id' => '[0-9]+']);
});
