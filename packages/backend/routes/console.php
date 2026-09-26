<?php

use App\Domains\Ledger\Services\ReminderService;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('ledger:send-reminders', function (ReminderService $reminders) {
    foreach ($reminders->sendAll() as $reminder => $sent) {
        $this->info("{$reminder}: {$sent}");
    }
})->purpose('Notify users about installments due soon or overdue and goals near their deadline');

Schedule::command('ledger:send-reminders')->dailyAt('08:00')->timezone('America/Sao_Paulo');
