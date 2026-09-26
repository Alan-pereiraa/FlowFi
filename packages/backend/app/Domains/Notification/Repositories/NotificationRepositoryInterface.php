<?php

namespace App\Domains\Notification\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Notification\Models\Notification;
use Carbon\CarbonInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

interface NotificationRepositoryInterface
{
    public function listFor(User $user, int $perPage, ?string $status = null): LengthAwarePaginator;

    public function findFor(User $user, int $notificationId): ?Notification;

    public function create(User $user, array $attributes): Notification;

    public function exists(User $user, string $subject, ?int $subjectId, ?CarbonInterface $since = null): bool;

    public function markAsRead(Notification $notification): Notification;

    public function delete(Notification $notification): void;
}
