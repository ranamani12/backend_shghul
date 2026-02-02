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
        Schema::create('candidate_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('major')->nullable();
            $table->unsignedInteger('years_experience')->default(0);
            $table->json('skills')->nullable();
            $table->string('education')->nullable();
            $table->string('location')->nullable();
            $table->string('availability')->nullable();
            $table->string('cv_path')->nullable();
            $table->text('summary')->nullable();
            $table->string('public_slug')->nullable()->unique();
            $table->string('qr_code_path')->nullable();
            $table->string('profile_image_path')->nullable();
            $table->boolean('is_activated')->default(false);
            $table->timestamp('activated_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('candidate_profiles');
    }
};
