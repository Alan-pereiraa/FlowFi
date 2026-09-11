<?php

namespace App\Domains\Shared\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;

class Money implements CastsAttributes
{
    public function get(Model $model, string $key, mixed $value, array $attributes): ?string
    {
        if ($value === null) {
            return null;
        }

        $cents = (int) $value;
        $magnitude = abs($cents);

        return sprintf('%s%d.%02d', $cents < 0 ? '-' : '', intdiv($magnitude, 100), $magnitude % 100);
    }

    public function set(Model $model, string $key, mixed $value, array $attributes): ?int
    {
        if ($value === null) {
            return null;
        }

        if (is_float($value)) {
            $value = number_format($value, 2, '.', '');
        }

        $decimal = trim((string) $value);

        if (preg_match('/^([+-]?)(\d+)(?:\.(\d{1,2}))?$/', $decimal, $matches) !== 1) {
            throw new InvalidArgumentException("[{$key}] must be a decimal with at most two places, got [{$decimal}].");
        }

        [, $sign, $whole, $fraction] = array_pad($matches, 4, '');

        $cents = ((int) $whole * 100) + (int) str_pad($fraction, 2, '0');

        return $sign === '-' ? -$cents : $cents;
    }
}
