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
        Schema::table('job_posts', function (Blueprint $table) {
            $table->string('salary_range')->nullable()->after('location');
            $table->string('hiring_type')->nullable()->after('salary_range');
            $table->string('interview_type')->nullable()->after('hiring_type');
            $table->json('major_ids')->nullable()->after('interview_type');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('job_posts', function (Blueprint $table) {
            $table->dropColumn(['salary_range', 'hiring_type', 'interview_type', 'major_ids']);
        });
    }
};
