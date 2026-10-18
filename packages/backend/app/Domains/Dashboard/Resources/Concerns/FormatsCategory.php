<?php

namespace App\Domains\Dashboard\Resources\Concerns;

use App\Domains\Ledger\Models\Category;

trait FormatsCategory
{
    /**
     * Just enough for a card to draw the category chip. Null when the row has no category at all;
     * a category deleted after the fact keeps its old name, icon and color.
     */
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
