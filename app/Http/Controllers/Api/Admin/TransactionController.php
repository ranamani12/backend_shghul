<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use App\Models\User;
use App\Models\ActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Transaction::query()->with('user');

        if ($request->filled('user_type')) {
            $role = $request->string('user_type');
            if (in_array($role, [User::ROLE_CANDIDATE, User::ROLE_COMPANY, User::ROLE_ADMIN], true)) {
                $query->whereHas('user', fn ($builder) => $builder->where('role', $role));
            }
        }

        if ($request->filled('method')) {
            $query->where('method', $request->string('method'));
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->date('from'));
        }

        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->date('to'));
        }

        return response()->json($query->orderByDesc('created_at')->paginate($request->integer('per_page', 20)));
    }

    public function activityLogs(Request $request): JsonResponse
    {
        $query = ActivityLog::query()->with('user');

        if ($request->filled('action')) {
            $query->where('action', 'like', '%' . $request->string('action') . '%');
        }

        if ($request->filled('user_id')) {
            $query->where('user_id', $request->integer('user_id'));
        }

        $paginated = $query->orderByDesc('created_at')->paginate($request->integer('per_page', 20));

        // Collect all user IDs from meta fields to resolve names
        $userIds = collect();
        $jobIds = collect();
        $applicationIds = collect();

        foreach ($paginated->items() as $log) {
            $meta = $log->meta ?? [];
            foreach (['to', 'from', 'user_id', 'candidate_id', 'company_id'] as $key) {
                if (isset($meta[$key]) && is_numeric($meta[$key])) {
                    $userIds->push($meta[$key]);
                }
            }
            if (isset($meta['job_id']) && is_numeric($meta['job_id'])) {
                $jobIds->push($meta['job_id']);
            }
            if (isset($meta['application_id']) && is_numeric($meta['application_id'])) {
                $applicationIds->push($meta['application_id']);
            }
        }

        // Load all related data at once
        $users = User::whereIn('id', $userIds->unique())->pluck('name', 'id');
        $jobs = \App\Models\Job::whereIn('id', $jobIds->unique())->pluck('title', 'id');
        $applications = \App\Models\Application::whereIn('id', $applicationIds->unique())
            ->with('candidate:id,name', 'job:id,title')
            ->get()
            ->keyBy('id');

        // Enrich meta with resolved names
        $paginated->getCollection()->transform(function ($log) use ($users, $jobs, $applications) {
            $meta = $log->meta ?? [];
            $resolved = [];

            foreach ($meta as $key => $value) {
                if (in_array($key, ['to', 'from', 'user_id', 'candidate_id', 'company_id']) && is_numeric($value)) {
                    $resolved[$key] = $users->get($value) ?? "ID: {$value}";
                } elseif ($key === 'job_id' && is_numeric($value)) {
                    $resolved[$key] = $jobs->get($value) ?? "ID: {$value}";
                } elseif ($key === 'application_id' && is_numeric($value)) {
                    $app = $applications->get($value);
                    if ($app) {
                        $resolved[$key] = ($app->candidate->name ?? 'Unknown') . ' → ' . ($app->job->title ?? 'Unknown Job');
                    } else {
                        $resolved[$key] = "ID: {$value}";
                    }
                } else {
                    $resolved[$key] = $value;
                }
            }

            $log->meta = $resolved;
            return $log;
        });

        return response()->json($paginated);
    }
}
