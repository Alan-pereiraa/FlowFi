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
     * Resolve the user a caller is entitled to act on.
     *
     * A caller may only ever address themselves, so a mismatch is reported as
     * "not found" rather than "forbidden": a 403 would confirm that the id
     * belongs to a real account. Callers are already loaded by the Sanctum
     * guard, so the entitled case costs no query.
     *
     * The message is deliberately generic. setModel() would render as
     * "No query results for model [App\Domains\Identity\Models\User] 42",
     * echoing the id and the internal class name, which survives even with
     * APP_DEBUG off and would make a foreign id distinguishable from one that
     * never existed.
     *
     * @throws ModelNotFoundException
     */
    public function findOwned(User $caller, int $id): User
    {
        if ($caller->id !== $id) {
            throw new ModelNotFoundException('Not found.');
        }

        return $caller;
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
