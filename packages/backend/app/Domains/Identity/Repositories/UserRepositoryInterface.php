<?php

namespace App\Domains\Identity\Repositories;

use App\Domains\Identity\Models\User;

interface UserRepositoryInterface
{
    public function create(array $attributes): User;

    public function findById(int $id): ?User;

    public function findByEmail(string $email): ?User;

    public function update(User $user, array $attributes): User;

    public function delete(User $user): void;

    public function revokeTokens(User $user): void;
}
