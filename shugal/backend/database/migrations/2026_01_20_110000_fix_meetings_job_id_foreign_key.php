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
            // Drop the incorrect foreign key constraint
            $table->dropForeign(['job_id']);

            // Add the correct foreign key constraint pointing to job_posts table
            $table->foreign('job_id')
                  ->references('id')
                  ->on('job_posts')
                  ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('meetings', function (Blueprint $table) {
            // Drop the corrected foreign key
            $table->dropForeign(['job_id']);

            // Restore the original (incorrect) foreign key
            $table->foreign('job_id')
                  ->references('id')
                  ->on('jobs')
                  ->nullOnDelete();
        });
    }
};
