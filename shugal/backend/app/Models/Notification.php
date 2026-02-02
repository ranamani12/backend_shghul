<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notification extends Model
{
    use HasFactory;

    // Notification types
    public const TYPE_MEETING_SCHEDULED = 'meeting_scheduled';
    public const TYPE_MEETING_RESCHEDULED = 'meeting_rescheduled';
    public const TYPE_MEETING_CANCELLED = 'meeting_cancelled';
    public const TYPE_MEETING_REMINDER = 'meeting_reminder';
    public const TYPE_JOB_APPLIED = 'job_applied';
    public const TYPE_APPLICATION_VIEWED = 'application_viewed';
    public const TYPE_APPLICATION_ACCEPTED = 'application_accepted';
    public const TYPE_APPLICATION_REJECTED = 'application_rejected';
    public const TYPE_CANDIDATE_UNLOCKED = 'candidate_unlocked';
    public const TYPE_NEW_JOB_POSTED = 'new_job_posted';
    public const TYPE_PROFILE_VIEWED = 'profile_viewed';
    public const TYPE_NEW_MESSAGE = 'new_message';
    public const TYPE_SYSTEM = 'system';

    protected $fillable = [
        'user_id',
        'type',
        'title',
        'message',
        'data',
        'read_at',
    ];

    protected $casts = [
        'data' => 'array',
        'read_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isRead(): bool
    {
        return $this->read_at !== null;
    }

    public function markAsRead(): void
    {
        if (!$this->isRead()) {
            $this->update(['read_at' => now()]);
        }
    }

    public function markAsUnread(): void
    {
        $this->update(['read_at' => null]);
    }

    /**
     * Create a notification for a user
     */
    public static function createFor(
        User $user,
        string $type,
        string $title,
        string $message,
        ?array $data = null
    ): self {
        return self::create([
            'user_id' => $user->id,
            'type' => $type,
            'title' => $title,
            'message' => $message,
            'data' => $data,
        ]);
    }

    /**
     * Create meeting scheduled notification
     */
    public static function meetingScheduled(User $user, array $interviewData): self
    {
        return self::createFor(
            $user,
            self::TYPE_MEETING_SCHEDULED,
            'Interview Scheduled',
            "An interview has been scheduled for {$interviewData['date']} at {$interviewData['time']}.",
            $interviewData
        );
    }

    /**
     * Create meeting rescheduled notification
     */
    public static function meetingRescheduled(User $user, array $interviewData): self
    {
        return self::createFor(
            $user,
            self::TYPE_MEETING_RESCHEDULED,
            'Interview Rescheduled',
            "Your interview has been rescheduled to {$interviewData['date']} at {$interviewData['time']}.",
            $interviewData
        );
    }

    /**
     * Create meeting cancelled notification
     */
    public static function meetingCancelled(User $user, array $interviewData): self
    {
        return self::createFor(
            $user,
            self::TYPE_MEETING_CANCELLED,
            'Interview Cancelled',
            'Your scheduled interview has been cancelled.',
            $interviewData
        );
    }

    /**
     * Create job applied notification (for company)
     */
    public static function jobApplied(User $company, array $applicationData): self
    {
        $candidateName = $applicationData['candidate_name'] ?? 'A candidate';
        $jobTitle = $applicationData['job_title'] ?? 'your job posting';

        return self::createFor(
            $company,
            self::TYPE_JOB_APPLIED,
            'New Job Application',
            "{$candidateName} has applied for {$jobTitle}.",
            $applicationData
        );
    }

    /**
     * Create application status notification (for candidate)
     */
    public static function applicationAccepted(User $candidate, array $applicationData): self
    {
        $jobTitle = $applicationData['job_title'] ?? 'a job';

        return self::createFor(
            $candidate,
            self::TYPE_APPLICATION_ACCEPTED,
            'Application Accepted',
            "Congratulations! Your application for {$jobTitle} has been accepted.",
            $applicationData
        );
    }

    /**
     * Create application rejected notification (for candidate)
     */
    public static function applicationRejected(User $candidate, array $applicationData): self
    {
        $jobTitle = $applicationData['job_title'] ?? 'a job';

        return self::createFor(
            $candidate,
            self::TYPE_APPLICATION_REJECTED,
            'Application Update',
            "Your application for {$jobTitle} was not selected at this time.",
            $applicationData
        );
    }

    /**
     * Create candidate unlocked notification (for candidate)
     */
    public static function candidateUnlocked(User $candidate, array $companyData): self
    {
        $companyName = $companyData['company_name'] ?? 'A company';

        return self::createFor(
            $candidate,
            self::TYPE_CANDIDATE_UNLOCKED,
            'Profile Unlocked',
            "{$companyName} has unlocked your profile and can now view your full details.",
            $companyData
        );
    }

    /**
     * Create new message notification
     */
    public static function newMessage(User $user, array $messageData): self
    {
        $senderName = $messageData['sender_name'] ?? 'Someone';

        return self::createFor(
            $user,
            self::TYPE_NEW_MESSAGE,
            'New Message',
            "{$senderName} sent you a message.",
            $messageData
        );
    }
}
