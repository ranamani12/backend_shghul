<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class SettingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Setting::query();

        if ($request->filled('group')) {
            $query->where('group', $request->string('group'));
        }

        return response()->json($query->orderBy('group')->orderBy('key')->get());
    }

    public function upsert(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'settings' => ['required', 'array'],
            'settings.*.key' => ['required', 'string'],
            'settings.*.value' => ['nullable'],
            'settings.*.group' => ['sometimes', 'string'],
            'settings.*.description' => ['sometimes', 'string'],
        ]);

        $updated = collect($validated['settings'])->map(function (array $setting) {
            return Setting::updateOrCreate(
                ['key' => $setting['key']],
                [
                    'group' => $setting['group'] ?? 'general',
                    'value' => $setting['value'] ?? null,
                    'description' => $setting['description'] ?? null,
                ]
            );
        });

        return response()->json($updated);
    }

    public function upload(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'key' => ['required', 'in:app_logo,app_favicon,app_logo_light,app_logo_dark'],
            'file' => ['required', 'file', 'mimes:png,jpg,jpeg,svg,ico'],
        ]);

        $file = $validated['file'];
        $extension = $file->getClientOriginalExtension();
        $filename = $validated['key'].'-'.Str::uuid().'.'.$extension;
        $path = $file->storeAs('branding', $filename, 'public');

        $url = Storage::disk('public')->url($path);

        $descriptions = [
            'app_logo' => 'Application logo',
            'app_favicon' => 'Application favicon',
            'app_logo_light' => 'Logo for light theme',
            'app_logo_dark' => 'Logo for dark theme',
        ];

        $setting = Setting::updateOrCreate(
            ['key' => $validated['key']],
            [
                'group' => 'branding',
                'value' => $url,
                'description' => $descriptions[$validated['key']] ?? 'Branding asset',
            ]
        );

        return response()->json([
            'setting' => $setting,
            'url' => $url,
        ]);
    }
}
