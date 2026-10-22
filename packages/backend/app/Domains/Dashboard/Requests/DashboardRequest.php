<?php

namespace App\Domains\Dashboard\Requests;

use Illuminate\Foundation\Http\FormRequest;

class DashboardRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'month' => ['bail', 'sometimes', 'string', 'regex:/^\d{4}-(0[1-9]|1[0-2])$/'],
        ];
    }

    public function messages(): array
    {
        return [
            'month.string' => 'O mês deve estar no formato AAAA-MM, por exemplo 2026-09.',
            'month.regex' => 'O mês deve estar no formato AAAA-MM, por exemplo 2026-09.',
        ];
    }
}
