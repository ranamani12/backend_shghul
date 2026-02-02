<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Meeting;
use App\Models\Notification;
use App\Models\User;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MeetingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Meeting::query()
            ->with(['candidate.candidateProfile', 'company.companyProfile', 'job'])
            ->orderByDesc('scheduled_at');

        if ($user->role === User::ROLE_CANDIDATE) {
            $query->where('candidate_id', $user->id);
        } elseif ($user->role === User::ROLE_COMPANY) {
            $query->where('company_id', $user->id);
        }

        // Filter by status if provided
        if ($request->has('status')) {
            $query->where('status', $request->input('status'));
        }

        // Filter by date range if provided
        if ($request->has('from_date')) {
            $query->whereDate('scheduled_at', '>=', $request->input('from_date'));
        }
        if ($request->has('to_date')) {
            $query->whereDate('scheduled_at', '<=', $request->input('to_date'));
        }

        return response()->json($query->paginate($request->integer('per_page', 20)));
    }

    public function store(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'candidate_id' => ['nullable', 'exists:users,id'],
            'company_id' => ['nullable', 'exists:users,id'],
            'scheduled_at' => ['nullable', 'date'],
            'interview_type' => ['nullable', 'in:physical,online,phone'],
            'location' => ['nullable', 'string', 'max:500'],
            'job_title' => ['nullable', 'string', 'max:255'],
            'job_id' => ['nullable', 'integer', 'exists:job_posts,id'],
            'notes' => ['nullable', 'string'],
        ]);

        if ($user->role === User::ROLE_CANDIDATE) {
            $validated['candidate_id'] = $user->id;
        }

        if ($user->role === User::ROLE_COMPANY) {
            $validated['company_id'] = $user->id;
        }

        if (empty($validated['candidate_id']) || empty($validated['company_id'])) {
            return response()->json(['message' => 'Candidate and company required.'], 422);
        }

        $meeting = Meeting::create([
            'candidate_id' => $validated['candidate_id'],
            'company_id' => $validated['company_id'],
            'scheduled_at' => $validated['scheduled_at'] ?? null,
            'interview_type' => $validated['interview_type'] ?? Meeting::TYPE_PHYSICAL,
            'location' => $validated['location'] ?? null,
            'job_title' => $validated['job_title'] ?? null,
            'job_id' => $validated['job_id'] ?? null,
            'notes' => $validated['notes'] ?? null,
            'status' => Meeting::STATUS_REQUESTED,
        ]);

        $meeting->load(['candidate.candidateProfile', 'company.companyProfile', 'job']);

        ActivityLogger::log($user, 'meeting.requested', ['meeting_id' => $meeting->id]);

        // Send notification to the other party
        $scheduledDate = $meeting->scheduled_at ? $meeting->scheduled_at->format('M d, Y') : 'TBD';
        $scheduledTime = $meeting->scheduled_at ? $meeting->scheduled_at->format('h:i A') : 'TBD';

        $interviewData = [
            'meeting_id' => $meeting->id,
            'job_id' => $meeting->job_id,
            'job_title' => $meeting->job_title,
            'date' => $scheduledDate,
            'time' => $scheduledTime,
            'interview_type' => $meeting->interview_type,
            'location' => $meeting->location,
        ];

        if ($user->role === User::ROLE_COMPANY) {
            // Notify candidate
            $candidate = User::find($meeting->candidate_id);
            if ($candidate) {
                Notification::meetingScheduled($candidate, $interviewData);
            }
        } else {
            // Notify company
            $company = User::find($meeting->company_id);
            if ($company) {
                Notification::meetingScheduled($company, $interviewData);
            }
        }

        return response()->json($meeting, 201);
    }

    public function update(Request $request, Meeting $meeting): JsonResponse
    {
        $user = $request->user();
        if ($user->id !== $meeting->candidate_id && $user->id !== $meeting->company_id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $validated = $request->validate([
            'status' => ['sometimes', 'in:requested,accepted,rejected,completed,cancelled'],
            'scheduled_at' => ['nullable', 'date'],
            'interview_type' => ['nullable', 'in:physical,online,phone'],
            'location' => ['nullable', 'string', 'max:500'],
            'job_title' => ['nullable', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
            'reschedule_reason' => ['nullable', 'string', 'max:500'],
        ]);

        // Track rescheduling
        $isRescheduling = isset($validated['scheduled_at']) &&
                          $meeting->scheduled_at &&
                          $validated['scheduled_at'] !== $meeting->scheduled_at->toIso8601String();

        if ($isRescheduling) {
            // Store original time on first reschedule
            if (!$meeting->is_rescheduled) {
                $validated['original_scheduled_at'] = $meeting->scheduled_at;
            }
            $validated['is_rescheduled'] = true;
            $validated['rescheduled_at'] = now();

            ActivityLogger::log($user, 'meeting.rescheduled', [
                'meeting_id' => $meeting->id,
                'old_time' => $meeting->scheduled_at,
                'new_time' => $validated['scheduled_at'],
            ]);
        }

        $meeting->update($validated);

        // Log status changes
        if (isset($validated['status'])) {
            ActivityLogger::log($user, 'meeting.status_changed', [
                'meeting_id' => $meeting->id,
                'status' => $validated['status'],
            ]);
        }

        $meeting->load(['candidate.candidateProfile', 'company.companyProfile', 'job']);

        // Send notifications for reschedule or status changes
        $scheduledDate = $meeting->scheduled_at ? $meeting->scheduled_at->format('M d, Y') : 'TBD';
        $scheduledTime = $meeting->scheduled_at ? $meeting->scheduled_at->format('h:i A') : 'TBD';

        $interviewData = [
            'meeting_id' => $meeting->id,
            'job_id' => $meeting->job_id,
            'job_title' => $meeting->job_title,
            'date' => $scheduledDate,
            'time' => $scheduledTime,
            'interview_type' => $meeting->interview_type,
            'location' => $meeting->location,
        ];

        // Determine who to notify (the other party)
        $notifyUserId = $user->id === $meeting->candidate_id
            ? $meeting->company_id
            : $meeting->candidate_id;
        $notifyUser = User::find($notifyUserId);

        if ($notifyUser) {
            if ($isRescheduling) {
                Notification::meetingRescheduled($notifyUser, $interviewData);
            }
        }

        return response()->json($meeting);
    }

    public function show(Request $request, Meeting $meeting): JsonResponse
    {
        $user = $request->user();
        if ($user->id !== $meeting->candidate_id && $user->id !== $meeting->company_id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        return response()->json($meeting->load(['candidate.candidateProfile', 'company.companyProfile', 'job']));
    }

    /**
     * Cancel a meeting.
     */
    public function cancel(Request $request, Meeting $meeting): JsonResponse
    {
        $user = $request->user();
        if ($user->id !== $meeting->candidate_id && $user->id !== $meeting->company_id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        if ($meeting->status === Meeting::STATUS_CANCELLED) {
            return response()->json(['message' => 'Meeting is already cancelled.'], 422);
        }

        if ($meeting->status === Meeting::STATUS_COMPLETED) {
            return response()->json(['message' => 'Cannot cancel a completed meeting.'], 422);
        }

        $validated = $request->validate([
            'reason' => ['nullable', 'string', 'max:500'],
        ]);

        $meeting->update([
            'status' => Meeting::STATUS_CANCELLED,
            'notes' => $validated['reason'] ?? $meeting->notes,
        ]);

        ActivityLogger::log($user, 'meeting.cancelled', [
            'meeting_id' => $meeting->id,
            'reason' => $validated['reason'] ?? null,
        ]);

        $meeting->load(['candidate.candidateProfile', 'company.companyProfile', 'job']);

        // Send notification to the other party
        $interviewData = [
            'meeting_id' => $meeting->id,
            'job_id' => $meeting->job_id,
            'job_title' => $meeting->job_title,
            'reason' => $validated['reason'] ?? null,
        ];

        $notifyUserId = $user->id === $meeting->candidate_id
            ? $meeting->company_id
            : $meeting->candidate_id;
        $notifyUser = User::find($notifyUserId);

        if ($notifyUser) {
            Notification::meetingCancelled($notifyUser, $interviewData);
        }

        return response()->json($meeting);
    }
}
