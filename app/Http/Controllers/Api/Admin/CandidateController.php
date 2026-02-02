<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\CandidateProfile;
use App\Models\CandidateUnlock;
use App\Models\Application;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CandidateController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = User::query()
            ->where('role', User::ROLE_CANDIDATE)
            ->with('candidateProfile');

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('q')) {
            $search = $request->string('q');
            $query->where(function ($builder) use ($search) {
                $builder->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('unique_code', 'like', "%{$search}%");
            });
        }

        return response()->json($query->paginate($request->integer('per_page', 15)));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'status' => ['sometimes', 'in:'.User::STATUS_ACTIVE.','.User::STATUS_SUSPENDED],
            'profile_image' => ['nullable', 'image', 'max:2048'],
            'cv_file' => ['nullable', 'file', 'mimes:pdf,doc,docx', 'max:5120'],
            'skills' => ['nullable', 'string'],
            'profile' => ['sometimes', 'array'],
            'profile.nationality_country_id' => ['nullable', 'exists:countries,id'],
            'profile.resident_country_id' => ['nullable', 'exists:countries,id'],
            'profile.mobile_number' => ['nullable', 'regex:/^\+\d{6,15}$/'],
            'profile.major_ids' => ['nullable', 'array'],
            'profile.major_ids.*' => ['exists:lookups,id'],
            'profile.years_of_experience_id' => ['nullable', 'exists:lookups,id'],
            'profile.education_id' => ['nullable', 'exists:lookups,id'],
            'profile.availability' => ['nullable', 'string', 'in:,immediate,1_week,2_weeks,1_month,negotiable'],
            'profile.summary' => ['nullable', 'string', 'max:2000'],
            'profile.public_slug' => ['nullable', 'string', 'max:100', 'regex:/^[a-z0-9-]*$/'],
            'profile.upwork_profile_url' => ['nullable', 'url', 'max:500'],
        ], [
            'profile.mobile_number.regex' => 'Mobile number must include country code, e.g. +96550123456.',
            'profile.public_slug.regex' => 'Public slug can only contain lowercase letters, numbers, and hyphens.',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => $validated['password'],
            'role' => User::ROLE_CANDIDATE,
            'status' => $validated['status'] ?? User::STATUS_ACTIVE,
            'unique_code' => $this->generateUniqueCode(User::ROLE_CANDIDATE),
        ]);

        $profileData = $validated['profile'] ?? [];
        $profileData['user_id'] = $user->id;

        // Handle profile image upload
        if ($request->hasFile('profile_image')) {
            $path = $request->file('profile_image')->store('candidates/profile-images', 'public');
            $profileData['profile_image_path'] = '/storage/' . $path;
        }

        // Handle CV upload
        if ($request->hasFile('cv_file')) {
            $path = $request->file('cv_file')->store('candidates/cvs', 'public');
            $profileData['cv_path'] = '/storage/' . $path;
        }

        // Handle skills (comma-separated string to array)
        if (!empty($validated['skills'])) {
            $profileData['skills'] = array_map('trim', explode(',', $validated['skills']));
        }

        CandidateProfile::create($profileData);

        return response()->json($user->load('candidateProfile'), 201);
    }

    public function show(User $candidate): JsonResponse
    {
        if ($candidate->role !== User::ROLE_CANDIDATE) {
            return response()->json(['message' => 'Candidate not found.'], 404);
        }

        $candidate->load([
            'candidateProfile.nationalityCountry.translations',
            'candidateProfile.residentCountry.translations',
            'candidateProfile.yearsOfExperience.translations',
            'candidateProfile.educationLevel.translations',
        ]);

        // Load major lookups if major_ids exist
        $majorIds = $candidate->candidateProfile?->major_ids ?? [];
        $majorLookups = [];
        if (!empty($majorIds)) {
            $majorLookups = \App\Models\Lookup::query()
                ->whereIn('id', $majorIds)
                ->with('translations')
                ->get()
                ->toArray();
        }

        $applications = Application::query()
            ->where('candidate_id', $candidate->id)
            ->with(['job.company.companyProfile'])
            ->orderByDesc('created_at')
            ->get();

        $unlocks = CandidateUnlock::query()
            ->where('candidate_id', $candidate->id)
            ->with(['company.companyProfile', 'transaction'])
            ->orderByDesc('created_at')
            ->get();

        $transactions = Transaction::query()
            ->where('user_id', $candidate->id)
            ->orderByDesc('created_at')
            ->get();

        $candidateData = $candidate->toArray();
        if (isset($candidateData['candidate_profile'])) {
            $candidateData['candidate_profile']['major_lookups'] = $majorLookups;
        }

        return response()->json([
            'candidate' => $candidateData,
            'applications' => $applications,
            'unlocks' => $unlocks,
            'transactions' => $transactions,
        ]);
    }

    public function update(Request $request, User $candidate): JsonResponse
    {
        if ($candidate->role !== User::ROLE_CANDIDATE) {
            return response()->json(['message' => 'Candidate not found.'], 404);
        }

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'max:255', 'unique:users,email,'.$candidate->id],
            'status' => ['sometimes', 'in:'.User::STATUS_ACTIVE.','.User::STATUS_SUSPENDED],
            'profile_image' => ['nullable', 'image', 'max:2048'],
            'cv_file' => ['nullable', 'file', 'mimes:pdf,doc,docx', 'max:5120'],
            'skills' => ['nullable', 'string'],
            'profile' => ['sometimes', 'array'],
            'profile.nationality_country_id' => ['nullable', 'exists:countries,id'],
            'profile.resident_country_id' => ['nullable', 'exists:countries,id'],
            'profile.mobile_number' => ['nullable', 'regex:/^\+\d{6,15}$/'],
            'profile.major_ids' => ['nullable', 'array'],
            'profile.major_ids.*' => ['exists:lookups,id'],
            'profile.years_of_experience_id' => ['nullable', 'exists:lookups,id'],
            'profile.education_id' => ['nullable', 'exists:lookups,id'],
            'profile.availability' => ['nullable', 'string'],
            'profile.summary' => ['nullable', 'string', 'max:2000'],
            'profile.public_slug' => ['nullable', 'string', 'max:100'],
            'profile.upwork_profile_url' => ['nullable', 'string', 'max:500'],
        ], [
            'profile.mobile_number.regex' => 'Mobile number must include country code, e.g. +96550123456.',
        ]);

        $candidate->update(Arr::except($validated, ['profile', 'profile_image', 'cv_file', 'skills']));

        $profileData = $validated['profile'] ?? [];

        // Handle profile image upload
        if ($request->hasFile('profile_image')) {
            // Delete old image if exists
            if ($candidate->candidateProfile?->profile_image_path) {
                $oldPath = str_replace('/storage/', '', $candidate->candidateProfile->profile_image_path);
                Storage::disk('public')->delete($oldPath);
            }
            $path = $request->file('profile_image')->store('candidates/profile-images', 'public');
            $profileData['profile_image_path'] = '/storage/' . $path;
        }

        // Handle CV upload
        if ($request->hasFile('cv_file')) {
            // Delete old CV if exists
            if ($candidate->candidateProfile?->cv_path) {
                $oldPath = str_replace('/storage/', '', $candidate->candidateProfile->cv_path);
                Storage::disk('public')->delete($oldPath);
            }
            $path = $request->file('cv_file')->store('candidates/cvs', 'public');
            $profileData['cv_path'] = '/storage/' . $path;
        }

        // Handle skills (comma-separated string to array)
        if (isset($validated['skills'])) {
            $profileData['skills'] = !empty($validated['skills'])
                ? array_map('trim', explode(',', $validated['skills']))
                : [];
        }

        if (!empty($profileData)) {
            $candidate->candidateProfile()->updateOrCreate(
                ['user_id' => $candidate->id],
                $profileData
            );
        }

        return response()->json($candidate->load('candidateProfile'));
    }

    public function updateStatus(Request $request, User $candidate): JsonResponse
    {
        if ($candidate->role !== User::ROLE_CANDIDATE) {
            return response()->json(['message' => 'Candidate not found.'], 404);
        }

        $validated = $request->validate([
            'status' => ['required', 'in:'.User::STATUS_ACTIVE.','.User::STATUS_SUSPENDED],
        ]);

        $candidate->update(['status' => $validated['status']]);

        return response()->json($candidate);
    }

    public function destroy(User $candidate): JsonResponse
    {
        if ($candidate->role !== User::ROLE_CANDIDATE) {
            return response()->json(['message' => 'Candidate not found.'], 404);
        }

        $candidate->delete();

        return response()->json(['message' => 'Candidate deleted.']);
    }

    private function generateUniqueCode(string $role): string
    {
        $prefix = $role === User::ROLE_COMPANY ? 'COMP' : 'CAND';

        return $prefix.'-'.Str::upper(Str::random(8));
    }
}
