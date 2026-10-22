<?php

namespace App\Domains\Dashboard\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RecentTransactionsRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'limit' => ['bail', 'sometimes', 'integer', 'min:1', 'max:20'],
        ];
    }

    public function messages(): array
    {
        return [
            'limit.integer' => 'O limite deve ser um número inteiro.',
            'limit.min' => 'O limite deve ser no mínimo :min.',
            'limit.max' => 'O limite deve ser no máximo :max.',
        ];
    }
}
