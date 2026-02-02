<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Application extends Model
{
    protected $fillable = [
        'job_id',
        'candidate_id',
        'status',
        'cover_letter',
        'is_paid',
        'applied_at',
    ];

    protected $casts = [
        'is_paid' => 'boolean',
        'applied_at' => 'datetime',
    ];

    public function job(): BelongsTo
    {
        return $this->belongsTo(Job::class);
    }

    public function candidate(): BelongsTo
    {
        return $this->belongsTo(User::class, 'candidate_id');
    }

    public function interview(): HasOne
    {
        return $this->hasOne(Meeting::class, 'candidate_id', 'candidate_id')
            ->whereColumn('meetings.job_id', 'applications.job_id');
    }
}
