<?php

namespace App\Domains\Shared\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Wraps IconCatalog::CATEGORIES as a list so the client can iterate sections
 * in a stable order.
 */
class IconCatalogResource extends JsonResource
{
    /**
     * @return list<array{category: string, icons: list<string>}>
     */
    public function toArray(Request $request): array
    {
        $categories = [];

        foreach ($this->resource as $category => $icons) {
            $categories[] = ['category' => $category, 'icons' => $icons];
        }

        return $categories;
    }
}
