<?php

namespace App\Domains\Identity\Repositories;

use App\Domains\Identity\Models\User;

interface UserRepositoryInterface
{
    public function create(array $attributes): User;

    public function findByEmail(string $email): ?User;

    /**
     * Includes soft-deleted users, so callers can tell "never existed" from
     * "deactivated".
     */
    public function findByEmailWithTrashed(string $email): ?User;

    public function update(User $user, array $attributes): User;

    public function delete(User $user): void;

    public function revokeTokens(User $user): void;
}
