<?php

namespace App\Domains\Identity\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use App\Domains\Notification\Service\NotificationService;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class AuthService
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
        private readonly OtpService $otp,
        private readonly NotificationService $notifications,
    ) {}

    public function requestOtp(string $email): void
    {
        $this->otp->issue($email);
    }

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

    public function logout(User $user, ?string $deviceToken = null): void
    {
        if ($deviceToken !== null) {
            $this->notifications->unregisterDevice($user, $deviceToken);
        }

        $token = $user->currentAccessToken();

        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }
    }
}
