<?php

namespace App\Domains\Notification\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Notification\Enums\DevicePlatform;
use App\Domains\Notification\Models\DeviceToken;

class EloquentDeviceTokenRepository implements DeviceTokenRepositoryInterface
{
    public function register(User $user, string $token, DevicePlatform $platform): DeviceToken
    {
        return DeviceToken::query()->updateOrCreate(
            ['token' => $token],
            ['user_id' => $user->id, 'platform' => $platform, 'last_used_at' => now()]
        );
    }

    public function deleteFor(User $user, string $token): void
    {
        $user->deviceTokens()->where('token', $token)->delete();
    }

    public function tokensFor(User $user): array
    {
        return $user->deviceTokens()->pluck('token')->all();
    }

    public function deleteByToken(string $token): void
    {
        DeviceToken::query()->where('token', $token)->delete();
    }
}
