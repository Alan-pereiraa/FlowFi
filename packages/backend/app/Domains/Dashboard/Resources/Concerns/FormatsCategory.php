<?php

namespace App\Domains\Dashboard\Resources\Concerns;

use App\Domains\Ledger\Models\Category;

trait FormatsCategory
{
    private function category(?Category $category): ?array
    {
        return $category === null ? null : [
            'id' => $category->id,
            'name' => $category->name,
            'icon' => $category->icon,
            'color' => $category->color,
        ];
    }
}
