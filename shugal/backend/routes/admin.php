<?php

use App\Http\Controllers\Api\Admin\AccountDeletionRequestController;
use App\Http\Controllers\Api\Admin\ApplicationController;
use App\Http\Controllers\Api\Admin\CandidateController;
use App\Http\Controllers\Api\Admin\InterviewController;
use App\Http\Controllers\Api\Admin\CompanyController;
use App\Http\Controllers\Api\Admin\CountryController;
use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\JobController;
use App\Http\Controllers\Api\Admin\LookupController;
use App\Http\Controllers\Api\Admin\ResumeQuestionController;
use App\Http\Controllers\Api\Admin\SettingController;
use App\Http\Controllers\Api\Admin\TransactionController;
use Illuminate\Support\Facades\Route;

Route::middleware(['auth:sanctum', 'admin'])->prefix('admin')->group(function () {
    Route::get('dashboard/stats', [DashboardController::class, 'stats']);

    Route::get('candidates', [CandidateController::class, 'index']);
    Route::post('candidates', [CandidateController::class, 'store']);
    Route::get('candidates/{candidate}', [CandidateController::class, 'show']);
    Route::put('candidates/{candidate}', [CandidateController::class, 'update']);
    Route::post('candidates/{candidate}', [CandidateController::class, 'update']); // For file uploads
    Route::patch('candidates/{candidate}/status', [CandidateController::class, 'updateStatus']);
    Route::delete('candidates/{candidate}', [CandidateController::class, 'destroy']);

    Route::get('companies', [CompanyController::class, 'index']);
    Route::post('companies', [CompanyController::class, 'store']);
    Route::get('companies/{company}', [CompanyController::class, 'show']);
    Route::put('companies/{company}', [CompanyController::class, 'update']);
    Route::post('companies/{company}', [CompanyController::class, 'update']); // For file uploads
    Route::patch('companies/{company}/status', [CompanyController::class, 'updateStatus']);
    Route::delete('companies/{company}', [CompanyController::class, 'destroy']);
    Route::post('companies/upload/logo', [CompanyController::class, 'uploadLogo']);
    Route::post('companies/upload/license', [CompanyController::class, 'uploadLicense']);

    Route::get('jobs', [JobController::class, 'index']);
    Route::post('jobs', [JobController::class, 'store']);
    Route::get('jobs/{job}', [JobController::class, 'show']);
    Route::put('jobs/{job}', [JobController::class, 'update']);
    Route::delete('jobs/{job}', [JobController::class, 'destroy']);
    Route::get('jobs/{job}/applications', [JobController::class, 'applications']);

    Route::put('applications/{application}', [ApplicationController::class, 'update']);

    Route::post('interviews', [InterviewController::class, 'store']);
    Route::put('interviews/{interview}', [InterviewController::class, 'update']);

    Route::get('transactions', [TransactionController::class, 'index']);
    Route::get('activity-logs', [TransactionController::class, 'activityLogs']);

    Route::get('settings', [SettingController::class, 'index']);
    Route::put('settings', [SettingController::class, 'upsert']);
    Route::post('settings/upload', [SettingController::class, 'upload']);

    Route::get('resume-questions', [ResumeQuestionController::class, 'index']);
    Route::post('resume-questions', [ResumeQuestionController::class, 'store']);
    Route::put('resume-questions/{resumeQuestion}', [ResumeQuestionController::class, 'update']);
    Route::delete('resume-questions/{resumeQuestion}', [ResumeQuestionController::class, 'destroy']);

    Route::get('lookups', [LookupController::class, 'index']);
    Route::post('lookups', [LookupController::class, 'store']);
    Route::put('lookups/{lookup}', [LookupController::class, 'update']);
    Route::delete('lookups/{lookup}', [LookupController::class, 'destroy']);

    Route::get('countries', [CountryController::class, 'index']);
    Route::post('countries', [CountryController::class, 'store']);
    Route::put('countries/{country}', [CountryController::class, 'update']);
    Route::delete('countries/{country}', [CountryController::class, 'destroy']);
    Route::post('countries/upload', [CountryController::class, 'uploadFlag']);

    Route::get('deletion-requests', [AccountDeletionRequestController::class, 'index']);
    Route::get('deletion-requests/{accountDeletionRequest}', [AccountDeletionRequestController::class, 'show']);
    Route::post('deletion-requests/{accountDeletionRequest}/process', [AccountDeletionRequestController::class, 'process']);
});
