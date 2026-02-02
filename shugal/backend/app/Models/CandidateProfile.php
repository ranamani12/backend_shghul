<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CandidateProfile extends Model
{
    protected $fillable = [
        'user_id',
        'major_ids',
        'years_of_experience_id',
        'skills',
        'education_id',
        'mobile_number',
        'date_of_birth',
        'availability',
        'cv_path',
        'summary',
        'profession_title',
        'address',
        'upwork_profile_url',
        'public_slug',
        'qr_code_path',
        'profile_image_path',
        'nationality_country_id',
        'resident_country_id',
        'is_activated',
        'activated_at',
    ];

    protected $casts = [
        'skills' => 'array',
        'major_ids' => 'array',
        'is_activated' => 'boolean',
        'activated_at' => 'datetime',
        'date_of_birth' => 'date',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function nationalityCountry(): BelongsTo
    {
        return $this->belongsTo(Country::class, 'nationality_country_id');
    }

    public function residentCountry(): BelongsTo
    {
        return $this->belongsTo(Country::class, 'resident_country_id');
    }

    public function yearsOfExperience(): BelongsTo
    {
        return $this->belongsTo(Lookup::class, 'years_of_experience_id');
    }

    public function educationLevel(): BelongsTo
    {
        return $this->belongsTo(Lookup::class, 'education_id');
    }
}
