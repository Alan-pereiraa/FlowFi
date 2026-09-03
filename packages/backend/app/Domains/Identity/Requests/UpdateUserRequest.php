<?php

namespace App\Domains\Identity\Requests;

use App\Domains\Identity\Services\UserService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateUserRequest extends FormRequest
{
    /**
     * Entitlement is checked here, not only in the controller, because
     * authorize() is the one hook that runs before validation. Without it a
     * malformed body aimed at someone else's id would answer 422 before the
     * request ever reached the 404. The rule itself lives in UserService; this
     * only decides when it runs.
     *
     * @throws ModelNotFoundException
     */
    public function authorize(UserService $users): bool
    {
        $users->findOwned($this->user(), (int) $this->route('id'));

        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'first_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'last_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'phone_number' => ['sometimes', 'nullable', 'string', 'max:20'],
            'email' => [
                'sometimes',
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($this->user()->id),
            ],
        ];
    }
}
