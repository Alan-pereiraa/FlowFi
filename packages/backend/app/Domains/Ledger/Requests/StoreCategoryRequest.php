<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Shared\Constants\IconCatalog;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCategoryRequest extends FormRequest
{
    /**
     * `name` is unique per user among live rows (soft-deleted names may be
     * reused); the comparison is case-sensitive. `limit_amount` is a decimal
     * ("500.50" or 500.5) or null for no cap; the Money cast turns it into
     * cents. `size:7` on top of `hex_color` pins the `#RRGGBB` form.
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
                Rule::unique('categories', 'name')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'icon' => ['required', 'string', Rule::in(IconCatalog::names())],
            'color' => ['required', 'string', 'hex_color', 'size:7'],
            'limit_amount' => ['nullable', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
        ];
    }
}
