<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>OTP Code</title>
  </head>
  <body style="font-family: 'Inter', Arial, sans-serif; background: #F5F5F5; color: #1A1A1A; padding: 32px;">
    <div style="max-width: 620px; margin: 0 auto;">
      <div style="border-radius: 18px; overflow: hidden; border: 1px solid #E0E0E0; box-shadow: 0 20px 40px rgba(7, 80, 86, 0.12);">
        <div style="background: linear-gradient(135deg, #075056 0%, #092A17 100%); padding: 24px;">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse: collapse;">
            <tr>
              <td style="vertical-align: middle;">
                <div style="display: flex; align-items: center; gap: 14px;">
                  @if(!empty($logoUrl))
                    <img src="{{ $logoUrl }}" alt="{{ $appName }}" style="max-width: 120px; max-height: 48px; object-fit: contain; border-radius: 8px;">
                  @endif
                  <div>
                    <div style="font-size: 18px; font-weight: 700; color: #ffffff;">{{ $appName }}</div>
                    <div style="font-size: 12px; color: rgba(255,255,255,0.8);">Secure verification</div>
                  </div>
                </div>
              </td>
              <td style="text-align: right; color: rgba(255,255,255,0.9); font-size: 12px;">
                {{ $type === 'reset_password' ? 'Password Reset' : 'Email Verification' }}
              </td>
            </tr>
          </table>
        </div>
        <div style="background: #ffffff; padding: 28px;">
          <h2 style="margin: 0 0 10px; font-size: 22px; color: #1A1A1A;">Your One-Time Password</h2>
          <p style="margin: 0 0 16px; font-size: 14px; color: #666666;">
            Hello{{ $name ? ' ' . $name : '' }}, please use the OTP below to complete your
            {{ $type === 'reset_password' ? 'password reset' : 'email verification' }}.
          </p>
          <div style="display: inline-flex; align-items: center; gap: 10px; padding: 14px 18px; border-radius: 14px; background: #F5F5F5; border: 1px dashed #E0E0E0;">
            <span style="font-size: 12px; color: #999999; text-transform: uppercase; letter-spacing: 2px;">OTP</span>
            <span style="font-size: 26px; font-weight: 700; letter-spacing: 6px; color: #075056;">{{ $code }}</span>
          </div>
          <div style="margin-top: 18px; padding: 14px 16px; background: #F5F5F5; border-radius: 12px; border: 1px solid #E0E0E0;">
            <p style="margin: 0; font-size: 13px; color: #666666;">
              This code expires at {{ $expiresAt->format('h:i A') }}. If you didn't request it, ignore this email.
            </p>
          </div>
          <div style="margin-top: 18px; padding: 12px 16px; border-radius: 12px; border: 1px solid #E0E0E0; background: #ffffff;">
            <p style="margin: 0; font-size: 12px; color: #999999;">
              Tip: Keep this code private. Our team will never ask you for your OTP.
            </p>
          </div>
        </div>
      </div>
      <p style="margin: 16px 0 0; text-align: center; font-size: 12px; color: #999999;">
        © {{ date('Y') }} {{ $appName }} • All rights reserved
      </p>
    </div>
  </body>
</html>
