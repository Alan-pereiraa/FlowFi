<?php

namespace App\Domains\Notification\Service;

use App\Domains\Notification\Contracts\PushSender;
use App\Domains\Notification\Exceptions\InvalidDeviceToken;
use App\Domains\Notification\Exceptions\PushRejected;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Exception\Messaging\InvalidMessage;
use Kreait\Firebase\Exception\Messaging\NotFound;
use Kreait\Firebase\Exception\Messaging\SenderIdMismatch;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification as FcmNotification;

class FcmPushSender implements PushSender
{
    public function __construct(
        private readonly Messaging $messaging
    ) {}

    public function send(string $token, string $title, string $body, array $data = []): void
    {
        $message = CloudMessage::new()
            ->toToken($token)
            ->withNotification(FcmNotification::create($title, $body))
            ->withData($data);

        try {
            $this->messaging->send($message);
        } catch (NotFound|SenderIdMismatch $e) {
            throw new InvalidDeviceToken($e->getMessage(), previous: $e);
        } catch (InvalidMessage $e) {
            throw new PushRejected($e->getMessage(), previous: $e);
        }
    }
}
