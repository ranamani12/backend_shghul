<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\CandidateUnlock;
use App\Models\CompanyProfile;
use App\Models\Job;
use App\Models\Lookup;
use App\Models\Notification;
use App\Models\Setting;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;
use App\Services\ActivityLogger;

class CompanyController extends Controller
{
    public function profile(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        return response()->json($user->load('companyProfile'));
    }

    public function dashboard(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        // Get recent jobs (limit 5)
        $jobs = Job::query()
            ->where('company_id', $user->id)
            ->withCount('applications')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(function (Job $job) {
                // Resolve major names from major_ids
                $majorNames = [];
                if (!empty($job->major_ids)) {
                    $majorNames = Lookup::whereIn('id', $job->major_ids)
                        ->with(['translations' => function ($query) {
                            $query->where('locale', 'en');
                        }])
                        ->get()
                        ->pluck('translations')
                        ->flatten()
                        ->pluck('name')
                        ->toArray();
                }

                return [
                    'id' => $job->id,
                    'title' => $job->title,
                    'description' => $job->description,
                    'salary_range' => $job->salary_range,
                    'experience_level' => $job->experience_level,
                    'hiring_type' => $job->hiring_type,
                    'interview_type' => $job->interview_type,
                    'location' => $job->location,
                    'major_ids' => $job->major_ids,
                    'major_names' => $majorNames,
                    'is_active' => $job->is_active,
                    'applications_count' => $job->applications_count,
                    'created_at' => $job->created_at,
                ];
            });

        // Get unlocked candidate IDs
        $unlockedIds = CandidateUnlock::query()
            ->where('company_id', $user->id)
            ->pluck('candidate_id')
            ->all();

        // Get recent candidates (limit 5)
        $candidates = User::query()
            ->where('role', User::ROLE_CANDIDATE)
            ->where('status', User::STATUS_ACTIVE)
            ->with('candidateProfile')
            ->orderByDesc('created_at')
            ->limit(5)
            ->get()
            ->map(function (User $candidate) use ($unlockedIds) {
                $profile = $candidate->candidateProfile;
                $isUnlocked = in_array($candidate->id, $unlockedIds, true);

                // Resolve major names
                $majorNames = [];
                if (!empty($profile?->major_ids)) {
                    $majorNames = Lookup::whereIn('id', $profile->major_ids)
                        ->with(['translations' => function ($query) {
                            $query->where('locale', 'en');
                        }])
                        ->get()
                        ->pluck('translations')
                        ->flatten()
                        ->pluck('name')
                        ->toArray();
                }

                // Resolve experience year name
                $experienceName = null;
                if ($profile?->years_of_experience_id) {
                    $expLookup = Lookup::with(['translations' => function ($query) {
                        $query->where('locale', 'en');
                    }])->find($profile->years_of_experience_id);
                    $experienceName = $expLookup?->translations->first()?->name;
                }

                if ($isUnlocked) {
                    return [
                        'id' => $candidate->id,
                        'name' => $candidate->name,
                        'email' => $candidate->email,
                        'profile_image_path' => $profile?->profile_image_path,
                        'job_title' => $profile?->job_title,
                        'location' => $profile?->location,
                        'major_ids' => $profile?->major_ids ?? [],
                        'major_names' => $majorNames,
                        'years_of_experience_id' => $profile?->years_of_experience_id,
                        'experience_name' => $experienceName,
                        'is_unlocked' => true,
                        'is_blurred' => false,
                    ];
                }

                return [
                    'id' => $candidate->id,
                    'name' => null,
                    'profile_image_path' => $profile?->profile_image_path,
                    'job_title' => $profile?->job_title,
                    'major_ids' => $profile?->major_ids ?? [],
                    'major_names' => $majorNames,
                    'years_of_experience_id' => $profile?->years_of_experience_id,
                    'experience_name' => $experienceName,
                    'is_unlocked' => false,
                    'is_blurred' => true,
                ];
            });

        // Get company profile info
        $companyProfile = $user->companyProfile;

        return response()->json([
            'company' => [
                'id' => $user->id,
                'name' => $user->name,
                'logo_path' => $companyProfile?->logo_path,
            ],
            'jobs' => $jobs,
            'candidates' => $candidates,
        ]);
    }

    public function uploadLogo(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        $validated = $request->validate([
            'logo' => ['required', 'file', 'mimes:jpg,jpeg,png,svg', 'max:5120'],
        ]);

        $path = $validated['logo']->store('companies', 'public');
        $url = Storage::disk('public')->url($path);

        $user->companyProfile()->updateOrCreate(
            ['user_id' => $user->id],
            ['logo_path' => $url]
        );

        ActivityLogger::log($user, 'company.upload_logo');

        return response()->json(['url' => $url]);
    }

    public function uploadLicense(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        $validated = $request->validate([
            'license' => ['required', 'file', 'mimes:pdf,jpg,jpeg,png,webp', 'max:10240'],
        ]);

        $path = $validated['license']->store('company-licenses', 'public');
        $url = Storage::disk('public')->url($path);

        $user->companyProfile()->updateOrCreate(
            ['user_id' => $user->id],
            ['license_path' => $url]
        );

        ActivityLogger::log($user, 'company.upload_license');

        return response()->json(['url' => $url]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'company_name' => ['sometimes', 'string', 'max:255'],
            'industry' => ['nullable', 'string', 'max:255'],
            'contact_email' => ['nullable', 'email', 'max:255'],
            'contact_phone' => ['nullable', 'string', 'max:50'],
            'location' => ['nullable', 'string', 'max:255'],
            'website' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'logo_path' => ['nullable', 'string', 'max:255'],
            'country_id' => ['nullable', 'exists:countries,id'],
            'mobile_number' => ['nullable', 'regex:/^\+\d{6,15}$/'],
            'civil_id' => ['nullable', 'string', 'max:255'],
            'majors' => ['nullable', 'array'],
            'license_path' => ['nullable', 'string', 'max:255'],
        ]);

        if (isset($validated['name'])) {
            $user->update(['name' => $validated['name']]);
        }

        $profileData = collect($validated)->except('name')->toArray();
        if (!empty($profileData)) {
            CompanyProfile::updateOrCreate(
                ['user_id' => $user->id],
                $profileData
            );
        }

        return response()->json($user->load('companyProfile'));
    }

    public function jobs(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        $query = Job::query()
            ->where('company_id', $user->id)
            ->withCount('applications')
            ->orderByDesc('created_at');

        return response()->json($query->paginate($request->integer('per_page', 15)));
    }

    public function storeJob(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'requirements' => ['nullable', 'string'],
            'experience_level' => ['nullable', 'string', 'max:255'],
            'location' => ['nullable', 'string', 'max:255'],
            'salary_range' => ['nullable', 'string', 'max:255'],
            'hiring_type' => ['nullable', 'string', 'max:255'],
            'interview_type' => ['nullable', 'string', 'max:255'],
            'major_ids' => ['nullable', 'array'],
            'major_ids.*' => ['integer', 'exists:lookups,id'],
            'status' => ['sometimes', 'string', 'max:50'],
            'is_active' => ['sometimes', 'boolean'],
            'published_at' => ['nullable', 'date'],
        ]);

        $validated['company_id'] = $user->id;
        $job = Job::create($validated);

        ActivityLogger::log($user, 'company.create_job', ['job_id' => $job->id]);

        return response()->json($job, 201);
    }

    public function updateJob(Request $request, Job $job): JsonResponse
    {
        $user = $this->requireCompany($request);
        if ($job->company_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string'],
            'requirements' => ['nullable', 'string'],
            'experience_level' => ['nullable', 'string', 'max:255'],
            'location' => ['nullable', 'string', 'max:255'],
            'salary_range' => ['nullable', 'string', 'max:255'],
            'hiring_type' => ['nullable', 'string', 'max:255'],
            'interview_type' => ['nullable', 'string', 'max:255'],
            'major_ids' => ['nullable', 'array'],
            'major_ids.*' => ['integer', 'exists:lookups,id'],
            'status' => ['sometimes', 'string', 'max:50'],
            'is_active' => ['sometimes', 'boolean'],
            'published_at' => ['nullable', 'date'],
        ]);

        $job->update($validated);
        ActivityLogger::log($user, 'company.update_job', ['job_id' => $job->id]);

        return response()->json($job);
    }

    public function destroyJob(Request $request, Job $job): JsonResponse
    {
        $user = $this->requireCompany($request);
        if ($job->company_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $job->delete();
        ActivityLogger::log($user, 'company.delete_job', ['job_id' => $job->id]);

        return response()->json(['message' => 'Job deleted.']);
    }

    public function applicants(Request $request, Job $job): JsonResponse
    {
        $user = $this->requireCompany($request);
        if ($job->company_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $applications = Application::query()
            ->where('job_id', $job->id)
            ->with(['candidate.candidateProfile'])
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 20));

        return response()->json($applications);
    }

    /**
     * Get all applications received by the company across all jobs.
     */
    public function allApplications(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        // Get all job IDs for this company
        $jobIds = Job::where('company_id', $user->id)->pluck('id');

        $applications = Application::query()
            ->whereIn('job_id', $jobIds)
            ->with(['candidate.candidateProfile', 'job'])
            ->orderByDesc('created_at')
            ->paginate($request->integer('per_page', 20));

        return response()->json($applications);
    }

    public function candidates(Request $request): JsonResponse
    {
        $user = $this->requireCompany($request);

        $query = User::query()
            ->where('role', User::ROLE_CANDIDATE)
            ->where('status', User::STATUS_ACTIVE)
            ->with(['candidateProfile.nationalityCountry', 'candidateProfile.residentCountry']);

        if ($request->filled('major_id')) {
            $majorId = $request->integer('major_id');
            $query->whereHas('candidateProfile', function ($builder) use ($majorId) {
                $builder->whereJsonContains('major_ids', $majorId);
            });
        }

        $unlockedIds = CandidateUnlock::query()
            ->where('company_id', $user->id)
            ->pluck('candidate_id')
            ->all();

        $paginated = $query->paginate($request->integer('per_page', 20));
        $paginated->getCollection()->transform(function (User $candidate) use ($unlockedIds) {
            $profile = $candidate->candidateProfile;
            $isUnlocked = in_array($candidate->id, $unlockedIds, true);

            // Resolve major names
            $majorNames = [];
            if (!empty($profile?->major_ids)) {
                $majorNames = Lookup::whereIn('id', $profile->major_ids)
                    ->with(['translations' => function ($query) {
                        $query->where('locale', 'en');
                    }])
                    ->get()
                    ->pluck('translations')
                    ->flatten()
                    ->pluck('name')
                    ->toArray();
            }

            // Resolve experience year name
            $experienceName = null;
            if ($profile?->years_of_experience_id) {
                $expLookup = Lookup::with(['translations' => function ($query) {
                    $query->where('locale', 'en');
                }])->find($profile->years_of_experience_id);
                $experienceName = $expLookup?->translations->first()?->name;
            }

            // Resolve education level name
            $educationName = null;
            if ($profile?->education_id) {
                $eduLookup = Lookup::with(['translations' => function ($query) {
                    $query->where('locale', 'en');
                }])->find($profile->education_id);
                $educationName = $eduLookup?->translations->first()?->name;
            }

            if ($isUnlocked) {
                return [
                    'id' => $candidate->id,
                    'name' => $candidate->name,
                    'email' => $candidate->email,
                    'unique_code' => $candidate->unique_code,
                    'mobile_number' => $profile?->mobile_number,
                    'profile_image_path' => $profile?->profile_image_path,
                    'profession_title' => $profile?->profession_title,
                    'summary' => $profile?->summary,
                    'address' => $profile?->address,
                    'date_of_birth' => $profile?->date_of_birth?->format('Y-m-d'),
                    'availability' => $profile?->availability,
                    'cv_path' => $profile?->cv_path,
                    'skills' => $profile?->skills ?? [],
                    'major_ids' => $profile?->major_ids ?? [],
                    'major_names' => $majorNames,
                    'years_of_experience_id' => $profile?->years_of_experience_id,
                    'experience_name' => $experienceName,
                    'education_id' => $profile?->education_id,
                    'education_name' => $educationName,
                    'nationality_country' => $profile?->nationalityCountry?->name,
                    'resident_country' => $profile?->residentCountry?->name,
                    'upwork_profile_url' => $profile?->upwork_profile_url,
                    'is_unlocked' => true,
                    'is_blurred' => false,
                ];
            }

            return [
                'id' => $candidate->id,
                'profile_image_path' => $profile?->profile_image_path,
                'profession_title' => $profile?->profession_title,
                'major_ids' => $profile?->major_ids ?? [],
                'major_names' => $majorNames,
                'years_of_experience_id' => $profile?->years_of_experience_id,
                'experience_name' => $experienceName,
                'education_name' => $educationName,
                'is_blurred' => true,
                'is_unlocked' => false,
            ];
        });

        return response()->json($paginated);
    }

    public function unlock(Request $request, User $candidate): JsonResponse
    {
        $user = $this->requireCompany($request);

        if ($candidate->role !== User::ROLE_CANDIDATE) {
            return response()->json(['message' => 'Candidate not found.'], 404);
        }

        $existing = CandidateUnlock::where('candidate_id', $candidate->id)
            ->where('company_id', $user->id)
            ->first();

        if ($existing) {
            return response()->json($existing);
        }

        $fee = $this->getSettingAmount('candidate_unlock_fee', 1.0);

        $transaction = Transaction::create([
            'user_id' => $user->id,
            'type' => 'candidate_unlock',
            'amount' => $fee,
            'currency' => $request->string('currency', 'KWD'),
            'method' => $request->string('method', 'manual'),
            'status' => 'completed',
            'reference' => (string) Str::uuid(),
        ]);

        $unlock = CandidateUnlock::create([
            'candidate_id' => $candidate->id,
            'company_id' => $user->id,
            'transaction_id' => $transaction->id,
            'unlocked_at' => now(),
        ]);

        ActivityLogger::log($user, 'company.unlock_candidate', ['candidate_id' => $candidate->id]);

        // Send notification to candidate
        $companyProfile = $user->companyProfile;
        Notification::candidateUnlocked($candidate, [
            'company_id' => $user->id,
            'company_name' => $companyProfile?->company_name ?? $user->name,
        ]);

        return response()->json($unlock, 201);
    }

    private function requireCompany(Request $request): User
    {
        $user = $request->user();
        abort_if(!$user || $user->role !== User::ROLE_COMPANY, 403, 'Unauthorized.');

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
