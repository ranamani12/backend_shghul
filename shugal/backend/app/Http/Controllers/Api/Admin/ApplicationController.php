<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Application;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ApplicationController extends Controller
{
    public function update(Request $request, Application $application): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['sometimes', 'string', 'in:pending,reviewed,shortlisted,interviewed,hired,rejected'],
        ]);

        $application->update($validated);

        return response()->json($application->load(['candidate.candidateProfile', 'job']));
    }
}
