<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Shared\Constants\IconCatalog;
use App\Domains\Shared\Rules\UniqueIgnoringCase;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreCategoryRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => [
                'required',
                'string',
                'max:255',
                new UniqueIgnoringCase(
                    $this->user()->categories(),
                    'name',
                    'Já existe uma categoria com esse nome.',
                    null,
                ),
            ],
            'icon' => ['required', 'string', Rule::in(IconCatalog::names())],
            'color' => ['required', 'string', 'hex_color', 'size:7'],
            'limit_amount' => ['nullable', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
        ];
    }
}
