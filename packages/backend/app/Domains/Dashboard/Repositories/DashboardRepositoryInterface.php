<?php

namespace App\Domains\Dashboard\Repositories;

use App\Domains\Identity\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Collection;

interface DashboardRepositoryInterface
{
    public function installmentTotals(User $user, ?CarbonImmutable $from, ?CarbonImmutable $to): array;

    public function oneOffTotals(User $user, ?CarbonImmutable $from, ?CarbonImmutable $to, CarbonImmutable $today): array;

    public function overdueTotals(User $user, CarbonImmutable $today): array;

    public function expensesByCategory(User $user, CarbonImmutable $from, CarbonImmutable $to): array;

    public function upcomingInstallments(User $user, CarbonImmutable $until, int $limit): Collection;

    public function recentTransactions(User $user, int $limit): Collection;

    public function goals(User $user): Collection;

    public function unreadNotificationsCount(User $user): int;
}
