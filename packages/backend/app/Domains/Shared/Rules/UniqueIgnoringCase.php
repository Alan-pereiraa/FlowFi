<?php

namespace App\Domains\Shared\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Relations\Relation;

class UniqueIgnoringCase implements ValidationRule
{
    public function __construct(
        private readonly Builder|Relation $query,
        private readonly string $column,
        private readonly string $message,
        private readonly ?int $ignoreId = null,
    ) {}

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (! is_string($value)) {
            return;
        }

        $wanted = $this->normalize($value);

        $taken = $this->query
            ->when($this->ignoreId !== null, fn ($query) => $query->whereKeyNot($this->ignoreId))
            ->pluck($this->column)
            ->contains(fn ($existing) => $this->normalize((string) $existing) === $wanted);

        if ($taken) {
            $fail($this->message);
        }
    }

    private function normalize(string $value): string
    {
        return mb_strtolower(trim($value));
    }
}
