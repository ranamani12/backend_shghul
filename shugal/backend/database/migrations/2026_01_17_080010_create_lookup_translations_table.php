<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lookup_translations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('lookup_id')->constrained('lookups')->cascadeOnDelete();
            $table->string('locale', 10);
            $table->string('name');
            $table->timestamps();

            $table->unique(['lookup_id', 'locale']);
            $table->index(['locale']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lookup_translations');
    }
};
