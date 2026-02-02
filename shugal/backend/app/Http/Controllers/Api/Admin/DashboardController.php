<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Job;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;

class DashboardController extends Controller
{
    public function stats(): JsonResponse
    {
        $candidateCount = User::where('role', User::ROLE_CANDIDATE)->count();
        $companyCount = User::where('role', User::ROLE_COMPANY)->count();
        $jobCount = Job::count();
        $revenue = Transaction::where('status', 'completed')->sum('amount');

        return response()->json([
            'candidates' => $candidateCount,
            'companies' => $companyCount,
            'jobs' => $jobCount,
            'revenue' => $revenue,
        ]);
    }
}
