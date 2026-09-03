<?php

namespace App\Domains\Identity\Requests;

use App\Domains\Identity\Requests\Concerns\NormalizesEmail;
use Illuminate\Foundation\Http\FormRequest;

class VerifyOtpRequest extends FormRequest
{
    use NormalizesEmail;

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email', 'max:255'],
            'code' => ['required', 'digits:'.config('auth.otp.length')],
        ];
    }
}
