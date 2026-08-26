<?php

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    require app_path('Domains/Identity/routes.php');
});
