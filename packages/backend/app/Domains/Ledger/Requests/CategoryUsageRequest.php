<?php

namespace App\Domains\Ledger\Requests;

use Illuminate\Foundation\Http\FormRequest;

class CategoryUsageRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'month' => ['sometimes', 'string', 'regex:/^\d{4}-(0[1-9]|1[0-2])$/'],
        ];
    }

    public function messages(): array
    {
        return [
            'month.regex' => 'Informe o mês no formato AAAA-MM.',
        ];
    }
}
