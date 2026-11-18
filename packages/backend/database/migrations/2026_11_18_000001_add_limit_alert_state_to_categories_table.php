<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->unsignedTinyInteger('limit_alert_level')->nullable()->after('limit_amount');
            $table->char('limit_alert_month', 7)->nullable()->after('limit_alert_level');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn(['limit_alert_level', 'limit_alert_month']);
        });
    }
};
