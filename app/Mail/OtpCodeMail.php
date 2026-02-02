<?php

namespace App\Mail;

use App\Models\Setting;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Carbon;

class OtpCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    private string $appName;

    public function __construct(
        public string $code,
        public string $type,
        public Carbon $expiresAt,
        public ?string $name = null,
        public ?string $logoUrl = null
    ) {
        // Get app name from settings, fallback to config
        $this->appName = Setting::where('key', 'app_name')->value('value') ?? config('app.name');
    }

    public function envelope(): Envelope
    {
        $title = $this->type === 'reset_password' ? 'Reset Password OTP' : 'Email Verification OTP';

        return new Envelope(
            subject: $title.' - '.$this->appName,
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
                'appName' => $this->appName,
                'logoUrl' => $this->logoUrl,
            ],
        );
    }
}
