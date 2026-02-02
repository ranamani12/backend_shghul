<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

// Private channel for user's chat messages
Broadcast::channel('chat.{userId}', function (User $user, int $userId) {
    return $user->id === $userId;
});

// Private channel for user notifications
Broadcast::channel('notifications.{userId}', function (User $user, int $userId) {
    return $user->id === $userId;
});
