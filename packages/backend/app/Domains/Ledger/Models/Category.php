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
use Illuminate\Support\Carbon;

/**
 * A label a user files transactions under, optionally with a spending cap.
 *
 * @property int $id
 * @property int $user_id
 * @property string $name
 * @property string $icon
 * @property string $color
 * @property string|null $limit_amount Decimal string ("500.00") or null for no cap; stored as cents.
 * @property Carbon $created_at
 * @property Carbon $updated_at
 * @property Carbon|null $deleted_at
 */
#[Fillable(['user_id', 'name', 'icon', 'color', 'limit_amount'])]
#[UseFactory(CategoryFactory::class)]
class Category extends Model implements HasAppearance
{
    /** @use HasFactory<CategoryFactory> */
    use HasFactory, SoftDeletes;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'limit_amount' => Money::class,
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
