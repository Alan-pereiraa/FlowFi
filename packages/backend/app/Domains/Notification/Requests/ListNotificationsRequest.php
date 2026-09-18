<?php

namespace App\Domains\Notification\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ListNotificationsRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['sometimes', 'string', Rule::in(['read', 'unread'])],
        ];
    }
}