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
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['user_id', 'name', 'type', 'icon', 'color', 'limit_amount'])]
#[UseFactory(CategoryFactory::class)]
class Category extends Model implements HasAppearance
{
    use HasFactory, SoftDeletes;

    public const string TYPE_INCOME = 'income';

    public const string TYPE_EXPENSE = 'expense';

    public const array TYPES = [self::TYPE_INCOME, self::TYPE_EXPENSE];

    public function isIncome(): bool
    {
        return $this->type === self::TYPE_INCOME;
    }

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

    public function recurringTransactions(): HasMany
    {
        return $this->hasMany(RecurringTransaction::class);
    }

    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
