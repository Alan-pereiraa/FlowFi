<?php

namespace App\Domains\Ledger\Models;

use App\Domains\Identity\Models\User;
use App\Domains\Shared\Casts\Money;
use App\Domains\Shared\Contracts\HasAppearance;
use Database\Factories\GoalFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

/**
 * A savings target owned by one user.
 *
 * @property int $id
 * @property int $user_id
 * @property string $name
 * @property string $icon
 * @property string $color
 * @property string $target_amount Decimal string ("1500.00"); stored as cents.
 * @property Carbon|null $expires_at
 * @property Carbon $created_at
 * @property Carbon $updated_at
 * @property Carbon|null $deleted_at
 */
#[Fillable(['user_id', 'name', 'icon', 'color', 'target_amount', 'expires_at'])]
#[UseFactory(GoalFactory::class)]
class Goal extends Model implements HasAppearance
{
    /** @use HasFactory<GoalFactory> */
    use HasFactory, SoftDeletes;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'target_amount' => Money::class,
            'expires_at' => 'date',
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
