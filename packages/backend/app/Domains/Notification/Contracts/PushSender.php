<?php

namespace App\Domains\Notification\Contracts;

use App\Domains\Notification\Exceptions\InvalidDeviceToken;
use App\Domains\Notification\Exceptions\PushRejected;

interface PushSender
{
    /**
     * @param  array<string, string>  $data
     *
     * @throws InvalidDeviceToken
     * @throws PushRejected
     */
    public function send(string $token, string $title, string $body, array $data = []): void;
}
