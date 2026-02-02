<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Meeting extends Model
{
    // Interview types
    public const TYPE_PHYSICAL = 'physical';
    public const TYPE_ONLINE = 'online';
    public const TYPE_PHONE = 'phone';

    // Meeting statuses
    public const STATUS_REQUESTED = 'requested';
    public const STATUS_ACCEPTED = 'accepted';
    public const STATUS_REJECTED = 'rejected';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'candidate_id',
        'company_id',
        'status',
        'scheduled_at',
        'interview_type',
        'location',
        'job_title',
        'job_id',
        'notes',
        'is_rescheduled',
        'rescheduled_at',
        'reschedule_reason',
        'original_scheduled_at',
    ];

    protected $casts = [
        'scheduled_at' => 'datetime',
        'rescheduled_at' => 'datetime',
        'original_scheduled_at' => 'datetime',
        'is_rescheduled' => 'boolean',
    ];

    public function candidate(): BelongsTo
    {
        return $this->belongsTo(User::class, 'candidate_id');
    }

    public function company(): BelongsTo
    {
        return $this->belongsTo(User::class, 'company_id');
    }

    public function job(): BelongsTo
    {
        return $this->belongsTo(Job::class);
    }

    /**
     * Get available interview types.
     */
    public static function getInterviewTypes(): array
    {
        return [
            self::TYPE_PHYSICAL,
            self::TYPE_ONLINE,
            self::TYPE_PHONE,
        ];
    }

    /**
     * Get available statuses.
     */
    public static function getStatuses(): array
    {
        return [
            self::STATUS_REQUESTED,
            self::STATUS_ACCEPTED,
            self::STATUS_REJECTED,
            self::STATUS_COMPLETED,
            self::STATUS_CANCELLED,
        ];
    }
}
