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
            // Nullable per docs/erd.md's open point: most transactions have no goal.
            $table->foreignId('goal_id')->nullable()->index()->constrained()->nullOnDelete();
            $table->string('type');
            $table->unsignedBigInteger('total_amount');
            $table->date('date');
            $table->text('description')->nullable();
            // Denormalized count of live installments (ERD flags this as a duplicate of
            // COUNT(installments); kept anyway as a read-side convenience, always written
            // by TransactionService alongside the installments themselves, never by hand).
            $table->unsignedInteger('installments_count')->default(1);
            // How the current schedule was produced: single | periodic | custom.
            // Not in the original drawing; needed to know whether period_* still applies
            // and whether an update should re-derive dates from a period or accept explicit ones.
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
