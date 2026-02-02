<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Job extends Model
{
    protected $table = 'job_posts';

    protected $fillable = [
        'company_id',
        'title',
        'description',
        'requirements',
        'experience_level',
        'education_level',
        'location',
        'salary_range',
        'hiring_type',
        'employment_type',
        'job_type',
        'interview_type',
        'major_ids',
        'status',
        'is_active',
        'published_at',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'published_at' => 'datetime',
        'major_ids' => 'array',
    ];

    public function company(): BelongsTo
    {
        return $this->belongsTo(User::class, 'company_id');
    }

    public function applications(): HasMany
    {
        return $this->hasMany(Application::class);
    }
}
