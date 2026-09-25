<?php

namespace App\Domains\Notification\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Notification\Enums\DevicePlatform;
use App\Domains\Notification\Models\DeviceToken;

interface DeviceTokenRepositoryInterface
{
    public function register(User $user, string $token, DevicePlatform $platform): DeviceToken;

    public function deleteFor(User $user, string $token): void;

    public function tokensFor(User $user): array;

    public function deleteByToken(string $token): void;
}
