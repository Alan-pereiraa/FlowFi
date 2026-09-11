<?php

namespace App\Domains\Identity\Services;

use App\Domains\Identity\Mail\OtpCodeMail;
use App\Domains\Identity\Repositories\OtpCodeRepositoryInterface;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class OtpService
{
    private const string INVALID = 'The code is invalid or has expired.';

    private const string TOO_MANY_ATTEMPTS = 'Too many attempts. Request a new code.';

    public function __construct(
        private readonly OtpCodeRepositoryInterface $codes,
    ) {}

    public function issue(string $email): void
    {
        $code = $this->generateCode();
        $expiresInMinutes = (int) config('auth.otp.expire');

        $this->codes->create($email, Hash::make($code), now()->addMinutes($expiresInMinutes));

        Mail::to($email)->send(new OtpCodeMail($code, $expiresInMinutes));
    }

    public function consume(string $email, string $code): void
    {
        $failure = DB::transaction(function () use ($email, $code): ?string {
            $record = $this->codes->findLatestByEmail($email);

            if (! $record || $record->isConsumed() || $record->isExpired()) {
                return self::INVALID;
            }

            if ($record->attempts >= (int) config('auth.otp.max_attempts')) {
                return self::TOO_MANY_ATTEMPTS;
            }

            $this->codes->incrementAttempts($record);

            if (! Hash::check($code, $record->code_hash)) {
                return self::INVALID;
            }

            $this->codes->markConsumed($record);

            return null;
        });

        if ($failure !== null) {
            throw ValidationException::withMessages(['code' => [$failure]]);
        }
    }

    private function generateCode(): string
    {
        $length = (int) config('auth.otp.length');

        return str_pad((string) random_int(0, (10 ** $length) - 1), $length, '0', STR_PAD_LEFT);
    }
}
