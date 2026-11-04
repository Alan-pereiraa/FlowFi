<?php

use Carbon\CarbonImmutable;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('installments')
            ->whereIn('transaction_id', DB::table('transactions')->where('type', '!=', 'expense')->select('id'))
            ->delete();

        DB::table('transactions')
            ->where('type', '!=', 'expense')
            ->update([
                'installments_count' => 1,
                'schedule_type' => 'single',
                'period_unit' => null,
                'period_interval' => null,
            ]);
    }

    public function down(): void
    {
        $today = CarbonImmutable::today('America/Sao_Paulo')->toDateString();

        DB::table('transactions')
            ->where('type', '!=', 'expense')
            ->orderBy('id')
            ->each(function (object $transaction) use ($today): void {
                $date = substr($transaction->date, 0, 10);
                $paid = $transaction->type === 'transfer' || $date <= $today;

                DB::table('installments')->insert([
                    'transaction_id' => $transaction->id,
                    'step' => 1,
                    'amount' => $transaction->total_amount,
                    'status' => $paid ? 'paid' : 'pending',
                    'date' => $transaction->date,
                    'paid_at' => $paid ? now() : null,
                    'created_at' => now(),
                    'updated_at' => now(),
                    'deleted_at' => $transaction->deleted_at,
                ]);
            });
    }
};
