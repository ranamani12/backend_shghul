<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Job;
use App\Models\Meeting;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class JobController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Job::query()->with('company');

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('company_id')) {
            $query->where('company_id', $request->integer('company_id'));
        }

        if ($request->filled('q')) {
            $search = $request->string('q');
            $query->where('title', 'like', "%{$search}%");
        }

        return response()->json($query->orderByDesc('created_at')->paginate($request->integer('per_page', 15)));
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'company_id' => ['required', 'exists:users,id'],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'requirements' => ['nullable', 'string'],
            'experience_level' => ['nullable', 'string', 'max:255'],
            'location' => ['nullable', 'string', 'max:255'],
            'salary_range' => ['nullable', 'string', 'max:255'],
            'hiring_type' => ['nullable', 'string', 'max:255'],
            'employment_type' => ['nullable', 'string', 'max:255'],
            'job_type' => ['nullable', 'string', 'max:255'],
            'interview_type' => ['nullable', 'string', 'max:255'],
            'major_ids' => ['nullable', 'array'],
            'major_ids.*' => ['exists:lookups,id'],
            'status' => ['sometimes', 'string', 'max:50'],
            'is_active' => ['sometimes', 'boolean'],
            'published_at' => ['nullable', 'date'],
        ]);

        $company = User::findOrFail($validated['company_id']);
        if ($company->role !== User::ROLE_COMPANY) {
            return response()->json(['message' => 'Company not found.'], 404);
        }

        $job = Job::create($validated);

        return response()->json($job->load('company'), 201);
    }

    public function show(Job $job): JsonResponse
    {
        return response()->json($job->load('company'));
    }

    public function update(Request $request, Job $job): JsonResponse
    {
        $validated = $request->validate([
            'company_id' => ['sometimes', 'exists:users,id'],
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string'],
            'requirements' => ['nullable', 'string'],
            'experience_level' => ['nullable', 'string', 'max:255'],
            'location' => ['nullable', 'string', 'max:255'],
            'salary_range' => ['nullable', 'string', 'max:255'],
            'hiring_type' => ['nullable', 'string', 'max:255'],
            'employment_type' => ['nullable', 'string', 'max:255'],
            'job_type' => ['nullable', 'string', 'max:255'],
            'interview_type' => ['nullable', 'string', 'max:255'],
            'major_ids' => ['nullable', 'array'],
            'major_ids.*' => ['exists:lookups,id'],
            'status' => ['sometimes', 'string', 'max:50'],
            'is_active' => ['sometimes', 'boolean'],
            'published_at' => ['nullable', 'date'],
        ]);

        if (isset($validated['company_id'])) {
            $company = User::findOrFail($validated['company_id']);
            if ($company->role !== User::ROLE_COMPANY) {
                return response()->json(['message' => 'Company not found.'], 404);
            }
        }

        $job->update($validated);

        return response()->json($job->load('company'));
    }

    public function destroy(Job $job): JsonResponse
    {
        $job->delete();

        return response()->json(['message' => 'Job deleted.']);
    }

    public function applications(Job $job): JsonResponse
    {
        $applications = $job->applications()
            ->with([
                'candidate.candidateProfile.yearsOfExperience.translations',
                'candidate.candidateProfile.educationLevel.translations',
            ])
            ->orderByDesc('created_at')
            ->get();

        // Get all meetings for this job indexed by candidate_id
        $meetings = Meeting::where('job_id', $job->id)
            ->get()
            ->keyBy('candidate_id');

        // Collect all major_ids from all candidate profiles
        $allMajorIds = $applications
            ->pluck('candidate.candidateProfile.major_ids')
            ->filter()
            ->flatten()
            ->unique()
            ->values()
            ->toArray();

        // Load all majors at once
        $majorsMap = [];
        if (!empty($allMajorIds)) {
            $majorsMap = \App\Models\Lookup::query()
                ->whereIn('id', $allMajorIds)
                ->with('translations')
                ->get()
                ->keyBy('id');
        }

        // Attach interview and major_lookups to each application
        $applications->each(function ($application) use ($meetings, $majorsMap) {
            $application->interview = $meetings->get($application->candidate_id);

            // Attach major_lookups to candidate profile
            if ($application->candidate?->candidateProfile) {
                $majorIds = $application->candidate->candidateProfile->major_ids ?? [];
                $majorLookups = collect($majorIds)
                    ->map(fn($id) => $majorsMap->get($id))
                    ->filter()
                    ->values()
                    ->toArray();
                $application->candidate->candidateProfile->major_lookups = $majorLookups;
            }
        });

        return response()->json(['data' => $applications]);
    }
}
