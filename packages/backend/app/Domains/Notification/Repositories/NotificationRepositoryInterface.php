<?php

namespace App\Domains\Notification\Repositories;

use App\Domains\Notification\Models\Notification;
use Illuminate\Database\Eloquent\Collection;
use App\Domains\Identity\Models\User;

interface NotificationRepositoryInterface
{
    public function listFor(User $user): Collection;

    public function findFor(User $user, int $notificationId): ?Notification;

    public function markAsRead(Notification $notification): Notification;

    public function delete(Notification $notification): void;
}