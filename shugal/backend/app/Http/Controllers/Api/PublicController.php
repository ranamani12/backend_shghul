<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CandidateProfile;
use App\Models\Job;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PublicController extends Controller
{
    public function jobs(Request $request): JsonResponse
    {
        $query = Job::query()
            ->with(['company.companyProfile'])
            ->where('is_active', true);

        // Search by keyword (title or description)
        if ($request->filled('q')) {
            $search = $request->string('q');
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Filter by location
        if ($request->filled('location')) {
            $query->where('location', 'like', '%'.$request->string('location').'%');
        }

        // Filter by major_id (single major)
        if ($request->filled('major_id')) {
            $majorId = $request->integer('major_id');
            $query->whereJsonContains('major_ids', $majorId);
        }

        // Filter by major_ids (multiple majors - any match)
        if ($request->filled('major_ids')) {
            $majorIds = array_map('intval', explode(',', $request->string('major_ids')));
            $query->where(function ($q) use ($majorIds) {
                foreach ($majorIds as $majorId) {
                    $q->orWhereJsonContains('major_ids', $majorId);
                }
            });
        }

        // Filter by experience level
        if ($request->filled('experience_level')) {
            $query->where('experience_level', $request->string('experience_level'));
        }

        // Filter by hiring type (full-time, part-time, contract, etc.)
        if ($request->filled('hiring_type')) {
            $query->where('hiring_type', $request->string('hiring_type'));
        }

        // Filter by education level
        if ($request->filled('education_level')) {
            $query->where('education_level', 'like', '%'.$request->string('education_level').'%');
        }

        // Filter by job type (remote, on-site, hybrid)
        if ($request->filled('job_type')) {
            $query->where('job_type', $request->string('job_type'));
        }

        return response()->json($query->orderByDesc('published_at')->paginate($request->integer('per_page', 15)));
    }

    public function job(Job $job): JsonResponse
    {
        if (!$job->is_active) {
            return response()->json(['message' => 'Job not found.'], 404);
        }

        return response()->json($job->load(['company.companyProfile']));
    }

    public function candidates(Request $request): JsonResponse
    {
        $query = User::query()
            ->where('role', User::ROLE_CANDIDATE)
            ->where('status', User::STATUS_ACTIVE)
            ->with('candidateProfile');

        if ($request->filled('major_id')) {
            $majorId = $request->integer('major_id');
            $query->whereHas('candidateProfile', function ($builder) use ($majorId) {
                $builder->whereJsonContains('major_ids', $majorId);
            });
        }

        $paginated = $query->paginate($request->integer('per_page', 20));
        $paginated->getCollection()->transform(function (User $candidate) {
            $profile = $candidate->candidateProfile;

            return [
                'id' => $candidate->id,
                'major_ids' => $profile?->major_ids ?? [],
                'years_of_experience_id' => $profile?->years_of_experience_id,
                'profile_image_path' => $profile?->profile_image_path,
                'is_blurred' => true,
            ];
        });

        return response()->json($paginated);
    }

    public function candidatePublic(string $slug): JsonResponse
    {
        $profile = CandidateProfile::query()
            ->where('public_slug', $slug)
            ->where('is_activated', true)
            ->first();

        if (!$profile) {
            return response()->json(['message' => 'Candidate not found.'], 404);
        }

        return response()->json($profile->load('user'));
    }

    public function settings(Request $request): JsonResponse
    {
        $query = Setting::query();

        if ($request->filled('group')) {
            $query->where('group', $request->string('group'));
        }

        return response()->json($query->orderBy('group')->orderBy('key')->get());
    }
}
