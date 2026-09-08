<?php

namespace App\Domains\Shared\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;

/**
 * Stores money as integer cents, exposes it as a two-decimal string.
 *
 * The API speaks decimals ("1500.50") because that is what people type and
 * read; the database stores cents so sums never drift. Conversion is string
 * arithmetic on purpose: `(int) ($value * 100)` turns 4.35 into 434.
 *
 * @implements CastsAttributes<string|null, int|null>
 */
class Money implements CastsAttributes
{
    /**
     * @param  array<string, mixed>  $attributes
     */
    public function get(Model $model, string $key, mixed $value, array $attributes): ?string
    {
        if ($value === null) {
            return null;
        }

        $cents = (int) $value;
        $magnitude = abs($cents);

        return sprintf('%s%d.%02d', $cents < 0 ? '-' : '', intdiv($magnitude, 100), $magnitude % 100);
    }

    /**
     * Accepts the shapes a validated request can hand over: a decimal string,
     * an int, or a float (JSON numbers arrive as floats).
     *
     * @param  array<string, mixed>  $attributes
     */
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
