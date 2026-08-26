<?php

namespace App\Domains\Identity\Repositories;

use App\Domains\Identity\Models\User;

interface UserRepositoryInterface
{
    public function create(array $attributes): User;

    public function findByEmail(string $email): ?User;
}
