<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->string('type', 16)->default('expense')->after('name');
        });

        DB::table('categories')
            ->whereIn('id', DB::table('transactions')->where('type', 'income')->whereNotNull('category_id')->select('category_id'))
            ->whereNotIn('id', DB::table('transactions')->where('type', 'expense')->whereNotNull('category_id')->select('category_id'))
            ->update(['type' => 'income']);
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('type');
        });
    }
};
