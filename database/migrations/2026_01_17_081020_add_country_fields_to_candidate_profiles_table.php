<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('candidate_profiles', function (Blueprint $table) {
            $table->foreignId('nationality_country_id')->nullable()->constrained('countries')->nullOnDelete();
            $table->foreignId('resident_country_id')->nullable()->constrained('countries')->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('candidate_profiles', function (Blueprint $table) {
            $table->dropForeign(['nationality_country_id']);
            $table->dropForeign(['resident_country_id']);
            $table->dropColumn(['nationality_country_id', 'resident_country_id']);
        });
    }
};
