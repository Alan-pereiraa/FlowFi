<?php

namespace App\Providers;

use App\Domains\Identity\Repositories\EloquentOtpCodeRepository;
use App\Domains\Identity\Repositories\EloquentUserRepository;
use App\Domains\Identity\Repositories\OtpCodeRepositoryInterface;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use App\Domains\Ledger\Repositories\CategoryRepositoryInterface;
use App\Domains\Ledger\Repositories\EloquentCategoryRepository;
use App\Domains\Ledger\Repositories\EloquentGoalRepository;
use App\Domains\Ledger\Repositories\GoalRepositoryInterface;
use App\Domains\Shared\Repositories\AppearanceRepositoryInterface;
use App\Domains\Shared\Repositories\EloquentAppearanceRepository;
use Illuminate\Support\ServiceProvider;

class DomainServiceProvider extends ServiceProvider
{
    /**
     * Repository interface bindings, one entry per domain implementation.
     *
     * @var array<class-string, class-string>
     */
    public array $bindings = [
        UserRepositoryInterface::class => EloquentUserRepository::class,
        OtpCodeRepositoryInterface::class => EloquentOtpCodeRepository::class,
        GoalRepositoryInterface::class => EloquentGoalRepository::class,
        CategoryRepositoryInterface::class => EloquentCategoryRepository::class,
        AppearanceRepositoryInterface::class => EloquentAppearanceRepository::class,
    ];
}
