<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Lookup;
use App\Models\LookupTranslation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LookupController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Lookup::query()->with('translations')->orderBy('sort_order');

        if ($request->filled('type')) {
            $query->where('type', $request->string('type'));
        }

        $lookups = $query->get()->map(function (Lookup $lookup) {
            $translations = $lookup->translations->mapWithKeys(function (LookupTranslation $translation) {
                return [$translation->locale => $translation->name];
            });

            return [
                'id' => $lookup->id,
                'type' => $lookup->type,
                'sort_order' => $lookup->sort_order,
                'is_active' => $lookup->is_active,
                'translations' => $translations,
            ];
        });

        return response()->json($lookups);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request);

        $lookup = Lookup::create([
            'type' => $validated['type'],
            'sort_order' => $validated['sort_order'] ?? 0,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        foreach ($validated['translations'] as $locale => $name) {
            LookupTranslation::create([
                'lookup_id' => $lookup->id,
                'locale' => $locale,
                'name' => $name,
            ]);
        }

        return response()->json($lookup->load('translations'), 201);
    }

    public function update(Request $request, Lookup $lookup): JsonResponse
    {
        $validated = $this->validatePayload($request, false);

        $lookup->update([
            'type' => $validated['type'] ?? $lookup->type,
            'sort_order' => $validated['sort_order'] ?? $lookup->sort_order,
            'is_active' => $validated['is_active'] ?? $lookup->is_active,
        ]);

        if (!empty($validated['translations'])) {
            foreach ($validated['translations'] as $locale => $name) {
                LookupTranslation::updateOrCreate(
                    ['lookup_id' => $lookup->id, 'locale' => $locale],
                    ['name' => $name]
                );
            }
        }

        return response()->json($lookup->load('translations'));
    }

    public function destroy(Lookup $lookup): JsonResponse
    {
        $lookup->delete();

        return response()->json(['message' => 'Deleted']);
    }

    private function validatePayload(Request $request, bool $isCreate = true): array
    {
        $rules = [
            'type' => ['required', 'in:'.implode(',', $this->allowedTypes())],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
            'translations' => ['required', 'array'],
            'translations.en' => ['required', 'string', 'max:255'],
            'translations.ar' => ['required', 'string', 'max:255'],
        ];

        if (!$isCreate) {
            $rules['type'][0] = 'sometimes';
            $rules['translations'][0] = 'sometimes';
            $rules['translations.en'][0] = 'sometimes';
            $rules['translations.ar'][0] = 'sometimes';
        }

        return $request->validate($rules);
    }

    private function allowedTypes(): array
    {
        return [
            Lookup::TYPE_MAJOR,
            Lookup::TYPE_EXPERIENCE_YEAR,
            Lookup::TYPE_EDUCATION_LEVEL,
        ];
    }
}
