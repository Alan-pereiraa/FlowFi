<?php

use Carbon\CarbonImmutable;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    private const string TIMEZONE = 'America/Sao_Paulo';

    private const int BORN_PAID_TOLERANCE_SECONDS = 5;

    public function up(): void
    {
        DB::table('installments')
            ->where('status', 'paid')
            ->orderBy('id')
            ->chunkById(500, function ($installments): void {
                foreach ($installments as $installment) {
                    if (! $this->bornPaid($installment)) {
                        continue;
                    }

                    DB::table('installments')
                        ->where('id', $installment->id)
                        ->update(['paid_at' => $this->dueMidnight($installment->date)]);
                }
            });
    }

    public function down(): void {}

    private function bornPaid(object $installment): bool
    {
        if ($installment->paid_at === null) {
            return true;
        }

        $paidAt = CarbonImmutable::parse($installment->paid_at, config('app.timezone'));
        $createdAt = CarbonImmutable::parse($installment->created_at, config('app.timezone'));

        return abs($paidAt->diffInSeconds($createdAt)) <= self::BORN_PAID_TOLERANCE_SECONDS;
    }

    private function dueMidnight(string $date): string
    {
        return CarbonImmutable::parse(substr($date, 0, 10), self::TIMEZONE)
            ->setTimezone(config('app.timezone'))
            ->format('Y-m-d H:i:s');
    }
};
