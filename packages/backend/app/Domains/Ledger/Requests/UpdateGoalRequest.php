<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Ledger\Services\GoalService;
use App\Domains\Shared\Constants\IconCatalog;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateGoalRequest extends FormRequest
{
    public function authorize(GoalService $goals): bool
    {
        $goals->findOwned($this->user(), (int) $this->route('id'));

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
                Rule::unique('goals', 'name')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at')
                    ->ignore((int) $this->route('id')),
            ],
            'icon' => ['sometimes', 'required', 'string', Rule::in(IconCatalog::names())],
            'color' => ['sometimes', 'required', 'string', 'hex_color', 'size:7'],
            'target_amount' => ['sometimes', 'required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
            'expires_at' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ];
    }
}
