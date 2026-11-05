<?php

namespace App\Domains\Shared\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Database\Eloquent\Model;
use InvalidArgumentException;

class Money implements CastsAttributes
{
    public function get(Model $model, string $key, mixed $value, array $attributes): ?string
    {
        return $value === null ? null : self::toDecimal((int) $value);
    }

    public function set(Model $model, string $key, mixed $value, array $attributes): ?int
    {
        return $value === null ? null : self::toCents($value, $key);
    }

    public static function toDecimal(int $cents): string
    {
        $magnitude = abs($cents);

        return sprintf('%s%d.%02d', $cents < 0 ? '-' : '', intdiv($magnitude, 100), $magnitude % 100);
    }

    public static function toBrl(int $cents): string
    {
        $magnitude = abs($cents);

        return sprintf(
            '%sR$ %s,%02d',
            $cents < 0 ? '-' : '',
            number_format(intdiv($magnitude, 100), 0, ',', '.'),
            $magnitude % 100,
        );
    }

    public static function toCents(mixed $value, string $key = 'value'): int
    {
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
