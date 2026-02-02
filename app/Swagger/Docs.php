<?php

namespace App\Swagger;

use OpenApi\Attributes as OA;

#[OA\Info(title: 'Shugul API', version: '1.0.0', description: 'API documentation for Shugul platform')]
#[OA\Server(url: 'http://127.0.0.1:8000/api', description: 'Local API server')]
#[OA\SecurityScheme(securityScheme: 'bearerAuth', type: 'http', scheme: 'bearer', bearerFormat: 'JWT')]
#[OA\Tag(name: 'Auth', description: 'Authentication endpoints')]
#[OA\Tag(name: 'Admin', description: 'Admin endpoints')]
#[OA\Tag(name: 'Candidate', description: 'Candidate mobile endpoints')]
#[OA\Tag(name: 'Company', description: 'Company mobile endpoints')]
#[OA\Tag(name: 'Messaging', description: 'Chat endpoints')]
#[OA\Tag(name: 'Meetings', description: 'Meeting endpoints')]
#[OA\Tag(name: 'Public', description: 'Public browse endpoints')]
#[OA\Tag(name: 'Lookups', description: 'Lookup values for mobile')]
#[OA\Tag(name: 'Countries', description: 'Country values for mobile')]
class Docs
{
    #[OA\Post(
        path: '/auth/register',
        tags: ['Auth'],
        summary: 'Register candidate or company',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['name', 'email', 'password', 'password_confirmation', 'role'],
                properties: [
                    new OA\Property(property: 'name', type: 'string'),
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                    new OA\Property(property: 'password', type: 'string', format: 'password'),
                    new OA\Property(property: 'password_confirmation', type: 'string', format: 'password'),
                    new OA\Property(property: 'role', type: 'string', example: 'candidate'),
                    new OA\Property(property: 'company_name', type: 'string'),
                ]
            )
        ),
        responses: [new OA\Response(response: 201, description: 'Registered')]
    )]
    public function register(): void {}

    #[OA\Post(
        path: '/auth/login',
        tags: ['Auth'],
        summary: 'Login as candidate or company',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['email', 'password'],
                properties: [
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                    new OA\Property(property: 'password', type: 'string', format: 'password'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'Authenticated')]
    )]
    public function login(): void {}

    #[OA\Post(
        path: '/auth/admin/login',
        tags: ['Auth'],
        summary: 'Admin login',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['email', 'password'],
                properties: [
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                    new OA\Property(property: 'password', type: 'string', format: 'password'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'Authenticated')]
    )]
    public function adminLogin(): void {}

    #[OA\Get(
        path: '/auth/me',
        tags: ['Auth'],
        summary: 'Get current user',
        security: [['bearerAuth' => []]],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function me(): void {}

    #[OA\Post(
        path: '/auth/otp/request',
        tags: ['Auth'],
        summary: 'Request OTP',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['email', 'type'],
                properties: [
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                    new OA\Property(property: 'type', type: 'string', example: 'verify_email'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OTP generated')]
    )]
    public function requestOtp(): void {}

    #[OA\Post(
        path: '/auth/otp/resend',
        tags: ['Auth'],
        summary: 'Resend OTP',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['email', 'type'],
                properties: [
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                    new OA\Property(property: 'type', type: 'string', example: 'verify_email'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OTP generated')]
    )]
    public function resendOtp(): void {}

    #[OA\Post(
        path: '/auth/otp/verify',
        tags: ['Auth'],
        summary: 'Verify OTP',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['email', 'type', 'code'],
                properties: [
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                    new OA\Property(property: 'type', type: 'string', example: 'verify_email'),
                    new OA\Property(property: 'code', type: 'string'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OTP verified')]
    )]
    public function verifyOtp(): void {}

    #[OA\Post(
        path: '/auth/password/reset',
        tags: ['Auth'],
        summary: 'Reset password with OTP',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['email', 'code', 'password', 'password_confirmation'],
                properties: [
                    new OA\Property(property: 'email', type: 'string', format: 'email'),
                    new OA\Property(property: 'code', type: 'string'),
                    new OA\Property(property: 'password', type: 'string', format: 'password'),
                    new OA\Property(property: 'password_confirmation', type: 'string', format: 'password'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'Password updated')]
    )]
    public function resetPassword(): void {}

    #[OA\Get(
        path: '/jobs',
        tags: ['Public'],
        summary: 'List jobs (public)',
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function publicJobs(): void {}

    #[OA\Get(
        path: '/jobs/{job}',
        tags: ['Public'],
        summary: 'Job detail (public)',
        parameters: [
            new OA\Parameter(name: 'job', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function publicJob(): void {}

    #[OA\Get(
        path: '/candidates',
        tags: ['Public'],
        summary: 'List candidates (public)',
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function publicCandidates(): void {}

    #[OA\Get(
        path: '/candidates/public/{slug}',
        tags: ['Public'],
        summary: 'Public resume by slug',
        parameters: [
            new OA\Parameter(name: 'slug', in: 'path', required: true, schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function publicCandidate(): void {}

    #[OA\Get(
        path: '/admin/candidates',
        tags: ['Admin'],
        summary: 'List candidates',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'q', in: 'query', schema: new OA\Schema(type: 'string')),
            new OA\Parameter(name: 'status', in: 'query', schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function candidates(): void {}

    #[OA\Get(
        path: '/admin/candidates/{candidate}',
        tags: ['Admin'],
        summary: 'Candidate profile',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(
                name: 'candidate',
                in: 'path',
                required: true,
                schema: new OA\Schema(type: 'integer')
            ),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function candidateProfile(): void {}

    #[OA\Get(
        path: '/admin/companies',
        tags: ['Admin'],
        summary: 'List companies',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'q', in: 'query', schema: new OA\Schema(type: 'string')),
            new OA\Parameter(name: 'status', in: 'query', schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function companies(): void {}

    #[OA\Get(
        path: '/admin/companies/{company}',
        tags: ['Admin'],
        summary: 'Company profile',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(
                name: 'company',
                in: 'path',
                required: true,
                schema: new OA\Schema(type: 'integer')
            ),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function companyProfile(): void {}

    #[OA\Get(
        path: '/admin/jobs',
        tags: ['Admin'],
        summary: 'List jobs',
        security: [['bearerAuth' => []]],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function jobs(): void {}

    #[OA\Get(
        path: '/admin/transactions',
        tags: ['Admin'],
        summary: 'List transactions',
        security: [['bearerAuth' => []]],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function transactions(): void {}

    #[OA\Get(
        path: '/admin/settings',
        tags: ['Admin'],
        summary: 'List settings',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'group', in: 'query', schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function settings(): void {}

    #[OA\Get(
        path: '/admin/resume-questions',
        tags: ['Admin'],
        summary: 'List resume questions',
        security: [['bearerAuth' => []]],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function resumeQuestions(): void {}

    #[OA\Get(
        path: '/admin/activity-logs',
        tags: ['Admin'],
        summary: 'List activity logs',
        security: [['bearerAuth' => []]],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function activityLogs(): void {}

    #[OA\Get(
        path: '/admin/lookups',
        tags: ['Admin'],
        summary: 'List lookup items',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'type', in: 'query', schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function adminLookups(): void {}

    #[OA\Post(
        path: '/admin/lookups',
        tags: ['Admin'],
        summary: 'Create lookup item',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['type', 'translations'],
                properties: [
                    new OA\Property(property: 'type', type: 'string', example: 'major'),
                    new OA\Property(property: 'sort_order', type: 'integer'),
                    new OA\Property(property: 'is_active', type: 'boolean'),
                    new OA\Property(
                        property: 'translations',
                        type: 'object',
                        example: ['en' => 'Computer Science', 'ar' => 'علوم الحاسب']
                    ),
                ]
            )
        ),
        responses: [new OA\Response(response: 201, description: 'Created')]
    )]
    public function adminCreateLookup(): void {}

    #[OA\Put(
        path: '/admin/lookups/{lookup}',
        tags: ['Admin'],
        summary: 'Update lookup item',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'lookup', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'type', type: 'string', example: 'major'),
                    new OA\Property(property: 'sort_order', type: 'integer'),
                    new OA\Property(property: 'is_active', type: 'boolean'),
                    new OA\Property(
                        property: 'translations',
                        type: 'object',
                        example: ['en' => 'Computer Science', 'ar' => 'علوم الحاسب']
                    ),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function adminUpdateLookup(): void {}

    #[OA\Delete(
        path: '/admin/lookups/{lookup}',
        tags: ['Admin'],
        summary: 'Delete lookup item',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'lookup', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function adminDeleteLookup(): void {}

    #[OA\Get(
        path: '/admin/countries',
        tags: ['Admin'],
        summary: 'List countries',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'active', in: 'query', schema: new OA\Schema(type: 'boolean')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function adminCountries(): void {}

    #[OA\Post(
        path: '/admin/countries',
        tags: ['Admin'],
        summary: 'Create country',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['translations'],
                properties: [
                    new OA\Property(property: 'code', type: 'string', example: 'KW'),
                    new OA\Property(property: 'flag_path', type: 'string'),
                    new OA\Property(property: 'sort_order', type: 'integer'),
                    new OA\Property(property: 'is_active', type: 'boolean'),
                    new OA\Property(
                        property: 'translations',
                        type: 'object',
                        example: ['en' => 'Kuwait', 'ar' => 'الكويت']
                    ),
                ]
            )
        ),
        responses: [new OA\Response(response: 201, description: 'Created')]
    )]
    public function adminCreateCountry(): void {}

    #[OA\Put(
        path: '/admin/countries/{country}',
        tags: ['Admin'],
        summary: 'Update country',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'country', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'code', type: 'string', example: 'KW'),
                    new OA\Property(property: 'flag_path', type: 'string'),
                    new OA\Property(property: 'sort_order', type: 'integer'),
                    new OA\Property(property: 'is_active', type: 'boolean'),
                    new OA\Property(
                        property: 'translations',
                        type: 'object',
                        example: ['en' => 'Kuwait', 'ar' => 'الكويت']
                    ),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function adminUpdateCountry(): void {}

    #[OA\Delete(
        path: '/admin/countries/{country}',
        tags: ['Admin'],
        summary: 'Delete country',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'country', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function adminDeleteCountry(): void {}

    #[OA\Post(
        path: '/admin/countries/upload',
        tags: ['Admin'],
        summary: 'Upload country flag',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\MediaType(
                mediaType: 'multipart/form-data',
                schema: new OA\Schema(
                    required: ['flag'],
                    properties: [new OA\Property(property: 'flag', type: 'string', format: 'binary')]
                )
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function adminUploadCountryFlag(): void {}

    #[OA\Get(
        path: '/mobile/candidate/profile',
        tags: ['Candidate'],
        summary: 'Candidate profile',
        security: [['bearerAuth' => []]],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function candidateProfileSelf(): void {}

    #[OA\Put(
        path: '/mobile/candidate/profile',
        tags: ['Candidate'],
        summary: 'Update candidate profile',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'name', type: 'string'),
                    new OA\Property(property: 'major_ids', type: 'array', items: new OA\Items(type: 'integer'), description: 'Array of major/field lookup IDs'),
                    new OA\Property(property: 'years_of_experience_id', type: 'integer', description: 'Years of experience lookup ID'),
                    new OA\Property(property: 'skills', type: 'array', items: new OA\Items(type: 'string')),
                    new OA\Property(property: 'education_id', type: 'integer', description: 'Education level lookup ID'),
                    new OA\Property(property: 'mobile_number', type: 'string', example: '+96550123456'),
                    new OA\Property(property: 'availability', type: 'string'),
                    new OA\Property(property: 'cv_path', type: 'string'),
                    new OA\Property(property: 'summary', type: 'string'),
                    new OA\Property(property: 'public_slug', type: 'string'),
                    new OA\Property(property: 'profile_image_path', type: 'string'),
                    new OA\Property(property: 'nationality_country_id', type: 'integer', description: 'Nationality country ID'),
                    new OA\Property(property: 'resident_country_id', type: 'integer', description: 'Resident country ID'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function updateCandidateProfile(): void {}

    #[OA\Post(
        path: '/mobile/candidate/profile/image',
        tags: ['Candidate'],
        summary: 'Upload candidate profile image',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\MediaType(
                mediaType: 'multipart/form-data',
                schema: new OA\Schema(
                    required: ['image'],
                    properties: [new OA\Property(property: 'image', type: 'string', format: 'binary')]
                )
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function uploadCandidateImage(): void {}

    #[OA\Post(
        path: '/mobile/candidate/profile/cv',
        tags: ['Candidate'],
        summary: 'Upload candidate CV',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\MediaType(
                mediaType: 'multipart/form-data',
                schema: new OA\Schema(
                    required: ['cv'],
                    properties: [new OA\Property(property: 'cv', type: 'string', format: 'binary')]
                )
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function uploadCandidateCv(): void {}

    #[OA\Post(
        path: '/mobile/candidate/activate',
        tags: ['Candidate'],
        summary: 'Activate candidate profile (payment stub)',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'currency', type: 'string', example: 'KWD'),
                    new OA\Property(property: 'method', type: 'string', example: 'manual'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function activateCandidate(): void {}

    #[OA\Get(
        path: '/mobile/candidate/applications',
        tags: ['Candidate'],
        summary: 'List candidate applications',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'per_page', in: 'query', schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function candidateApplications(): void {}

    #[OA\Post(
        path: '/mobile/candidate/jobs/{job}/apply',
        tags: ['Candidate'],
        summary: 'Apply to a job',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'job', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'cover_letter', type: 'string'),
                ]
            )
        ),
        responses: [new OA\Response(response: 201, description: 'Created')]
    )]
    public function applyJob(): void {}

    #[OA\Get(
        path: '/mobile/company/profile',
        tags: ['Company'],
        summary: 'Company profile',
        security: [['bearerAuth' => []]],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function companyProfileSelf(): void {}

    #[OA\Put(
        path: '/mobile/company/profile',
        tags: ['Company'],
        summary: 'Update company profile',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'name', type: 'string'),
                    new OA\Property(property: 'company_name', type: 'string'),
                    new OA\Property(property: 'country_id', type: 'integer', description: 'Country ID'),
                    new OA\Property(property: 'mobile_number', type: 'string', example: '+96550123456', description: 'Mobile number with country code'),
                    new OA\Property(property: 'civil_id', type: 'string'),
                    new OA\Property(property: 'majors', type: 'array', items: new OA\Items(type: 'string'), description: 'Array of major/field names'),
                    new OA\Property(property: 'website', type: 'string'),
                    new OA\Property(property: 'description', type: 'string'),
                    new OA\Property(property: 'logo_path', type: 'string', description: 'Logo path (use upload endpoint instead)'),
                    new OA\Property(property: 'license_path', type: 'string', description: 'License path (use upload endpoint instead)'),
                    new OA\Property(property: 'contact_email', type: 'string', format: 'email'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function updateCompanyProfile(): void {}

    #[OA\Post(
        path: '/mobile/company/profile/logo',
        tags: ['Company'],
        summary: 'Upload company logo',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\MediaType(
                mediaType: 'multipart/form-data',
                schema: new OA\Schema(
                    required: ['logo'],
                    properties: [new OA\Property(property: 'logo', type: 'string', format: 'binary')]
                )
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function uploadCompanyLogo(): void {}

    #[OA\Post(
        path: '/mobile/company/profile/license',
        tags: ['Company'],
        summary: 'Upload company license document',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\MediaType(
                mediaType: 'multipart/form-data',
                schema: new OA\Schema(
                    required: ['license'],
                    properties: [new OA\Property(property: 'license', type: 'string', format: 'binary')]
                )
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function uploadCompanyLicense(): void {}

    #[OA\Get(
        path: '/mobile/company/jobs',
        tags: ['Company'],
        summary: 'List company jobs',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'per_page', in: 'query', schema: new OA\Schema(type: 'integer')),
            new OA\Parameter(name: 'status', in: 'query', schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function companyJobs(): void {}

    #[OA\Post(
        path: '/mobile/company/jobs',
        tags: ['Company'],
        summary: 'Create company job',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['title', 'description'],
                properties: [
                    new OA\Property(property: 'title', type: 'string'),
                    new OA\Property(property: 'description', type: 'string'),
                    new OA\Property(property: 'requirements', type: 'string'),
                    new OA\Property(property: 'experience_level', type: 'string'),
                    new OA\Property(property: 'location', type: 'string'),
                    new OA\Property(property: 'status', type: 'string', example: 'open'),
                    new OA\Property(property: 'is_active', type: 'boolean', example: true),
                    new OA\Property(property: 'published_at', type: 'string', format: 'date-time'),
                ]
            )
        ),
        responses: [new OA\Response(response: 201, description: 'Created')]
    )]
    public function companyCreateJob(): void {}

    #[OA\Put(
        path: '/mobile/company/jobs/{job}',
        tags: ['Company'],
        summary: 'Update company job',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'job', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'title', type: 'string'),
                    new OA\Property(property: 'description', type: 'string'),
                    new OA\Property(property: 'requirements', type: 'string'),
                    new OA\Property(property: 'experience_level', type: 'string'),
                    new OA\Property(property: 'location', type: 'string'),
                    new OA\Property(property: 'status', type: 'string', example: 'open'),
                    new OA\Property(property: 'is_active', type: 'boolean'),
                    new OA\Property(property: 'published_at', type: 'string', format: 'date-time'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function companyUpdateJob(): void {}

    #[OA\Delete(
        path: '/mobile/company/jobs/{job}',
        tags: ['Company'],
        summary: 'Delete company job',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'job', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function companyDeleteJob(): void {}

    #[OA\Get(
        path: '/mobile/company/jobs/{job}/applicants',
        tags: ['Company'],
        summary: 'List job applicants',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'job', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function companyJobApplicants(): void {}

    #[OA\Get(
        path: '/mobile/company/candidates',
        tags: ['Company'],
        summary: 'Browse candidates',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'major_id', in: 'query', schema: new OA\Schema(type: 'integer'), description: 'Filter by major/field lookup ID'),
            new OA\Parameter(name: 'per_page', in: 'query', schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function companyBrowseCandidates(): void {}

    #[OA\Post(
        path: '/mobile/company/candidates/{candidate}/unlock',
        tags: ['Company'],
        summary: 'Unlock candidate',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'candidate', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'currency', type: 'string', example: 'KWD'),
                    new OA\Property(property: 'method', type: 'string', example: 'manual'),
                ]
            )
        ),
        responses: [new OA\Response(response: 201, description: 'Created')]
    )]
    public function companyUnlockCandidate(): void {}

    #[OA\Get(
        path: '/mobile/messages',
        tags: ['Messaging'],
        summary: 'List conversations',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'per_page', in: 'query', schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function conversations(): void {}

    #[OA\Get(
        path: '/mobile/messages/{user}',
        tags: ['Messaging'],
        summary: 'Get message thread',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'user', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function messageThread(): void {}

    #[OA\Post(
        path: '/mobile/messages/{user}',
        tags: ['Messaging'],
        summary: 'Send message',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'user', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ['content'],
                properties: [
                    new OA\Property(property: 'content', type: 'string'),
                ]
            )
        ),
        responses: [new OA\Response(response: 201, description: 'Created')]
    )]
    public function sendMessage(): void {}

    #[OA\Patch(
        path: '/mobile/messages/{message}/read',
        tags: ['Messaging'],
        summary: 'Mark message as read',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'message', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function markMessageRead(): void {}

    #[OA\Get(
        path: '/mobile/meetings',
        tags: ['Meetings'],
        summary: 'List meetings',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'per_page', in: 'query', schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function meetings(): void {}

    #[OA\Post(
        path: '/mobile/meetings',
        tags: ['Meetings'],
        summary: 'Create meeting',
        security: [['bearerAuth' => []]],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'candidate_id', type: 'integer'),
                    new OA\Property(property: 'company_id', type: 'integer'),
                    new OA\Property(property: 'scheduled_at', type: 'string', format: 'date-time'),
                    new OA\Property(property: 'notes', type: 'string'),
                ]
            )
        ),
        responses: [new OA\Response(response: 201, description: 'Created')]
    )]
    public function createMeeting(): void {}

    #[OA\Get(
        path: '/mobile/meetings/{meeting}',
        tags: ['Meetings'],
        summary: 'Meeting detail',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'meeting', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function meetingDetail(): void {}

    #[OA\Patch(
        path: '/mobile/meetings/{meeting}',
        tags: ['Meetings'],
        summary: 'Update meeting',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'meeting', in: 'path', required: true, schema: new OA\Schema(type: 'integer')),
        ],
        requestBody: new OA\RequestBody(
            required: false,
            content: new OA\JsonContent(
                properties: [
                    new OA\Property(property: 'status', type: 'string', example: 'accepted'),
                    new OA\Property(property: 'scheduled_at', type: 'string', format: 'date-time'),
                    new OA\Property(property: 'notes', type: 'string'),
                ]
            )
        ),
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function updateMeeting(): void {}

    #[OA\Get(
        path: '/mobile/lookups',
        tags: ['Lookups'],
        summary: 'List lookup items by type',
        security: [['bearerAuth' => []]],
        parameters: [
            new OA\Parameter(name: 'type', in: 'query', required: true, schema: new OA\Schema(type: 'string')),
            new OA\Parameter(name: 'locale', in: 'query', schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function mobileLookups(): void {}

    #[OA\Get(
        path: '/mobile/countries',
        tags: ['Countries'],
        summary: 'List countries',
        parameters: [
            new OA\Parameter(name: 'locale', in: 'query', schema: new OA\Schema(type: 'string')),
        ],
        responses: [new OA\Response(response: 200, description: 'OK')]
    )]
    public function mobileCountries(): void {}
}
