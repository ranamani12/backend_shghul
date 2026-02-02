<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Country;
use App\Models\CountryTranslation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CountryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'locale' => ['nullable', 'string', 'max:10'],
        ]);

        $locale = $validated['locale'] ?? 'en';

        $countries = Country::query()
            ->with('translations')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get()
            ->map(function (Country $country) use ($locale) {
                $translations = $country->translations->mapWithKeys(function (CountryTranslation $translation) {
                    return [$translation->locale => $translation->name];
                });

                $name = $translations[$locale]
                    ?? $translations['en']
                    ?? $translations->first()
                    ?? '';

                return [
                    'id' => $country->id,
                    'code' => $country->code,
                    'name' => $name,
                    'flag_path' => $country->flag_path,
                    'locale' => $locale,
                ];
            });

        return response()->json($countries);
    }
}
