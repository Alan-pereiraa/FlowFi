<?php

namespace App\Domains\Ledger\Services;

use App\Domains\Ledger\Models\Installment;
use App\Domains\Notification\Enums\NotificationType;
use App\Domains\Notification\Service\NotificationService;
use App\Domains\Shared\Casts\Money;
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
                'Parcela vencendo em breve',
                "{$this->describe($installment)} vence em {$installment->date->format('d/m/Y')}.",
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
                'Parcela em atraso',
                "{$this->describe($installment)} venceu em {$installment->date->format('d/m/Y')} e ainda não foi paga.",
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
                'Prazo da meta se aproximando',
                "Sua meta \"{$goal->name}\" termina em {$goal->expires_at->format('d/m/Y')} e tem {$this->brl($goal->current_amount)} de {$this->brl($goal->target_amount)} guardados.",
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
                $categoryName !== null => "seu gasto em \"{$categoryName}\"",
                default => 'seu gasto',
            };

            return "Parcela {$installment->step}/{$transaction->installments_count} de {$label} ({$this->brl($installment->amount)})";
        }

        $label = match (true) {
            $transaction->description !== null => "Gasto \"{$transaction->description}\"",
            $categoryName !== null => "Seu gasto em \"{$categoryName}\"",
            default => 'Seu gasto',
        };

        return "{$label} ({$this->brl($installment->amount)})";
    }

    private function brl(string $amount): string
    {
        return Money::toBrl(Money::toCents($amount));
    }
}
