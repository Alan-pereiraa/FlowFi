<?php

namespace App\Domains\Identity\Requests\Concerns;

/**
 * SQLite compares emails case-sensitively (and so does the users.email unique
 * index), so normalize before validating to keep one mailbox = one user.
 */
trait NormalizesEmail
{
    protected function prepareForValidation(): void
    {
        $this->merge([
            'email' => strtolower(trim((string) $this->input('email'))),
        ]);
    }
}
