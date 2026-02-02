<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\CompanyProfile;
use App\Models\CandidateUnlock;
use App\Models\Job;
use App\Models\Application;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Storage;

class CompanyController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = User::query()
            ->where('role', User::ROLE_COMPANY)
            ->with('companyProfile');

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
            'name' => ['nullable', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'status' => ['sometimes', 'in:'.User::STATUS_ACTIVE.','.User::STATUS_SUSPENDED],
            'company_name' => ['required', 'string', 'max:255'],
            'profile' => ['sometimes', 'array'],
            'profile.country_id' => ['nullable', 'exists:countries,id'],
            'profile.mobile_number' => ['nullable', 'regex:/^\+\d{6,15}$/'],
            'profile.civil_id' => ['nullable', 'string', 'max:255'],
            'profile.majors' => ['nullable', 'array'],
            'profile.license_path' => ['nullable', 'string', 'max:255'],
            'profile.logo_path' => ['nullable', 'string', 'max:255'],
            'profile.website' => ['nullable', 'string', 'max:255'],
            'profile.description' => ['nullable', 'string'],
        ]);

        $user = User::create([
            'name' => $validated['name'] ?? $validated['company_name'],
            'email' => $validated['email'],
            'password' => $validated['password'],
            'role' => User::ROLE_COMPANY,
            'status' => $validated['status'] ?? User::STATUS_ACTIVE,
            'unique_code' => $this->generateUniqueCode(User::ROLE_COMPANY),
        ]);

        $profileData = $validated['profile'] ?? [];
        $profileData['user_id'] = $user->id;
        $profileData['company_name'] = $validated['company_name'];
        $profileData['contact_email'] = $profileData['contact_email'] ?? $user->email;
        CompanyProfile::create($profileData);

        return response()->json($user->load('companyProfile'), 201);
    }

    public function show(User $company): JsonResponse
    {
        if ($company->role !== User::ROLE_COMPANY) {
            return response()->json(['message' => 'Company not found.'], 404);
        }

        $company->load('companyProfile');

        $jobs = Job::query()
            ->where('company_id', $company->id)
            ->withCount('applications')
            ->orderByDesc('created_at')
            ->get();

        $applications = Application::query()
            ->whereHas('job', fn ($builder) => $builder->where('company_id', $company->id))
            ->with(['job', 'candidate.candidateProfile'])
            ->orderByDesc('created_at')
            ->get();

        $unlocks = CandidateUnlock::query()
            ->where('company_id', $company->id)
            ->with(['candidate.candidateProfile', 'transaction'])
            ->orderByDesc('created_at')
            ->get();

        $transactions = Transaction::query()
            ->where('user_id', $company->id)
            ->orderByDesc('created_at')
            ->get();

        return response()->json([
            'company' => $company,
            'jobs' => $jobs,
            'applications' => $applications,
            'unlocks' => $unlocks,
            'transactions' => $transactions,
        ]);
    }

    public function update(Request $request, User $company): JsonResponse
    {
        if ($company->role !== User::ROLE_COMPANY) {
            return response()->json(['message' => 'Company not found.'], 404);
        }

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'max:255', 'unique:users,email,'.$company->id],
            'status' => ['sometimes', 'in:'.User::STATUS_ACTIVE.','.User::STATUS_SUSPENDED],
            'company_name' => ['sometimes', 'string', 'max:255'],
            'profile' => ['sometimes', 'array'],
            'profile.country_id' => ['nullable', 'exists:countries,id'],
            'profile.mobile_number' => ['nullable', 'regex:/^\+\d{6,15}$/'],
            'profile.civil_id' => ['nullable', 'string', 'max:255'],
            'profile.majors' => ['nullable', 'array'],
            'profile.license_path' => ['nullable', 'string', 'max:255'],
            'profile.logo_path' => ['nullable', 'string', 'max:255'],
            'profile.website' => ['nullable', 'string', 'max:255'],
            'profile.description' => ['nullable', 'string'],
        ]);

        $company->update(Arr::except($validated, ['profile', 'company_name']));

        if (isset($validated['profile']) || isset($validated['company_name'])) {
            $profileData = $validated['profile'] ?? [];
            if (isset($validated['company_name'])) {
                $profileData['company_name'] = $validated['company_name'];
            }
            $company->companyProfile()->updateOrCreate(
                ['user_id' => $company->id],
                $profileData
            );
        }

        return response()->json($company->load('companyProfile'));
    }

    public function updateStatus(Request $request, User $company): JsonResponse
    {
        if ($company->role !== User::ROLE_COMPANY) {
            return response()->json(['message' => 'Company not found.'], 404);
        }

        $validated = $request->validate([
            'status' => ['required', 'in:'.User::STATUS_ACTIVE.','.User::STATUS_SUSPENDED],
        ]);

        $company->update(['status' => $validated['status']]);

        return response()->json($company);
    }

    public function destroy(User $company): JsonResponse
    {
        if ($company->role !== User::ROLE_COMPANY) {
            return response()->json(['message' => 'Company not found.'], 404);
        }

        $company->delete();

        return response()->json(['message' => 'Company deleted.']);
    }

    public function uploadLogo(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'logo' => ['required', 'file', 'mimes:jpg,jpeg,png,svg', 'max:5120'],
        ]);

        $path = $validated['logo']->store('companies', 'public');
        $url = Storage::disk('public')->url($path);

        return response()->json(['url' => $url]);
    }

    public function uploadLicense(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'license' => ['required', 'file', 'mimes:pdf,jpg,jpeg,png,webp', 'max:10240'],
        ]);

        $path = $validated['license']->store('company-licenses', 'public');
        $url = Storage::disk('public')->url($path);

        return response()->json(['url' => $url]);
    }

    private function generateUniqueCode(string $role): string
    {
        $prefix = $role === User::ROLE_COMPANY ? 'COMP' : 'CAND';

        return $prefix.'-'.Str::upper(Str::random(8));
    }
}
