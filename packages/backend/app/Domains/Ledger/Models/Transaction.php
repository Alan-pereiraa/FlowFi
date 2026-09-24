<?php

namespace App\Domains\Ledger\Models;

use App\Domains\Identity\Models\User;
use App\Domains\Shared\Casts\Money;
use Database\Factories\TransactionFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable([
    'user_id', 'category_id', 'goal_id', 'type', 'description', 'date',
    'total_amount', 'installments_count', 'schedule_type', 'period_unit', 'period_interval',
])]
#[UseFactory(TransactionFactory::class)]
class Transaction extends Model
{
    use HasFactory, SoftDeletes;

    public const string TYPE_INCOME = 'income';

    public const string TYPE_EXPENSE = 'expense';

    public const string TYPE_TRANSFER = 'transfer';

    public const array TYPES = [self::TYPE_INCOME, self::TYPE_EXPENSE, self::TYPE_TRANSFER];

    public const array PERIOD_UNITS = ['day', 'week', 'month', 'year'];

    public const string SCHEDULE_SINGLE = 'single';

    public const string SCHEDULE_PERIODIC = 'periodic';

    public const string SCHEDULE_CUSTOM = 'custom';

    public const array SCHEDULE_TYPES = [self::SCHEDULE_SINGLE, self::SCHEDULE_PERIODIC, self::SCHEDULE_CUSTOM];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'total_amount' => Money::class,
            'installments_count' => 'integer',
            'period_interval' => 'integer',
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

    public function installments(): HasMany
    {
        return $this->hasMany(Installment::class)->orderBy('step');
    }
}
