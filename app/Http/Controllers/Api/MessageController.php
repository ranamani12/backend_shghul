<?php

namespace App\Http\Controllers\Api;

use App\Events\MessageRead;
use App\Events\MessageSent;
use App\Http\Controllers\Controller;
use App\Models\Message;
use App\Models\Notification;
use App\Models\User;
use App\Services\ActivityLogger;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function conversations(Request $request): JsonResponse
    {
        $user = $request->user();

        $messages = Message::query()
            ->where('sender_id', $user->id)
            ->orWhere('receiver_id', $user->id)
            ->orderByDesc('created_at')
            ->with(['sender.candidateProfile', 'sender.companyProfile', 'receiver.candidateProfile', 'receiver.companyProfile'])
            ->get();

        $threads = $messages->map(function (Message $message) use ($user) {
            $other = $message->sender_id === $user->id ? $message->receiver : $message->sender;

            // Count unread messages from this user
            $unreadCount = Message::where('sender_id', $other->id)
                ->where('receiver_id', $user->id)
                ->whereNull('read_at')
                ->count();

            return [
                'user' => $other,
                'last_message' => $message,
                'unread_count' => $unreadCount,
            ];
        })->unique(fn ($thread) => $thread['user']?->id)->values();

        return response()->json($threads);
    }

    public function thread(Request $request, User $user): JsonResponse
    {
        $auth = $request->user();

        $messages = Message::query()
            ->where(function ($builder) use ($auth, $user) {
                $builder->where('sender_id', $auth->id)
                    ->where('receiver_id', $user->id);
            })
            ->orWhere(function ($builder) use ($auth, $user) {
                $builder->where('sender_id', $user->id)
                    ->where('receiver_id', $auth->id);
            })
            ->orderBy('created_at')
            ->with(['sender', 'receiver'])
            ->get();

        // Mark all messages from the other user as read
        Message::where('sender_id', $user->id)
            ->where('receiver_id', $auth->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json($messages);
    }

    public function send(Request $request, User $user): JsonResponse
    {
        $auth = $request->user();

        $validated = $request->validate([
            'content' => ['required', 'string'],
        ]);

        $message = Message::create([
            'sender_id' => $auth->id,
            'receiver_id' => $user->id,
            'content' => $validated['content'],
        ]);

        $message->load(['sender', 'receiver']);

        ActivityLogger::log($auth, 'message.sent', ['to' => $user->id]);

        // Broadcast the message for real-time delivery (if configured)
        try {
            broadcast(new MessageSent($message))->toOthers();
        } catch (\Exception $e) {
            // Broadcasting not configured, skip silently
        }

        // Create notification for new message
        Notification::newMessage($user, [
            'sender_id' => $auth->id,
            'sender_name' => $auth->name,
            'message_preview' => strlen($validated['content']) > 50
                ? substr($validated['content'], 0, 50) . '...'
                : $validated['content'],
        ]);

        return response()->json($message, 201);
    }

    public function markRead(Request $request, Message $message): JsonResponse
    {
        $auth = $request->user();
        if ($message->receiver_id !== $auth->id) {
            return response()->json(['message' => 'Unauthorized.'], 403);
        }

        $message->update(['read_at' => now()]);

        // Broadcast the read status (if configured)
        try {
            broadcast(new MessageRead($message))->toOthers();
        } catch (\Exception $e) {
            // Broadcasting not configured, skip silently
        }

        return response()->json($message);
    }

    /**
     * Mark all messages in a thread as read.
     */
    public function markThreadRead(Request $request, User $user): JsonResponse
    {
        $auth = $request->user();

        $updatedCount = Message::where('sender_id', $user->id)
            ->where('receiver_id', $auth->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'message' => 'Messages marked as read.',
            'count' => $updatedCount,
        ]);
    }

    /**
     * Get unread messages count.
     */
    public function unreadCount(Request $request): JsonResponse
    {
        $user = $request->user();

        $count = Message::where('receiver_id', $user->id)
            ->whereNull('read_at')
            ->count();

        return response()->json(['unread_count' => $count]);
    }
}
