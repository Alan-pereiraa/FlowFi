<?php

namespace App\Domains\Identity\Mail;

use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class OtpCodeMail extends Mailable
{
    public function __construct(
        public readonly string $code,
        public readonly int $expiresInMinutes,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Your FlowFi sign-in code',
        );
    }

    public function content(): Content
    {
        return new Content(
            markdown: 'mail.identity.otp-code',
        );
    }
}
