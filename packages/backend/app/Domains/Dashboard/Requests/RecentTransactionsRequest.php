<?php

namespace App\Domains\Dashboard\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RecentTransactionsRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'limit' => ['sometimes', 'integer', 'min:1', 'max:20'],
        ];
    }
}
