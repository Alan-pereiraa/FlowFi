<?php

namespace App\Domains\Shared\Repositories;

use App\Domains\Shared\Contracts\HasAppearance;
use Illuminate\Database\Eloquent\Model;

class EloquentAppearanceRepository implements AppearanceRepositoryInterface
{
    public function update(Model&HasAppearance $model, array $attributes): void
    {
        $model->forceFill($attributes)->save();
    }
}
