<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('company_profiles', function (Blueprint $table) {
            $table->foreignId('country_id')->nullable()->after('company_name')->constrained('countries')->nullOnDelete();
            $table->string('mobile_number')->nullable()->after('contact_email');
            $table->string('civil_id')->nullable()->after('mobile_number');
            $table->json('majors')->nullable()->after('civil_id');
        });
    }

    public function down(): void
    {
        Schema::table('company_profiles', function (Blueprint $table) {
            $table->dropForeign(['country_id']);
            $table->dropColumn(['country_id', 'mobile_number', 'civil_id', 'majors']);
        });
    }
};
