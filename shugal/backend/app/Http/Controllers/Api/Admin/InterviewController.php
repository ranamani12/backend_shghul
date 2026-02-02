<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\Job;
use App\Models\Meeting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class InterviewController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'application_id' => ['required', 'exists:applications,id'],
            'candidate_id' => ['required', 'exists:users,id'],
            'job_id' => ['required', 'exists:job_posts,id'],
            'scheduled_at' => ['required', 'date'],
            'meeting_type' => ['sometimes', 'string', 'in:Physical,Online,physical,online,phone'],
            'meeting_link' => ['nullable', 'string'],
            'location' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $job = Job::findOrFail($validated['job_id']);

        $meeting = Meeting::create([
            'candidate_id' => $validated['candidate_id'],
            'company_id' => $job->company_id,
            'job_id' => $validated['job_id'],
            'job_title' => $job->title,
            'scheduled_at' => $validated['scheduled_at'],
            'interview_type' => strtolower($validated['meeting_type'] ?? 'physical'),
            'location' => $validated['meeting_type'] === 'Physical' || $validated['meeting_type'] === 'physical'
                ? ($validated['location'] ?? null)
                : ($validated['meeting_link'] ?? null),
            'notes' => $validated['notes'] ?? null,
            'status' => Meeting::STATUS_REQUESTED,
        ]);

        // Update application with meeting reference
        $application = Application::find($validated['application_id']);
        if ($application) {
            $application->update(['meeting_id' => $meeting->id]);
        }

        return response()->json($meeting->load(['candidate', 'company', 'job']), 201);
    }

    public function update(Request $request, Meeting $interview): JsonResponse
    {
        $validated = $request->validate([
            'scheduled_at' => ['sometimes', 'date'],
            'meeting_type' => ['sometimes', 'string', 'in:Physical,Online,physical,online,phone'],
            'meeting_link' => ['nullable', 'string'],
            'location' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
            'status' => ['sometimes', 'string', 'in:requested,accepted,rejected,completed,cancelled'],
        ]);

        $updateData = [];

        if (isset($validated['scheduled_at'])) {
            // Mark as rescheduled if date changed
            if ($interview->scheduled_at && $interview->scheduled_at->toDateTimeString() !== $validated['scheduled_at']) {
                $updateData['is_rescheduled'] = true;
                $updateData['original_scheduled_at'] = $interview->original_scheduled_at ?? $interview->scheduled_at;
                $updateData['rescheduled_at'] = now();
            }
            $updateData['scheduled_at'] = $validated['scheduled_at'];
        }

        if (isset($validated['meeting_type'])) {
            $updateData['interview_type'] = strtolower($validated['meeting_type']);
        }

        if (isset($validated['location'])) {
            $updateData['location'] = $validated['location'];
        } elseif (isset($validated['meeting_link'])) {
            $updateData['location'] = $validated['meeting_link'];
        }

        if (isset($validated['notes'])) {
            $updateData['notes'] = $validated['notes'];
        }

        if (isset($validated['status'])) {
            $updateData['status'] = $validated['status'];
        }

        $interview->update($updateData);

        return response()->json($interview->load(['candidate', 'company', 'job']));
    }
}
