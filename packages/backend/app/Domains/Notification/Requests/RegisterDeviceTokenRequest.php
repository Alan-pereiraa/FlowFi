<?php

namespace App\Domains\Notification\Requests;

use App\Domains\Notification\Enums\DevicePlatform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class RegisterDeviceTokenRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'token' => ['required', 'string', 'max:255'],
            'platform' => ['required', 'string', Rule::enum(DevicePlatform::class)],
        ];
    }
}
