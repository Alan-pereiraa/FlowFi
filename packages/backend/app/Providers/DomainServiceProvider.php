<?php

namespace App\Providers;

use App\Domains\Identity\Repositories\EloquentOtpCodeRepository;
use App\Domains\Identity\Repositories\EloquentUserRepository;
use App\Domains\Identity\Repositories\OtpCodeRepositoryInterface;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use App\Domains\Ledger\Repositories\CategoryRepositoryInterface;
use App\Domains\Ledger\Repositories\EloquentCategoryRepository;
use App\Domains\Ledger\Repositories\EloquentGoalRepository;
use App\Domains\Ledger\Repositories\EloquentInstallmentRepository;
use App\Domains\Ledger\Repositories\EloquentTransactionRepository;
use App\Domains\Ledger\Repositories\GoalRepositoryInterface;
<<<<<<< HEAD
<<<<<<< HEAD
use App\Domains\Notification\Repositories\EloquentNotificationRepository;
use App\Domains\Notification\Repositories\NotificationRepositoryInterface;
=======
use App\Domains\Ledger\Repositories\InstallmentRepositoryInterface;
use App\Domains\Ledger\Repositories\TransactionRepositoryInterface;
>>>>>>> 5a24d02 (Ledger: add Transaction/Installment domain (single, periodic and custom schedules))
=======
use App\Domains\Ledger\Repositories\InstallmentRepositoryInterface;
use App\Domains\Ledger\Repositories\TransactionRepositoryInterface;
>>>>>>> 5a24d02581a4c82846cd1dae491d8db69418a0de
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
        InstallmentRepositoryInterface::class => EloquentInstallmentRepository::class,
        AppearanceRepositoryInterface::class => EloquentAppearanceRepository::class,
        NotificationRepositoryInterface::class => EloquentNotificationRepository::class,
    ];
}
