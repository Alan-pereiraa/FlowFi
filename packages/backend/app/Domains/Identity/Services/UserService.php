<?php

namespace App\Domains\Identity\Services;

use App\Domains\Identity\Models\User;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Support\Facades\DB;

class UserService
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
    ) {}

    public function findOwned(User $caller, int $id): User
    {
        if ($caller->id !== $id) {
            throw new ModelNotFoundException('Not found.');
        }

        return $caller;
    }

    public function update(User $user, array $data): User
    {
        if (array_key_exists('email', $data) && $data['email'] !== $user->email) {
            $data['email_verified_at'] = null;
        }

        return $this->users->update($user, $data);
    }

    public function delete(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $this->users->revokeTokens($user);
            $this->users->delete($user);
        });
    }
}
