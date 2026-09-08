<?php

namespace App\Domains\Shared\Services;

use App\Domains\Shared\Contracts\HasAppearance;
use App\Domains\Shared\Repositories\AppearanceRepositoryInterface;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Arr;

/**
 * Icon and color handling shared by every model a user can decorate (goals
 * now, categories later). Domain services call normalize() on create and
 * apply() on update so both paths store the same shape.
 */
class AppearanceService
{
    private const array KEYS = ['icon', 'color'];

    public function __construct(
        private readonly AppearanceRepositoryInterface $appearances,
    ) {}

    /**
     * Canonicalize appearance fields in a payload. Hex colors are uppercased
     * so the same color never exists in two spellings.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    public function normalize(array $data): array
    {
        if (isset($data['color']) && is_string($data['color'])) {
            $data['color'] = strtoupper($data['color']);
        }

        return $data;
    }

    /**
     * Persist whichever of icon/color the payload carries; a payload with
     * neither is a no-op.
     *
     * @param  array<string, mixed>  $data
     */
    public function apply(Model&HasAppearance $model, array $data): void
    {
        $attributes = Arr::only($this->normalize($data), self::KEYS);

        if ($attributes === []) {
            return;
        }

        $this->appearances->update($model, $attributes);
    }
}
