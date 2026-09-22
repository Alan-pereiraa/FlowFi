<?php

namespace App\Providers;

use App\Domains\Identity\Repositories\EloquentOtpCodeRepository;
use App\Domains\Identity\Repositories\EloquentUserRepository;
use App\Domains\Identity\Repositories\OtpCodeRepositoryInterface;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use App\Domains\Ledger\Repositories\CategoryRepositoryInterface;
use App\Domains\Ledger\Repositories\EloquentCategoryRepository;
use App\Domains\Ledger\Repositories\EloquentGoalRepository;
use App\Domains\Ledger\Repositories\EloquentTransactionRepository;
use App\Domains\Ledger\Repositories\GoalRepositoryInterface;
use App\Domains\Ledger\Repositories\TransactionRepositoryInterface;
use App\Domains\Notification\Repositories\EloquentNotificationRepository;
use App\Domains\Notification\Repositories\NotificationRepositoryInterface;
use App\Domains\Shared\Repositories\AppearanceRepositoryInterface;
use App\Domains\Shared\Repositories\EloquentAppearanceRepository;
use Illuminate\Support\ServiceProvider;

class DomainServiceProvider extends ServiceProvider
{
    public array $bindings = [
        UserRepositoryInterface::class => EloquentUserRepository::class,
        OtpCodeRepositoryInterface::class => EloquentOtpCodeRepository::class,
        GoalRepositoryInterface::class => EloquentGoalRepository::class,
        CategoryRepositoryInterface::class => EloquentCategoryRepository::class,
        TransactionRepositoryInterface::class => EloquentTransactionRepository::class,
        AppearanceRepositoryInterface::class => EloquentAppearanceRepository::class,
        NotificationRepositoryInterface::class => EloquentNotificationRepository::class,
    ];
}
