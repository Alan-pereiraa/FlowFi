<?php

namespace App\Domains\Identity\Requests;

use App\Domains\Identity\Requests\Concerns\NormalizesEmail;
use Illuminate\Foundation\Http\FormRequest;

class RequestOtpRequest extends FormRequest
{
    use NormalizesEmail;

    public function rules(): array
    {
        return [
            'email' => ['required', 'string', 'email', 'max:255'],
        ];
    }
}
