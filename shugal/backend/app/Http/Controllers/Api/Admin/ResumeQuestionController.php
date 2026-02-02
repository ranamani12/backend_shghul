<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ResumeQuestion;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ResumeQuestionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = ResumeQuestion::query();

        if ($request->filled('active')) {
            $query->where('is_active', $request->boolean('active'));
        }

        return response()->json($query->orderBy('sort_order')->get());
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'question' => ['required', 'string'],
            'type' => ['sometimes', 'string'],
            'options' => ['nullable', 'array'],
            'sort_order' => ['sometimes', 'integer'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $question = ResumeQuestion::create($validated);

        return response()->json($question, 201);
    }

    public function update(Request $request, ResumeQuestion $resumeQuestion): JsonResponse
    {
        $validated = $request->validate([
            'question' => ['sometimes', 'string'],
            'type' => ['sometimes', 'string'],
            'options' => ['nullable', 'array'],
            'sort_order' => ['sometimes', 'integer'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $resumeQuestion->update($validated);

        return response()->json($resumeQuestion);
    }

    public function destroy(ResumeQuestion $resumeQuestion): JsonResponse
    {
        $resumeQuestion->delete();

        return response()->json(['message' => 'Question deleted.']);
    }
}
