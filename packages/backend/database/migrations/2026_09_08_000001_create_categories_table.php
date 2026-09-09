<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * `limit_amount` is nullable integer cents (see App\Domains\Shared\Casts\Money);
     * null means the category has no spending cap.
     *
     * `index()` is called before `constrained()` on purpose: `constrained()`
     * returns the foreign-key definition, on which `index()` is a silent
     * no-op, and SQLite does not index foreign keys by itself.
     *
     * Names are unique per user, but only among live rows, and that rule is
     * enforced in the FormRequests rather than here. A unique index on
     * `(user_id, name)` would refuse to re-create a name after a soft delete,
     * and adding `deleted_at` to the index does not constrain live rows
     * because NULLs are distinct. The race window between check and insert is
     * accepted.
     */
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->index()->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('icon');
            $table->string('color', 7);
            $table->unsignedBigInteger('limit_amount')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
