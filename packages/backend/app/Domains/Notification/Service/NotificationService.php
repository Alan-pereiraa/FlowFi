<?php

namespace App\Domains\Notification\Service;

use App\Domains\Identity\Models\User;
use App\Domains\Notification\Models\Notification;
use App\Domains\Notification\Repositories\NotificationRepositoryInterface;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class NotificationService
{
    public function __construct(
        private readonly NotificationRepositoryInterface $notifications
    ) {}

    public function list(User $user): Collection
    {
        return $this->notifications->listFor($user);
    }

    public function findOwned(User $user, int $id): Notification
    {
        return $this->notifications->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function markAsRead(Notification $notification): Notification
    {
        return $this->notifications->markAsRead($notification);
    }

    public function delete(Notification $notification): void
    {
        $this->notifications->delete($notification);
    }
}