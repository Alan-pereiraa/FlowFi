<?php

namespace App\Domains\Notification\Repositories;

use App\Domains\Identity\Models\User;
use App\Domains\Notification\Models\Notification;
use Carbon\CarbonInterface;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class EloquentNotificationRepository implements NotificationRepositoryInterface
{
    public function listFor(User $user, int $perPage, ?string $status = null): LengthAwarePaginator
    {
        return $user->notifications()
            ->when($status === 'read', fn ($query) => $query->whereNotNull('read_at'))
            ->when($status === 'unread', fn ($query) => $query->whereNull('read_at'))
            ->orderBy('created_at', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($perPage);
    }

    public function findFor(User $user, int $notificationId): ?Notification
    {
        return $user->notifications()->find($notificationId);
    }

    public function create(User $user, array $attributes): Notification
    {
        return $user->notifications()->create($attributes);
    }

    public function exists(User $user, string $subject, ?int $subjectId, ?CarbonInterface $since = null): bool
    {
        return $user->notifications()
            ->withTrashed()
            ->where('subject', $subject)
            ->where('subject_id', $subjectId)
            ->when($since, fn ($query) => $query->where('created_at', '>=', $since))
            ->exists();
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
