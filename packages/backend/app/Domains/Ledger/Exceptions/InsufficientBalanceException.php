<?php

namespace App\Domains\Ledger\Exceptions;

use Illuminate\Validation\ValidationException;

class InsufficientBalanceException extends ValidationException
{
    public static function forTransfer(): static
    {
        return static::withMessages([
            'total_amount' => 'Saldo insuficiente para fazer esta transferência.',
        ]);
    }
}
