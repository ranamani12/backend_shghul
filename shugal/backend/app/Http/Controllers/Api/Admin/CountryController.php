<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Country;
use App\Models\CountryTranslation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CountryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Country::query()->with('translations')->orderBy('sort_order');

        if ($request->filled('active')) {
            $query->where('is_active', $request->boolean('active'));
        }

        $countries = $query->get()->map(function (Country $country) {
            $translations = $country->translations->mapWithKeys(function (CountryTranslation $translation) {
                return [$translation->locale => $translation->name];
            });

            return [
                'id' => $country->id,
                'code' => $country->code,
                'flag_path' => $country->flag_path,
                'sort_order' => $country->sort_order,
                'is_active' => $country->is_active,
                'translations' => $translations,
            ];
        });

        return response()->json($countries);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $this->validatePayload($request, true);

        $country = Country::create([
            'code' => $validated['code'] ?? null,
            'flag_path' => $validated['flag_path'] ?? null,
            'sort_order' => $validated['sort_order'] ?? 0,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        foreach ($validated['translations'] as $locale => $name) {
            CountryTranslation::create([
                'country_id' => $country->id,
                'locale' => $locale,
                'name' => $name,
            ]);
        }

        return response()->json($country->load('translations'), 201);
    }

    public function update(Request $request, Country $country): JsonResponse
    {
        $validated = $this->validatePayload($request, false, $country);

        $country->update([
            'code' => $validated['code'] ?? $country->code,
            'flag_path' => $validated['flag_path'] ?? $country->flag_path,
            'sort_order' => $validated['sort_order'] ?? $country->sort_order,
            'is_active' => $validated['is_active'] ?? $country->is_active,
        ]);

        if (!empty($validated['translations'])) {
            foreach ($validated['translations'] as $locale => $name) {
                CountryTranslation::updateOrCreate(
                    ['country_id' => $country->id, 'locale' => $locale],
                    ['name' => $name]
                );
            }
        }

        return response()->json($country->load('translations'));
    }

    public function destroy(Country $country): JsonResponse
    {
        $country->delete();

        return response()->json(['message' => 'Deleted']);
    }

    public function uploadFlag(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'flag' => ['required', 'file', 'mimes:png,jpg,jpeg,svg,webp', 'max:2048'],
        ]);

        $path = $validated['flag']->store('countries', 'public');
        $url = Storage::disk('public')->url($path);

        return response()->json(['url' => $url]);
    }

    private function validatePayload(Request $request, bool $isCreate, ?Country $country = null): array
    {
        $rules = [
            'code' => ['nullable', 'string', 'max:10', 'unique:countries,code'],
            'flag_path' => ['nullable', 'string', 'max:255'],
            'sort_order' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
            'translations' => ['required', 'array'],
            'translations.en' => ['required', 'string', 'max:255'],
            'translations.ar' => ['required', 'string', 'max:255'],
        ];

        if (!$isCreate) {
            $rules['translations'][0] = 'sometimes';
            $rules['translations.en'][0] = 'sometimes';
            $rules['translations.ar'][0] = 'sometimes';
            $rules['code'][3] = 'unique:countries,code,'.($country?->id ?? 'NULL');
        }

        return $request->validate($rules, [
            'code.unique' => 'Country code already exists.',
        ]);
    }
}
