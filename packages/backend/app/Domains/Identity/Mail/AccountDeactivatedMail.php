<?php

namespace App\Domains\Identity\Mail;

use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;

class AccountDeactivatedMail extends Mailable
{
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Sua conta do FlowFi foi desativada',
        );
    }

    public function content(): Content
    {
        return new Content(
            markdown: 'mail.identity.account-deactivated',
        );
    }
}
