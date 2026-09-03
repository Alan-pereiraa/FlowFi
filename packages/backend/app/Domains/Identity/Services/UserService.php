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

    /**
     * @throws ModelNotFoundException
     */
    public function find(int $id): User
    {
        return $this->users->findById($id)
            ?? throw (new ModelNotFoundException)->setModel(User::class, [$id]);
    }

    /**
     * @param  array{first_name?: string, last_name?: string, phone_number?: string|null, email?: string}  $data
     */
    public function update(User $user, array $data): User
    {
        if (array_key_exists('email', $data) && $data['email'] !== $user->email) {
            $data['email_verified_at'] = null;
        }

        return $this->users->update($user, $data);
    }

    /**
     * Soft-delete the user and revoke every API token they hold.
     */
    public function delete(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $this->users->revokeTokens($user);
            $this->users->delete($user);
        });
    }
}
