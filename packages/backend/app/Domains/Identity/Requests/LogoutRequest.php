<?php

namespace App\Domains\Identity\Requests;

use Illuminate\Foundation\Http\FormRequest;

class LogoutRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'device_token' => ['sometimes', 'nullable', 'string', 'max:255'],
        ];
    }
}
