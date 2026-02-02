<?php

namespace App\Services;

use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Http\Request;

class ActivityLogger
{
    public static function log(?User $user, string $action, array $meta = [], ?Request $request = null): void
    {
        $request = $request ?? request();

        ActivityLog::create([
            'user_id' => $user?->id,
            'action' => $action,
            'meta' => $meta,
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);
    }
}
