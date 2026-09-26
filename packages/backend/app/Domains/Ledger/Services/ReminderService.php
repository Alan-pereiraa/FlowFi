<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Ledger\Models\Installment;
use App\Domains\Notification\Enums\NotificationType;
use App\Domains\Notification\Service\NotificationService;
use Carbon\CarbonImmutable;

class ReminderService
{
    private const int INSTALLMENT_DUE_SOON_DAYS = 2;

    private const int GOAL_DEADLINE_DAYS = 7;

    public function __construct(
        private readonly TransactionService $transactions,
        private readonly GoalService $goals,
        private readonly NotificationService $notifications,
    ) {}

    public function sendAll(): array
    {
        return [
            'installments_due_soon' => $this->notifyInstallmentsDueSoon(),
            'installments_overdue' => $this->notifyInstallmentsOverdue(),
            'goals_near_deadline' => $this->notifyGoalsNearDeadline(),
        ];
    }

    public function notifyInstallmentsDueSoon(): int
    {
        $today = CarbonImmutable::today();
        $installments = $this->transactions->pendingExpenseInstallmentsDueBetween(
            $today,
            $today->addDays(self::INSTALLMENT_DUE_SOON_DAYS),
        );

        $sent = 0;

        foreach ($installments as $installment) {
            $user = $installment->transaction->user;

            if ($user === null) {
                continue;
            }

            $notification = $this->notifications->notifyOnce(
                $user,
                'Installment due soon',
                "{$this->describe($installment)} is due on {$installment->date->toDateString()}.",
                NotificationType::Info,
                'installment_due_soon',
                $installment->id,
            );

            $sent += $notification === null ? 0 : 1;
        }

        return $sent;
    }

    public function notifyInstallmentsOverdue(): int
    {
        $installments = $this->transactions->overduePendingExpenseInstallments(CarbonImmutable::today());

        $sent = 0;

        foreach ($installments as $installment) {
            $user = $installment->transaction->user;

            if ($user === null) {
                continue;
            }

            $notification = $this->notifications->notifyOnce(
                $user,
                'Installment overdue',
                "{$this->describe($installment)} was due on {$installment->date->toDateString()} and is still unpaid.",
                NotificationType::Error,
                'installment_overdue',
                $installment->id,
            );

            $sent += $notification === null ? 0 : 1;
        }

        return $sent;
    }

    public function notifyGoalsNearDeadline(): int
    {
        $today = CarbonImmutable::today();
        $goals = $this->goals->unreachedExpiringBetween($today, $today->addDays(self::GOAL_DEADLINE_DAYS));

        $sent = 0;

        foreach ($goals as $goal) {
            if ($goal->user === null) {
                continue;
            }

            $notification = $this->notifications->notifyOnce(
                $goal->user,
                'Goal deadline approaching',
                "Your goal \"{$goal->name}\" ends on {$goal->expires_at->toDateString()} and has {$goal->current_amount} of {$goal->target_amount} saved.",
                NotificationType::Warning,
                'goal_deadline',
                $goal->id,
            );

            $sent += $notification === null ? 0 : 1;
        }

        return $sent;
    }

    private function describe(Installment $installment): string
    {
        $transaction = $installment->transaction;
        $categoryName = $transaction->category?->name;

        if ($transaction->installments_count > 1) {
            $label = match (true) {
                $transaction->description !== null => "\"{$transaction->description}\"",
                $categoryName !== null => "your \"{$categoryName}\" expense",
                default => 'your expense',
            };

            return "Installment {$installment->step}/{$transaction->installments_count} of {$label} ({$installment->amount})";
        }

        $label = match (true) {
            $transaction->description !== null => "Expense \"{$transaction->description}\"",
            $categoryName !== null => "Your \"{$categoryName}\" expense",
            default => 'Your expense',
        };

        return "{$label} ({$installment->amount})";
    }
}
