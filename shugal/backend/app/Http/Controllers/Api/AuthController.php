<?php

namespace App\Http\Controllers\Api;

use App\Models\CandidateProfile;
use App\Models\CompanyProfile;
use App\Models\Otp;
use App\Models\Setting;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Mail\OtpCodeMail;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use App\Services\ActivityLogger;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'role' => ['required', 'in:'.User::ROLE_CANDIDATE.','.User::ROLE_COMPANY],
            'company_name' => ['nullable', 'string', 'max:255', 'required_if:role,'.User::ROLE_COMPANY],
            // Candidate profile fields
            'date_of_birth' => ['nullable', 'date', 'before:today'],
            'mobile_number' => ['nullable', 'regex:/^\+\d{6,15}$/'],
            'nationality_country_id' => ['nullable', 'exists:countries,id'],
            'resident_country_id' => ['nullable', 'exists:countries,id'],
            'major_ids' => ['nullable', 'array'],
            'major_ids.*' => ['exists:lookups,id'],
            'education_id' => ['nullable', 'exists:lookups,id'],
            'years_of_experience_id' => ['nullable', 'exists:lookups,id'],
        ], [
            'mobile_number.regex' => 'Mobile number must include country code, e.g. +96550123456.',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'role' => $validated['role'],
            'status' => User::STATUS_ACTIVE,
            'unique_code' => $this->generateUniqueCode($validated['role']),
            'password' => $validated['password'],
        ]);

        if ($user->role === User::ROLE_CANDIDATE) {
            $candidateData = ['user_id' => $user->id];
            
            // Add all candidate profile fields
            if (isset($validated['date_of_birth'])) {
                $candidateData['date_of_birth'] = $validated['date_of_birth'];
            }
            if (isset($validated['mobile_number'])) {
                $candidateData['mobile_number'] = $validated['mobile_number'];
            }
            if (isset($validated['nationality_country_id'])) {
                $candidateData['nationality_country_id'] = $validated['nationality_country_id'];
            }
            if (isset($validated['resident_country_id'])) {
                $candidateData['resident_country_id'] = $validated['resident_country_id'];
            }
            if (isset($validated['major_ids'])) {
                $candidateData['major_ids'] = $validated['major_ids'];
            }
            if (isset($validated['education_id'])) {
                $candidateData['education_id'] = $validated['education_id'];
            }
            if (isset($validated['years_of_experience_id'])) {
                $candidateData['years_of_experience_id'] = $validated['years_of_experience_id'];
            }
            
            CandidateProfile::create($candidateData);
        }

        if ($user->role === User::ROLE_COMPANY) {
            $companyData = [
                'user_id' => $user->id,
                'company_name' => $validated['company_name'],
                'contact_email' => $user->email,
            ];
            
            // Add mobile number if provided
            if (isset($validated['mobile_number'])) {
                $companyData['mobile_number'] = $validated['mobile_number'];
            }
            
            CompanyProfile::create($companyData);
        }

        $token = $user->createToken('api')->plainTextToken;

        $otp = $this->createOtp($user, 'verify_email');
        if (!$this->sendOtpEmail($otp, $validated['name'])) {
            return response()->json([
                'message' => 'OTP email failed to send. Check mail configuration.',
            ], 500);
        }
        ActivityLogger::log($user, 'auth.register', ['role' => $user->role]);

        return response()->json([
            'token' => $token,
            'user' => $user->load(['candidateProfile', 'companyProfile']),
            'otp' => [
                'code' => $otp->code,
                'expires_at' => $otp->expires_at,
            ],
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        if ($user->status === User::STATUS_SUSPENDED) {
            return response()->json(['message' => 'Account suspended.'], 403);
        }

        $token = $user->createToken('api')->plainTextToken;
        ActivityLogger::log($user, 'auth.login');

        return response()->json([
            'token' => $token,
            'user' => $user->load(['candidateProfile', 'companyProfile']),
        ]);
    }

    public function adminLogin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $validated['email'])
            ->where('role', User::ROLE_ADMIN)
            ->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        if ($user->status === User::STATUS_SUSPENDED) {
            return response()->json(['message' => 'Account suspended.'], 403);
        }

        $token = $user->createToken('admin')->plainTextToken;
        ActivityLogger::log($user, 'auth.admin_login');

        return response()->json([
            'token' => $token,
            'user' => $user,
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        ActivityLogger::log($request->user(), 'auth.logout');
        $request->user()?->currentAccessToken()?->delete();

        return response()->json(['message' => 'Logged out.']);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $request->user()?->load(['candidateProfile', 'companyProfile']),
        ]);
    }

    public function requestOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'type' => ['required', 'in:verify_email,reset_password'],
        ]);

        $user = User::where('email', $validated['email'])->first();
        if (!$user) {
            return response()->json(['message' => 'User not found.'], 404);
        }

        $otp = $this->createOtp($user, $validated['type']);
        if (!$this->sendOtpEmail($otp, $user->name)) {
            return response()->json([
                'message' => 'OTP email failed to send. Check mail configuration.',
            ], 500);
        }
        ActivityLogger::log($user, 'auth.request_otp', ['type' => $validated['type']]);

        return response()->json([
            'message' => 'OTP generated.',
            'otp' => [
                'code' => $otp->code,
                'expires_at' => $otp->expires_at,
            ],
        ]);
    }

    public function verifyOtp(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'type' => ['required', 'in:verify_email,reset_password'],
            'code' => ['required', 'string'],
        ]);

        $otp = Otp::query()
            ->where('email', $validated['email'])
            ->where('type', $validated['type'])
            ->where('code', $validated['code'])
            ->whereNull('used_at')
            ->orderByDesc('created_at')
            ->first();

        if (!$otp || $otp->expires_at->isPast()) {
            return response()->json(['message' => 'Invalid or expired OTP.'], 422);
        }

        $otp->update(['used_at' => now()]);
        $user = User::where('email', $validated['email'])->first();

        if ($validated['type'] === 'verify_email' && $user) {
            $user->update(['email_verified_at' => now()]);
        }

        ActivityLogger::log($user, 'auth.verify_otp', ['type' => $validated['type']]);

        return response()->json(['message' => 'OTP verified.']);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'code' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $otp = Otp::query()
            ->where('email', $validated['email'])
            ->where('type', 'reset_password')
            ->where('code', $validated['code'])
            ->whereNull('used_at')
            ->orderByDesc('created_at')
            ->first();

        if (!$otp || $otp->expires_at->isPast()) {
            return response()->json(['message' => 'Invalid or expired OTP.'], 422);
        }

        $user = User::where('email', $validated['email'])->first();
        if (!$user) {
            return response()->json(['message' => 'User not found.'], 404);
        }

        $user->update(['password' => $validated['password']]);
        $otp->update(['used_at' => now()]);
        ActivityLogger::log($user, 'auth.reset_password');

        return response()->json(['message' => 'Password updated.']);
    }

    private function generateUniqueCode(string $role): string
    {
        $prefix = $role === User::ROLE_COMPANY ? 'COMP' : 'CAND';

        return $prefix.'-'.Str::upper(Str::random(8));
    }

    private function createOtp(User $user, string $type): Otp
    {
        $code = (string) random_int(100000, 999999);

        return Otp::create([
            'user_id' => $user->id,
            'email' => $user->email,
            'code' => $code,
            'type' => $type,
            'expires_at' => now()->addMinutes(10),
        ]);
    }

    private function sendOtpEmail(Otp $otp, ?string $name = null): bool
    {
        try {
            // Use dark theme logo (light-colored) for dark email header background
            $logoUrl = Setting::where('key', 'app_logo_dark')->value('value')
                ?? Setting::where('key', 'app_logo')->value('value');

            Mail::to($otp->email)->send(new OtpCodeMail(
                $otp->code,
                $otp->type,
                $otp->expires_at,
                $name,
                $logoUrl
            ));
        } catch (\Throwable $e) {
            Log::error('OTP email failed', [
                'email' => $otp->email,
                'type' => $otp->type,
                'error' => $e->getMessage(),
            ]);
            return false;
        }

        return true;
    }
}
