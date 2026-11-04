<?php

namespace App\Domains\Notification\Contracts;

interface PushSender
{
    public function send(string $token, string $title, string $body, array $data = []): void;
}
