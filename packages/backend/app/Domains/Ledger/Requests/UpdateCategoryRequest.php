<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Ledger\Services\CategoryService;
use App\Domains\Shared\Constants\IconCatalog;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateCategoryRequest extends FormRequest
{
    public function authorize(CategoryService $categories): bool
    {
        $categories->findOwned($this->user(), (int) $this->route('id'));

        return true;
    }

    public function rules(): array
    {
        return [
            'name' => [
                'sometimes',
                'required',
                'string',
                'max:255',
                Rule::unique('categories', 'name')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at')
                    ->ignore((int) $this->route('id')),
            ],
            'icon' => ['sometimes', 'required', 'string', Rule::in(IconCatalog::names())],
            'color' => ['sometimes', 'required', 'string', 'hex_color', 'size:7'],
            'limit_amount' => ['sometimes', 'nullable', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
        ];
    }
}
