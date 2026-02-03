<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AccountDeletionRequest;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AccountDeletionController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email',
            'phone' => 'nullable|string|max:20',
            'accountType' => 'required|in:job_seeker,employer',
            'reason' => 'nullable|string|max:100',
            'comments' => 'nullable|string|max:1000',
        ]);

        // Generate unique reference
        $reference = 'DEL-' . strtoupper(Str::random(8)) . '-' . time();

        $deletionRequest = AccountDeletionRequest::create([
            'email' => $validated['email'],
            'phone' => $validated['phone'] ?? null,
            'account_type' => $validated['accountType'],
            'reason' => $validated['reason'] ?? null,
            'comments' => $validated['comments'] ?? null,
            'reference' => $reference,
            'status' => 'pending',
        ]);

        // Send notification email to admin
        $this->notifyAdmin($deletionRequest);

        // Send confirmation email to user
        $this->sendUserConfirmation($deletionRequest);

        return response()->json([
            'success' => true,
            'message' => 'Account deletion request submitted successfully',
            'reference' => $reference,
        ], 201);
    }

    private function notifyAdmin(AccountDeletionRequest $request)
    {
        $appName = Setting::where('key', 'app_name')->value('value') ?? config('app.name');

        try {
            Mail::raw(
                "New Account Deletion Request\n\n" .
                "Reference: {$request->reference}\n" .
                "Email: {$request->email}\n" .
                "Phone: " . ($request->phone ?: 'Not provided') . "\n" .
                "Account Type: {$request->account_type}\n" .
                "Reason: " . ($request->reason ?: 'Not specified') . "\n" .
                "Comments: " . ($request->comments ?: 'None') . "\n" .
                "Submitted: {$request->created_at}\n\n" .
                "Please process this request within 7 business days.",
                function ($message) use ($appName) {
                    $message->to(config('mail.from.address'))
                        ->subject("Account Deletion Request - {$appName}");
                }
            );
        } catch (\Exception $e) {
            // Log error but don't fail the request
            \Log::error('Failed to send admin notification: ' . $e->getMessage());
        }
    }

    private function sendUserConfirmation(AccountDeletionRequest $request)
    {
        $appName = Setting::where('key', 'app_name')->value('value') ?? config('app.name');

        try {
            Mail::raw(
                "Dear User,\n\n" .
                "We have received your account deletion request.\n\n" .
                "Reference Number: {$request->reference}\n\n" .
                "Your request will be processed within 7 business days. " .
                "You will receive a confirmation email once your account has been deleted.\n\n" .
                "If you did not make this request, please contact us immediately at support@shghul.com\n\n" .
                "Thank you,\n" .
                "The {$appName} Team",
                function ($message) use ($request, $appName) {
                    $message->to($request->email)
                        ->subject("Account Deletion Request Received - {$appName}");
                }
            );
        } catch (\Exception $e) {
            // Log error but don't fail the request
            \Log::error('Failed to send user confirmation: ' . $e->getMessage());
        }
    }
}
