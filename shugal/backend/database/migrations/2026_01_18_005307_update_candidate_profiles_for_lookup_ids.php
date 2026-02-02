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
        Schema::table('candidate_profiles', function (Blueprint $table) {
            // Add new lookup ID fields
            $table->json('major_ids')->nullable()->after('major');
            $table->foreignId('years_of_experience_id')->nullable()->after('years_experience')->constrained('lookups')->nullOnDelete();
            $table->foreignId('education_id')->nullable()->after('education')->constrained('lookups')->nullOnDelete();
            
            // Make old fields nullable (we'll remove them later if needed)
            $table->string('major')->nullable()->change();
            $table->unsignedInteger('years_experience')->nullable()->change();
            $table->string('education')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('candidate_profiles', function (Blueprint $table) {
            $table->dropForeign(['years_of_experience_id']);
            $table->dropForeign(['education_id']);
            $table->dropColumn(['major_ids', 'years_of_experience_id', 'education_id']);
            
            // Restore old fields to not nullable
            $table->string('major')->nullable(false)->change();
            $table->unsignedInteger('years_experience')->default(0)->change();
            $table->string('education')->nullable(false)->change();
        });
    }
};
