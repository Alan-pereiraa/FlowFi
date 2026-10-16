<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recurring_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->index()->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->nullable()->index()->constrained()->nullOnDelete();
            $table->foreignId('goal_id')->nullable()->index()->constrained()->nullOnDelete();
            $table->string('type');
            $table->unsignedBigInteger('amount');
            $table->text('description')->nullable();
            $table->string('period_unit');
            $table->unsignedInteger('period_interval')->default(1);
            $table->date('start_date');
            $table->date('end_date')->nullable();
            $table->unsignedInteger('occurrences')->nullable();
            $table->unsignedInteger('generated_count')->default(0);
            // Null once the template is finished (ended, or every occurrence generated).
            $table->date('next_occurrence_on')->nullable()->index();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recurring_transactions');
    }
};
