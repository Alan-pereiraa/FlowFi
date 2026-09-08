<?php

use App\Domains\Shared\Controllers\IconController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/icons', [IconController::class, 'index']);
});
