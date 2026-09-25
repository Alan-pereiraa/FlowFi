<?php

namespace App\Domains\Ledger\Models;

use App\Domains\Identity\Models\User;
use App\Domains\Shared\Casts\Money;
use App\Domains\Shared\Contracts\HasAppearance;
use Database\Factories\CategoryFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'name', 'icon', 'color', 'limit_amount'])]
#[UseFactory(CategoryFactory::class)]
class Category extends Model implements HasAppearance
{
    use HasFactory, SoftDeletes;

    protected function casts(): array
    {
        return [
            'limit_amount' => Money::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
