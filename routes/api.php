<?php

use App\Http\Controllers\Api\AccountDeletionController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CandidateController as CandidateApiController;
use App\Http\Controllers\Api\CompanyController as CompanyApiController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\MeetingController;
use App\Http\Controllers\Api\PublicController;
use Illuminate\Support\Facades\Route;

Route::get('jobs', [PublicController::class, 'jobs']);
Route::get('jobs/{job}', [PublicController::class, 'job']);
Route::get('candidates', [PublicController::class, 'candidates']);
Route::get('candidates/public/{slug}', [PublicController::class, 'candidatePublic']);
Route::get('settings', [PublicController::class, 'settings']);

// Account Deletion Request (Public - no auth required)
Route::post('account-deletion-request', [AccountDeletionController::class, 'store']);

Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register']);
    Route::post('login', [AuthController::class, 'login']);
    Route::post('admin/login', [AuthController::class, 'adminLogin']);
    Route::post('otp/request', [AuthController::class, 'requestOtp']);
    Route::post('otp/resend', [AuthController::class, 'requestOtp']);
    Route::post('otp/verify', [AuthController::class, 'verifyOtp']);
    Route::post('password/reset', [AuthController::class, 'resetPassword']);
});

Route::middleware('auth:sanctum')->prefix('auth')->group(function () {
    Route::post('logout', [AuthController::class, 'logout']);
    Route::get('me', [AuthController::class, 'me']);
});

require __DIR__.'/admin.php';
require __DIR__.'/mobile.php';
