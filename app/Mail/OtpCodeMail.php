<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Carbon;

class OtpCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $code,
        public string $type,
        public Carbon $expiresAt,
        public ?string $name = null,
        public ?string $logoUrl = null
    ) {}

    public function envelope(): Envelope
    {
        $title = $this->type === 'reset_password' ? 'Reset Password OTP' : 'Email Verification OTP';

        return new Envelope(
            subject: $title.' - '.config('app.name'),
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.otp',
            with: [
                'code' => $this->code,
                'type' => $this->type,
                'expiresAt' => $this->expiresAt,
                'name' => $this->name,
                'appName' => config('app.name'),
                'logoUrl' => $this->logoUrl,
            ],
        );
    }
}
