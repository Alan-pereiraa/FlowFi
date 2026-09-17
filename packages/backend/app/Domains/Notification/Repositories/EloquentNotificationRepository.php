<?php

namespace App\Domains\Notification\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Notification\Models\Notification;
use Illuminate\Database\Eloquent\Collection;

class EloquentNotificationRepository implements NotificationRepositoryInterface
{
    public function listFor(User $user): Collection
    {
        return $user->notifications()->orderBy('created_at')->orderBy('id')->get();
    }

    public function findFor(User $user, int $notificationId): ?Notification
    {
        return $user->notifications()->find($notificationId);
    }

    public function markAsRead(Notification $notification): Notification
    {
        $notification->read_at = now();
        $notification->save();

        return $notification;
    }

    public function delete(Notification $notification): void
    {
        $notification->delete();
    }
}