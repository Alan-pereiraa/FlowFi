<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Ledger\Models\Transaction;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreRecurringTransactionRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            // Same type/category/goal rules as StoreTransactionRequest: every occurrence is posted through TransactionService.
            'category_id' => [
                'nullable',
                'required_unless:type,transfer',
                'prohibited_if:type,transfer',
                'integer',
                Rule::exists('categories', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'goal_id' => [
                'nullable',
                'required_if:type,transfer',
                'prohibited_if:type,income',
                'integer',
                Rule::exists('goals', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'type' => ['required', 'string', Rule::in(Transaction::TYPES)],
            'description' => ['nullable', 'string', 'max:1000'],
            'amount' => ['required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],

            'period_unit' => ['required', 'string', Rule::in(Transaction::PERIOD_UNITS)],
            'period_interval' => ['nullable', 'integer', 'min:1', 'max:365'],
            // Past dates are back-filled on create; capped so one request can't generate years of rows.
            'start_date' => ['required', 'date_format:Y-m-d', 'after_or_equal:'.now('America/Sao_Paulo')->subYear()->toDateString()],
            'end_date' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:start_date', 'prohibits:occurrences'],
            'occurrences' => ['nullable', 'integer', 'min:2', 'max:120'],
        ];
    }
}
