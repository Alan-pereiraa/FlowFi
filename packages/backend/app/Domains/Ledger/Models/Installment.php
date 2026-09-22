<?php

namespace App\Domains\Ledger\Models;

use App\Domains\Shared\Casts\Money;
use Database\Factories\InstallmentFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\UseFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Fillable(['transaction_id', 'step', 'amount', 'status', 'date', 'paid_at'])]
#[UseFactory(InstallmentFactory::class)]
class Installment extends Model
{
    use HasFactory, SoftDeletes;

    public const string STATUS_PENDING = 'pending';

    public const string STATUS_PAID = 'paid';

    public const array STATUSES = [self::STATUS_PENDING, self::STATUS_PAID];

    protected function casts(): array
    {
        return [
            'amount' => Money::class,
            'step' => 'integer',
            'date' => 'date',
            'paid_at' => 'datetime',
        ];
    }

    /** INSTALLMENT reaches the account only through TRANSACTION (docs/erd.md ownership notes). */
    public function transaction(): BelongsTo
    {
        return $this->belongsTo(Transaction::class);
    }
}
