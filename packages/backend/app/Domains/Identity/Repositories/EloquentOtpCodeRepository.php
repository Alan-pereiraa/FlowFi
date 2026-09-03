<?php

namespace App\Domains\Identity\Repositories;

use App\Domains\Identity\Models\OtpCode;
use Carbon\CarbonInterface;

class EloquentOtpCodeRepository implements OtpCodeRepositoryInterface
{
    public function create(string $email, string $codeHash, CarbonInterface $expiresAt): OtpCode
    {
        return OtpCode::create([
            'email' => $email,
            'code_hash' => $codeHash,
            'expires_at' => $expiresAt,
        ]);
    }

    public function findLatestByEmail(string $email): ?OtpCode
    {
        return OtpCode::where('email', $email)
            ->lockForUpdate()
            ->latest('id')
            ->first();
    }

    public function incrementAttempts(OtpCode $code): OtpCode
    {
        $code->increment('attempts');

        return $code;
    }

    public function markConsumed(OtpCode $code): void
    {
        $code->forceFill(['consumed_at' => now()])->save();
    }
}
