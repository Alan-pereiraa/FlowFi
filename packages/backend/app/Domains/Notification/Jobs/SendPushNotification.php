<?php

namespace App\Domains\Notification\Jobs;

use App\Domains\Notification\Contracts\PushSender;
use App\Domains\Notification\Exceptions\InvalidDeviceToken;
use App\Domains\Notification\Exceptions\PushRejected;
use App\Domains\Notification\Models\Notification;
use App\Domains\Notification\Service\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class SendPushNotification implements ShouldQueue
{
    use Queueable;

    public int $tries = 5;

    public array $backoff = [10, 60, 300, 900];

    public bool $deleteWhenMissingModels = true;

    public function __construct(
        public readonly Notification $notification,
        public readonly string $token
    ) {}

    public function handle(PushSender $push, NotificationService $notifications): void
    {
        try {
            $push->send($this->token, $this->notification->title, $this->notification->message, [
                'notification_id' => (string) $this->notification->id,
                'subject' => $this->notification->subject,
                'subject_id' => (string) $this->notification->subject_id,
            ]);
        } catch (InvalidDeviceToken) {
            $notifications->forgetDevice($this->token);
        } catch (PushRejected $e) {
            $this->fail($e);
        }
    }
}
