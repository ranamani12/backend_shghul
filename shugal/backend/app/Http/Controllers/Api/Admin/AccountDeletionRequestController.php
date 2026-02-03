<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AccountDeletionRequest;
use App\Models\CandidateProfile;
use App\Models\CompanyProfile;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;

class AccountDeletionRequestController extends Controller
{
    public function index(Request $request)
    {
        $query = AccountDeletionRequest::query()
            ->orderBy('created_at', 'desc');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('email', 'like', "%{$search}%")
                    ->orWhere('phone', 'like', "%{$search}%")
                    ->orWhere('reference', 'like', "%{$search}%");
            });
        }

        $requests = $query->paginate($request->get('per_page', 20));

        return response()->json($requests);
    }

    public function show(AccountDeletionRequest $accountDeletionRequest)
    {
        // Try to find the user
        $user = User::where('email', $accountDeletionRequest->email)->first();

        return response()->json([
            'request' => $accountDeletionRequest,
            'user' => $user ? [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'created_at' => $user->created_at,
            ] : null,
        ]);
    }

    public function process(Request $request, AccountDeletionRequest $accountDeletionRequest)
    {
        $validated = $request->validate([
            'action' => 'required|in:approve,reject',
            'reason' => 'nullable|string|max:500',
        ]);

        if ($validated['action'] === 'approve') {
            return $this->approveRequest($accountDeletionRequest, $request->user());
        } else {
            return $this->rejectRequest($accountDeletionRequest, $request->user(), $validated['reason'] ?? null);
        }
    }

    private function approveRequest(AccountDeletionRequest $deletionRequest, User $admin)
    {
        DB::beginTransaction();

        try {
            // Find the user by email
            $user = User::where('email', $deletionRequest->email)->first();

            if ($user) {
                // Delete related data based on account type
                if ($deletionRequest->account_type === 'job_seeker') {
                    // Delete candidate profile and related data
                    CandidateProfile::where('user_id', $user->id)->delete();
                } else {
                    // Delete company profile and related data
                    CompanyProfile::where('user_id', $user->id)->delete();
                }

                // Delete the user
                $user->delete();
            }

            // Update deletion request
            $deletionRequest->update([
                'status' => 'completed',
                'processed_at' => now(),
                'processed_by' => $admin->id,
            ]);

            DB::commit();

            // Send confirmation email
            $this->sendCompletionEmail($deletionRequest);

            return response()->json([
                'success' => true,
                'message' => 'Account deletion request approved and processed',
            ]);
        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'success' => false,
                'message' => 'Failed to process deletion: ' . $e->getMessage(),
            ], 500);
        }
    }

    private function rejectRequest(AccountDeletionRequest $deletionRequest, User $admin, ?string $reason)
    {
        $deletionRequest->update([
            'status' => 'rejected',
            'processed_at' => now(),
            'processed_by' => $admin->id,
            'comments' => $deletionRequest->comments . "\n\n[Rejection Reason]: " . ($reason ?? 'No reason provided'),
        ]);

        // Send rejection email
        $this->sendRejectionEmail($deletionRequest, $reason);

        return response()->json([
            'success' => true,
            'message' => 'Account deletion request rejected',
        ]);
    }

    private function sendCompletionEmail(AccountDeletionRequest $request)
    {
        $appName = Setting::where('key', 'app_name')->value('value') ?? config('app.name');

        try {
            Mail::raw(
                "Dear User,\n\n" .
                "Your account deletion request has been processed.\n\n" .
                "Reference Number: {$request->reference}\n\n" .
                "Your account and all associated data have been permanently deleted from our systems.\n\n" .
                "Thank you for using {$appName}.\n\n" .
                "Best regards,\n" .
                "The {$appName} Team",
                function ($message) use ($request, $appName) {
                    $message->to($request->email)
                        ->subject("Account Deleted - {$appName}");
                }
            );
        } catch (\Exception $e) {
            \Log::error('Failed to send deletion completion email: ' . $e->getMessage());
        }
    }

    private function sendRejectionEmail(AccountDeletionRequest $request, ?string $reason)
    {
        $appName = Setting::where('key', 'app_name')->value('value') ?? config('app.name');

        try {
            Mail::raw(
                "Dear User,\n\n" .
                "Your account deletion request could not be processed.\n\n" .
                "Reference Number: {$request->reference}\n\n" .
                "Reason: " . ($reason ?? 'Please contact support for more information.') . "\n\n" .
                "If you have any questions, please contact us at support@shghul.com\n\n" .
                "Best regards,\n" .
                "The {$appName} Team",
                function ($message) use ($request, $appName) {
                    $message->to($request->email)
                        ->subject("Account Deletion Request Update - {$appName}");
                }
            );
        } catch (\Exception $e) {
            \Log::error('Failed to send rejection email: ' . $e->getMessage());
        }
    }
}
