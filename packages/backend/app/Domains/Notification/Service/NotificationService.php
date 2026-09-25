<?php

namespace App\Domains\Notification\Service;

use App\Domains\Identity\Models\User;
use App\Domains\Notification\Enums\NotificationType;
use App\Domains\Notification\Models\Notification;
use App\Domains\Notification\Repositories\NotificationRepositoryInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class NotificationService
{
    public function __construct(
        private readonly NotificationRepositoryInterface $notifications
    ) {}

    public function list(User $user, int $perPage, ?string $status = null): LengthAwarePaginator
    {
        return $this->notifications->listFor($user, $perPage, $status);
    }

    public function findOwned(User $user, int $id): Notification
    {
        return $this->notifications->findFor($user, $id)
            ?? throw new ModelNotFoundException('Not found.');
    }

    public function notify(
        User $user,
        string $title,
        string $message,
        NotificationType $type,
        string $subject
    ): Notification {
        return $this->notifications->create($user, [
            'title' => $title,
            'message' => $message,
            'type' => $type,
            'subject' => $subject,
        ]);
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
