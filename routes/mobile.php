<?php

use App\Http\Controllers\Api\CandidateController as CandidateApiController;
use App\Http\Controllers\Api\CompanyController as CompanyApiController;
use App\Http\Controllers\Api\CountryController;
use App\Http\Controllers\Api\LookupController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\MeetingController;
use App\Http\Controllers\Api\NotificationController;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Route;

Route::prefix('mobile')->group(function () {
    Route::get('countries', [CountryController::class, 'index']);
    Route::get('lookups', [LookupController::class, 'index']);
});

Route::middleware('auth:sanctum')->prefix('mobile')->group(function () {
    Route::prefix('candidate')->group(function () {
        Route::get('profile', [CandidateApiController::class, 'profile']);
        Route::put('profile', [CandidateApiController::class, 'updateProfile']);
        Route::post('profile/image', [CandidateApiController::class, 'uploadProfileImage']);
        Route::post('profile/cv', [CandidateApiController::class, 'uploadCv']);
        Route::put('password', [CandidateApiController::class, 'changePassword']);
        Route::post('activate', [CandidateApiController::class, 'activate']);
        Route::get('applications', [CandidateApiController::class, 'applications']);
        Route::post('jobs/{job}/apply', [CandidateApiController::class, 'apply']);
    });

    Route::prefix('company')->group(function () {
        Route::get('dashboard', [CompanyApiController::class, 'dashboard']);
        Route::get('profile', [CompanyApiController::class, 'profile']);
        Route::put('profile', [CompanyApiController::class, 'updateProfile']);
        Route::post('profile/logo', [CompanyApiController::class, 'uploadLogo']);
        Route::post('profile/license', [CompanyApiController::class, 'uploadLicense']);
        Route::get('jobs', [CompanyApiController::class, 'jobs']);
        Route::post('jobs', [CompanyApiController::class, 'storeJob']);
        Route::put('jobs/{job}', [CompanyApiController::class, 'updateJob']);
        Route::delete('jobs/{job}', [CompanyApiController::class, 'destroyJob']);
        Route::get('jobs/{job}/applicants', [CompanyApiController::class, 'applicants']);
        Route::get('applications', [CompanyApiController::class, 'allApplications']);
        Route::get('candidates', [CompanyApiController::class, 'candidates']);
        Route::post('candidates/{candidate}/unlock', [CompanyApiController::class, 'unlock']);
    });

    // Messages / Chat
    Route::get('messages', [MessageController::class, 'conversations']);
    Route::get('messages/unread-count', [MessageController::class, 'unreadCount']);
    Route::get('messages/{user}', [MessageController::class, 'thread']);
    Route::post('messages/{user}', [MessageController::class, 'send']);
    Route::post('messages/{user}/mark-read', [MessageController::class, 'markThreadRead']);
    Route::patch('messages/{message}/read', [MessageController::class, 'markRead']);

    Route::get('meetings', [MeetingController::class, 'index']);
    Route::post('meetings', [MeetingController::class, 'store']);
    Route::get('meetings/{meeting}', [MeetingController::class, 'show']);
    Route::patch('meetings/{meeting}', [MeetingController::class, 'update']);
    Route::post('meetings/{meeting}/cancel', [MeetingController::class, 'cancel']);

    // Notifications
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::get('notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('notifications/mark-all-read', [NotificationController::class, 'markAllAsRead']);
    Route::delete('notifications/delete-all', [NotificationController::class, 'destroyAll']);
    Route::post('notifications/{notification}/read', [NotificationController::class, 'markAsRead']);
    Route::delete('notifications/{notification}', [NotificationController::class, 'destroy']);

    // Broadcasting auth for WebSocket private channels
    Route::post('broadcasting/auth', function () {
        return Broadcast::auth(request());
    });
});
