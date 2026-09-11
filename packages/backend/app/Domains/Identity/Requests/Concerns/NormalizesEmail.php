<?php

namespace App\Domains\Identity\Requests\Concerns;

trait NormalizesEmail
{
    protected function prepareForValidation(): void
    {
        $this->merge([
            'email' => strtolower(trim((string) $this->input('email'))),
        ]);
    }
}
