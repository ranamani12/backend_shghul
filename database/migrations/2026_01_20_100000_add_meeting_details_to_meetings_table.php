<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('meetings', function (Blueprint $table) {
            // Interview type: physical, online, phone
            $table->string('interview_type')->default('physical')->after('scheduled_at');

            // Location for physical interviews or meeting link for online
            $table->string('location')->nullable()->after('interview_type');

            // Job position being interviewed for
            $table->string('job_title')->nullable()->after('location');

            // Foreign key to job if applicable
            $table->foreignId('job_id')->nullable()->after('job_title')->constrained('jobs')->nullOnDelete();

            // Rescheduling tracking
            $table->boolean('is_rescheduled')->default(false)->after('notes');
            $table->timestamp('rescheduled_at')->nullable()->after('is_rescheduled');
            $table->text('reschedule_reason')->nullable()->after('rescheduled_at');

            // Original scheduled time (before rescheduling)
            $table->timestamp('original_scheduled_at')->nullable()->after('reschedule_reason');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('meetings', function (Blueprint $table) {
            $table->dropForeign(['job_id']);
            $table->dropColumn([
                'interview_type',
                'location',
                'job_title',
                'job_id',
                'is_rescheduled',
                'rescheduled_at',
                'reschedule_reason',
                'original_scheduled_at',
            ]);
        });
    }
};
