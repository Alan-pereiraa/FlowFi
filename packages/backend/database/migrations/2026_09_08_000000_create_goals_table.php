<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * `target_amount` is integer cents (see App\Domains\Shared\Casts\Money).
     * `index()` is called before `constrained()` on purpose: `constrained()`
     * returns the foreign-key definition, on which `index()` is a silent
     * no-op, and SQLite does not index foreign keys by itself.
     */
    public function up(): void
    {
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->index()->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('icon');
            $table->string('color', 7);
            $table->unsignedBigInteger('target_amount');
            $table->date('expires_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('goals');
    }
};
