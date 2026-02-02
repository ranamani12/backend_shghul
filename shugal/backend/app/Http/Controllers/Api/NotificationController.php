<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Get all notifications for the authenticated user
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = Notification::query()
            ->where('user_id', $user->id)
            ->orderByDesc('created_at');

        // Filter by read status
        if ($request->has('unread_only') && $request->boolean('unread_only')) {
            $query->whereNull('read_at');
        }

        // Filter by type
        if ($request->filled('type')) {
            $query->where('type', $request->string('type'));
        }

        $notifications = $query->paginate($request->integer('per_page', 20));

        return response()->json($notifications);
    }

    /**
     * Get unread notification count
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();

        $count = Notification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();

        return response()->json(['unread_count' => $count]);
    }

    /**
     * Mark a notification as read
     */
    public function markAsRead(Request $request, Notification $notification): JsonResponse
    {
        $user = $request->user();

        if ($notification->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $notification->markAsRead();

        return response()->json($notification);
    }

    /**
     * Mark all notifications as read
     */
    public function markAllAsRead(Request $request): JsonResponse
    {
        $user = $request->user();

        Notification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'All notifications marked as read.']);
    }

    /**
     * Delete a notification
     */
    public function destroy(Request $request, Notification $notification): JsonResponse
    {
        $user = $request->user();

        if ($notification->user_id !== $user->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $notification->delete();

        return response()->json(['message' => 'Notification deleted.']);
    }

    /**
     * Delete all notifications
     */
    public function destroyAll(Request $request): JsonResponse
    {
        $user = $request->user();

        Notification::query()
            ->where('user_id', $user->id)
            ->delete();

        return response()->json(['message' => 'All notifications deleted.']);
    }

    /**
     * Create a test notification (for development)
     */
    public function createTest(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'type' => ['required', 'string'],
            'title' => ['required', 'string', 'max:255'],
            'message' => ['required', 'string'],
            'data' => ['nullable', 'array'],
        ]);

        $notification = Notification::create([
            'user_id' => $user->id,
            'type' => $validated['type'],
            'title' => $validated['title'],
            'message' => $validated['message'],
            'data' => $validated['data'] ?? null,
        ]);

        return response()->json($notification, 201);
    }
}
