<?php

namespace App\Domains\Identity\Repositories;

use App\Domains\Identity\Models\User;

class EloquentUserRepository implements UserRepositoryInterface
{
    public function create(array $attributes): User
    {
        return User::create($attributes);
    }

    public function findById(int $id): ?User
    {
        return User::find($id);
    }

    public function findByEmail(string $email): ?User
    {
        return User::where('email', $email)->first();
    }

    public function update(User $user, array $attributes): User
    {
        $user->forceFill($attributes)->save();

        return $user;
    }

    public function delete(User $user): void
    {
        $user->delete();
    }

    public function revokeTokens(User $user): void
    {
        $user->tokens()->delete();
    }
}
