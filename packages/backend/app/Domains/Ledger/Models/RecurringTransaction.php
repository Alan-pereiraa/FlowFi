<?php

namespace App\Domains\Ledger\Models;

use App\Domains\Identity\Models\User;
use App\Domains\Shared\Casts\Money;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

/**
 * Template that generates one ordinary Transaction per occurrence (salary, rent, a monthly
 * deposit into a goal). Unlike an installment plan, `amount` is repeated in full, not split.
 */
#[Fillable([
    'user_id', 'category_id', 'goal_id', 'type', 'amount', 'description',
    'period_unit', 'period_interval', 'start_date', 'end_date', 'occurrences',
    'generated_count', 'next_occurrence_on',
])]
class RecurringTransaction extends Model
{
    use SoftDeletes;

    protected function casts(): array
    {
        return [
            'amount' => Money::class,
            'period_interval' => 'integer',
            'start_date' => 'immutable_date',
            'end_date' => 'immutable_date',
            'occurrences' => 'integer',
            'generated_count' => 'integer',
            'next_occurrence_on' => 'immutable_date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function goal(): BelongsTo
    {
        return $this->belongsTo(Goal::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
