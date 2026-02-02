<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\CandidateProfile;
use App\Models\Job;
use App\Models\Notification;
use App\Models\Setting;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use App\Services\ActivityLogger;

class CandidateController extends Controller
{
    public function profile(Request $request): JsonResponse
    {
        $user = $this->requireCandidate($request);

        return response()->json($user->load('candidateProfile'));
    }

    public function uploadProfileImage(Request $request): JsonResponse
    {
        $user = $this->requireCandidate($request);

        $validated = $request->validate([
            'image' => ['required', 'file', 'mimes:jpg,jpeg,png', 'max:5120'],
        ]);

        $path = $validated['image']->store('candidates', 'public');
        $url = Storage::disk('public')->url($path);

        $user->candidateProfile()->updateOrCreate(
            ['user_id' => $user->id],
            ['profile_image_path' => $url]
        );

        ActivityLogger::log($user, 'candidate.upload_profile_image');

        return response()->json(['url' => $url]);
    }

    public function uploadCv(Request $request): JsonResponse
    {
        $user = $this->requireCandidate($request);

        $validated = $request->validate([
            'cv' => ['required', 'file', 'mimes:pdf,doc,docx', 'max:10240'],
        ]);

        $path = $validated['cv']->store('cvs', 'public');
        $url = Storage::disk('public')->url($path);

        $user->candidateProfile()->updateOrCreate(
            ['user_id' => $user->id],
            ['cv_path' => $url]
        );

        ActivityLogger::log($user, 'candidate.upload_cv');

        return response()->json(['url' => $url]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $this->requireCandidate($request);
        $profile = $user->candidateProfile;

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'major_ids' => ['nullable', 'array'],
            'major_ids.*' => ['exists:lookups,id'],
            'years_of_experience_id' => ['nullable', 'exists:lookups,id'],
            'skills' => ['nullable', 'array'],
            'education_id' => ['nullable', 'exists:lookups,id'],
            'mobile_number' => ['nullable', 'regex:/^\+\d{6,15}$/'],
            'date_of_birth' => ['nullable', 'date', 'before:today'],
            'availability' => ['nullable', 'string', 'max:255'],
            'cv_path' => ['nullable', 'string', 'max:255'],
            'summary' => ['nullable', 'string'],
            'profession_title' => ['nullable', 'string', 'max:255'],
            'address' => ['nullable', 'string'],
            'upwork_profile_url' => ['nullable', 'url', 'max:500'],
            'public_slug' => [
                'nullable',
                'string',
                'max:255',
                'unique:candidate_profiles,public_slug'.($profile ? ','.$profile->id : ''),
            ],
            'profile_image_path' => ['nullable', 'string', 'max:255'],
            'nationality_country_id' => ['nullable', 'exists:countries,id'],
            'resident_country_id' => ['nullable', 'exists:countries,id'],
        ], [
            'mobile_number.regex' => 'Mobile number must include country code, e.g. +96550123456.',
            'upwork_profile_url.url' => 'The upwork profile URL must be a valid URL.',
        ]);

        if (isset($validated['name'])) {
            $user->update(['name' => $validated['name']]);
        }

        $profileData = collect($validated)->except('name')->toArray();
        if (!empty($profileData)) {
            CandidateProfile::updateOrCreate(
                ['user_id' => $user->id],
                $profileData
            );
        }

        return response()->json($user->load('candidateProfile'));
    }

    public function activate(Request $request): JsonResponse
    {
        $user = $this->requireCandidate($request);
        $profile = $user->candidateProfile;

        if (!$profile) {
            $profile = CandidateProfile::create(['user_id' => $user->id]);
        }

        if ($profile->is_activated) {
            return response()->json(['message' => 'Profile already activated.']);
        }

        $fee = $this->getSettingAmount('candidate_activation_fee', 1.0);

        $transaction = Transaction::create([
            'user_id' => $user->id,
            'type' => 'candidate_activation',
            'amount' => $fee,
            'currency' => $request->string('currency', 'KWD'),
            'method' => $request->string('method', 'manual'),
            'status' => 'completed',
            'reference' => (string) Str::uuid(),
        ]);

        $profile->update([
            'is_activated' => true,
            'activated_at' => now(),
        ]);

        ActivityLogger::log($user, 'candidate.activate_profile', ['transaction_id' => $transaction->id]);

        return response()->json([
            'profile' => $profile->fresh(),
            'transaction' => $transaction,
        ]);
    }

    public function applications(Request $request): JsonResponse
    {
        $user = $this->requireCandidate($request);

        $applications = Application::query()
            ->where('candidate_id', $user->id)
            ->with(['job.company.companyProfile'])
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 20));

        return response()->json($applications);
    }

    public function apply(Request $request, Job $job): JsonResponse
    {
        $user = $this->requireCandidate($request);
        $profile = $user->candidateProfile;

        if (!$profile || !$profile->is_activated) {
            return response()->json(['message' => 'Profile activation required.'], 403);
        }

        if (!$job->is_active) {
            return response()->json(['message' => 'Job not found.'], 404);
        }

        $validated = $request->validate([
            'cover_letter' => ['nullable', 'string'],
        ]);

        $existing = Application::where('job_id', $job->id)
            ->where('candidate_id', $user->id)
            ->first();

        if ($existing) {
            return response()->json(['message' => 'Already applied.'], 409);
        }

        $application = Application::create([
            'job_id' => $job->id,
            'candidate_id' => $user->id,
            'status' => 'submitted',
            'cover_letter' => $validated['cover_letter'] ?? null,
            'is_paid' => true,
            'applied_at' => now(),
        ]);

        ActivityLogger::log($user, 'candidate.apply_job', ['job_id' => $job->id]);

        // Send notification to company
        $company = $job->company;
        if ($company) {
            Notification::jobApplied($company, [
                'application_id' => $application->id,
                'job_id' => $job->id,
                'job_title' => $job->title,
                'candidate_id' => $user->id,
                'candidate_name' => $user->name,
            ]);
        }

        return response()->json($application->load(['job.company.companyProfile']), 201);
    }

    public function changePassword(Request $request): JsonResponse
    {
        $user = $this->requireCandidate($request);

        $validated = $request->validate([
            'old_password' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        if (!\Illuminate\Support\Facades\Hash::check($validated['old_password'], $user->password)) {
            return response()->json(['message' => 'Current password is incorrect.'], 422);
        }

        $user->update(['password' => $validated['password']]);

        ActivityLogger::log($user, 'candidate.change_password');

        return response()->json(['message' => 'Password updated successfully.']);
    }

    private function requireCandidate(Request $request): User
    {
        $user = $request->user();
        abort_if(!$user || $user->role !== User::ROLE_CANDIDATE, 403, 'Unauthorized.');

        return $user;
    }

    private function getSettingAmount(string $key, float $default): float
    {
        $value = Setting::where('key', $key)->value('value');
        if (is_numeric($value)) {
            return (float) $value;
        }

        return $default;
    }
}
