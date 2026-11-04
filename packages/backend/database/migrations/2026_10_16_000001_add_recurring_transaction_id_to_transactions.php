<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->foreignId('recurring_transaction_id')->nullable()->index()->constrained()->nullOnDelete();

            $table->unique(['recurring_transaction_id', 'date']);
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropUnique(['recurring_transaction_id', 'date']);
            $table->dropForeign(['recurring_transaction_id']);
            $table->dropIndex(['recurring_transaction_id']);
            $table->dropColumn('recurring_transaction_id');
        });
    }
};
