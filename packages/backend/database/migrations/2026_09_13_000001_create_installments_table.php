<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('installments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('transaction_id')->index()->constrained()->cascadeOnDelete();
            $table->unsignedInteger('step');
            $table->unsignedBigInteger('amount');
            $table->string('status')->default('pending');
            $table->date('date');
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('installments');
    }
};
