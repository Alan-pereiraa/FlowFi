<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Ledger\Models\RecurringTransaction;
use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Services\RecurringTransactionService;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateRecurringTransactionRequest extends FormRequest
{
    private RecurringTransaction $recurring;

    public function authorize(RecurringTransactionService $recurring): bool
    {
        $this->recurring = $recurring->findOwned($this->user(), (int) $this->route('id'));

        return true;
    }

    public function rules(): array
    {
        $type = $this->recurring->type;

        return [
            'category_id' => [
                'sometimes',
                Rule::prohibitedIf($type === Transaction::TYPE_TRANSFER),
                'required',
                'integer',
                Rule::exists('categories', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'goal_id' => [
                'sometimes',
                Rule::prohibitedIf($type === Transaction::TYPE_INCOME),
                Rule::requiredIf($type === Transaction::TYPE_TRANSFER),
                'nullable',
                'integer',
                Rule::exists('goals', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'amount' => ['sometimes', 'required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],

            // The schedule is fixed once created: end it and create a new one instead.
            'type' => ['prohibited'],
            'period_unit' => ['prohibited'],
            'period_interval' => ['prohibited'],
            'start_date' => ['prohibited'],
            'end_date' => ['prohibited'],
            'occurrences' => ['prohibited'],
        ];
    }
}
