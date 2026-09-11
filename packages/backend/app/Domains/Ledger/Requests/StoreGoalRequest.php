<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Shared\Constants\IconCatalog;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreGoalRequest extends FormRequest
{
    /**
     * `name` is unique per user among live rows (soft-deleted names may be
     * reused); the comparison is case-sensitive, and it is enforced here
     * rather than by a DB index so a soft-deleted name stays reusable.
     * `target_amount` is a decimal ("1500.50" or 1500.5); the Money cast turns
     * it into cents. `size:7` on top of `hex_color` pins the `#RRGGBB` form.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => [
                'required',
                'string',
                'max:255',
                Rule::unique('goals', 'name')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'icon' => ['required', 'string', Rule::in(IconCatalog::names())],
            'color' => ['required', 'string', 'hex_color', 'size:7'],
            'target_amount' => ['required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
            'expires_at' => ['nullable', 'date_format:Y-m-d'],
        ];
    }
}
