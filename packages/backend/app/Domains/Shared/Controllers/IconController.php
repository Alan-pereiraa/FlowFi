<?php

namespace App\Domains\Shared\Controllers;

use App\Domains\Shared\Constants\IconCatalog;
use App\Domains\Shared\Resources\IconCatalogResource;
use App\Http\Controllers\Controller;

class IconController extends Controller
{
    public function index(): IconCatalogResource
    {
        return new IconCatalogResource(IconCatalog::CATEGORIES);
    }
}
