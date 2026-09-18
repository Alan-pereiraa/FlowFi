<?php

namespace App\Domains\Notification\Repositories;

use App\Domains\Notification\Models\Notification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use App\Domains\Identity\Models\User;

interface NotificationRepositoryInterface
{
    public function listFor(User $user, int $perPage, ?string $status = null): LengthAwarePaginator;

    public function findFor(User $user, int $notificationId): ?Notification;

    public function markAsRead(Notification $notification): Notification;

    public function delete(Notification $notification): void;
}