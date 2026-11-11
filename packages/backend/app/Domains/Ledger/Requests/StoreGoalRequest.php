<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Shared\Constants\IconCatalog;
use App\Domains\Shared\Rules\UniqueIgnoringCase;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreGoalRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => [
                'required',
                'string',
                'max:255',
                new UniqueIgnoringCase(
                    $this->user()->goals(),
                    'name',
                    'Já existe uma meta com esse nome.',
                    null,
                ),
            ],
            'icon' => ['required', 'string', Rule::in(IconCatalog::names())],
            'color' => ['required', 'string', 'hex_color', 'size:7'],
            'target_amount' => ['required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
            'expires_at' => ['nullable', 'date_format:Y-m-d'],
        ];
    }
}
