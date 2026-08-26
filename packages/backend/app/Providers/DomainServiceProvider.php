<?php

namespace App\Providers;

use App\Domains\Identity\Repositories\EloquentUserRepository;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
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
    ];
}
