<?php

namespace App\Domains\Identity\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use Illuminate\Validation\ValidationException;

class AuthService
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly OtpService $otp,
    ) {}

    /**
     * Issue a one-time code to the email. Behaves identically whether or not
     * an account exists, so the endpoint cannot be used to enumerate users.
     */
    public function requestOtp(string $email): void
    {
        $this->otp->issue($email);
    }

    /**
     * Burn the code, then sign in the matching user or create one. The code
     * is consumed (and committed) before the account check on purpose: a
     * deactivated account is only revealed to someone who proved they own
     * the mailbox.
     *
     * @return array{user: User, token: string}
     *
     * @throws ValidationException
     */
    public function verifyOtp(string $email, string $code): array
    {
        $this->otp->consume($email, $code);

        $user = $this->users->findByEmailWithTrashed($email);

        if ($user?->trashed()) {
            throw ValidationException::withMessages([
                'email' => ['This account has been deactivated.'],
            ]);
        }

        if (! $user) {
            $user = $this->users->create([
                'email' => $email,
                'email_verified_at' => now(),
            ]);
        } elseif ($user->email_verified_at === null) {
            $this->users->update($user, ['email_verified_at' => now()]);
        }

        return [
            'user' => $user,
            'token' => $user->createToken('api')->plainTextToken,
        ];
    }

    public function logout(User $user): void
    {
        $user->currentAccessToken()?->delete();
    }
}
