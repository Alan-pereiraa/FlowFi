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
            throw new ModelNotFoundException('Não encontrado.');
        }

        return $caller;
    }

    public function update(User $user, array $data): User
    {
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
