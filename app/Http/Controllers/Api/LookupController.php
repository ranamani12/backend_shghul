<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lookup;
use App\Models\LookupTranslation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LookupController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'type' => ['required', 'in:'.implode(',', $this->allowedTypes())],
            'locale' => ['nullable', 'string', 'max:10'],
        ]);

        $locale = $validated['locale'] ?? 'en';

        $lookups = Lookup::query()
            ->with('translations')
            ->where('type', $validated['type'])
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get()
            ->map(function (Lookup $lookup) use ($locale) {
                $translations = $lookup->translations->mapWithKeys(function (LookupTranslation $translation) {
                    return [$translation->locale => $translation->name];
                });

                $name = $translations[$locale]
                    ?? $translations['en']
                    ?? $translations->first()
                    ?? '';

                return [
                    'id' => $lookup->id,
                    'type' => $lookup->type,
                    'name' => $name,
                    'locale' => $locale,
                ];
            });

        return response()->json($lookups);
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
