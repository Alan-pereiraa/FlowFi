<?php

use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    require app_path('Domains/Identity/routes.php');
    require app_path('Domains/Shared/routes.php');
    require app_path('Domains/Ledger/routes.php');
    require app_path('Domains/Notification/routes.php');
});
