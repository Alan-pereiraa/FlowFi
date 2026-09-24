<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->index()->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->index()->constrained()->cascadeOnDelete();
            $table->foreignId('goal_id')->nullable()->index()->constrained()->nullOnDelete();
            $table->string('type');
            $table->unsignedBigInteger('total_amount');
            $table->date('date');
            $table->text('description')->nullable();
            $table->unsignedInteger('installments_count')->default(1);
            $table->string('schedule_type')->default('single');
            $table->string('period_unit')->nullable();
            $table->unsignedInteger('period_interval')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
