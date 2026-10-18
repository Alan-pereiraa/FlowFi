<?php

namespace App\Domains\Dashboard\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpcomingInstallmentsRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            // How many days ahead to look. Pending installments already past due are always included.
            'days' => ['sometimes', 'integer', 'min:1', 'max:365'],
            'limit' => ['sometimes', 'integer', 'min:1', 'max:50'],
        ];
    }
}
