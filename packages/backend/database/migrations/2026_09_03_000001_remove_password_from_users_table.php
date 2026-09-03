<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * Authentication is OTP-only: the password column goes away and only the
     * email is required to create an account. Each Schema::table call is kept
     * separate on purpose: changing a column's nullability rebuilds the whole
     * table on SQLite.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('password');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->string('first_name')->nullable()->change();
            $table->string('last_name')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     *
     * Password hashes cannot be restored; the column comes back nullable.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable();
        });

        DB::table('users')->whereNull('first_name')->update(['first_name' => '']);
        DB::table('users')->whereNull('last_name')->update(['last_name' => '']);

        Schema::table('users', function (Blueprint $table) {
            $table->string('first_name')->nullable(false)->change();
            $table->string('last_name')->nullable(false)->change();
        });
    }
};
