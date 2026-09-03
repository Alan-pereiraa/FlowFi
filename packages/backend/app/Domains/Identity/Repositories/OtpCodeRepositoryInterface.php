<?php

namespace App\Domains\Identity\Repositories;

use App\Domains\Identity\Models\OtpCode;
use Carbon\CarbonInterface;

interface OtpCodeRepositoryInterface
{
    public function create(string $email, string $codeHash, CarbonInterface $expiresAt): OtpCode;

    /**
     * Latest row for the email regardless of its state. Locked for update so
     * concurrent verifications serialize on the attempts counter.
     */
    public function findLatestByEmail(string $email): ?OtpCode;

    public function incrementAttempts(OtpCode $code): OtpCode;

    public function markConsumed(OtpCode $code): void;
}
