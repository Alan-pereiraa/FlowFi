<?php

namespace App\Domains\Shared\Services;

use App\Domains\Shared\Contracts\HasAppearance;
use App\Domains\Shared\Repositories\AppearanceRepositoryInterface;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Arr;

class AppearanceService
{
    private const array KEYS = ['icon', 'color'];

    public function __construct(
        private readonly AppearanceRepositoryInterface $appearances,
    ) {}

    public function normalize(array $data): array
    {
        if (isset($data['color']) && is_string($data['color'])) {
            $data['color'] = strtoupper($data['color']);
        }

        return $data;
    }

    public function apply(Model&HasAppearance $model, array $data): void
    {
        $attributes = Arr::only($this->normalize($data), self::KEYS);

        if ($attributes === []) {
            return;
        }

        $this->appearances->update($model, $attributes);
    }
}
