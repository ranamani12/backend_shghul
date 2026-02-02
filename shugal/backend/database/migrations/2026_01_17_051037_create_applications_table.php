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
        Schema::create('applications', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('job_id');
            $table->foreignId('candidate_id')->constrained('users')->cascadeOnDelete();
            $table->string('status')->default('submitted');
            $table->text('cover_letter')->nullable();
            $table->boolean('is_paid')->default(false);
            $table->timestamp('applied_at')->nullable();
            $table->timestamps();

            $table->index('job_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('applications');
    }
};
