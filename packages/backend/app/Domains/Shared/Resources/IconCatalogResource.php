<?php

namespace App\Domains\Shared\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class IconCatalogResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $categories = [];

        foreach ($this->resource as $category => $icons) {
            $categories[] = ['category' => $category, 'icons' => $icons];
        }

        return $categories;
    }
}
