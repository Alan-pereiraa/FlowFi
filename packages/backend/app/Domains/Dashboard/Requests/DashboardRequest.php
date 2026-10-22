<?php

namespace App\Domains\Dashboard\Requests;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Query string shared by `GET /dashboard`, `/dashboard/summary` and `/dashboard/spending-by-category`.
 */
class DashboardRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            // Calendar month the period-based blocks refer to. Defaults to the current month.
            'month' => ['sometimes', 'string', 'regex:/^\d{4}-(0[1-9]|1[0-2])$/'],
        ];
    }
}
