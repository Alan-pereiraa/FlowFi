<?php

namespace App\Domains\Identity\Requests;

use App\Domains\Identity\Services\UserService;
use Illuminate\Foundation\Http\FormRequest;

class UpdateUserRequest extends FormRequest
{
    public function authorize(UserService $users): bool
    {
        $users->findOwned($this->user(), (int) $this->route('id'));

        return true;
    }

    public function rules(): array
    {
        return [
            'first_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'last_name' => ['sometimes', 'nullable', 'string', 'max:255'],
            'phone_number' => ['sometimes', 'nullable', 'string', 'max:20'],
            'email' => ['prohibited'],
        ];
    }

    public function messages(): array
    {
        return [
            'email.prohibited' => 'O e-mail não pode ser alterado.',
        ];
    }
}
