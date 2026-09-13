<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Requests\Concerns\ValidatesInstallmentPlan;
use App\Domains\Ledger\Services\TransactionService;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UpdateTransactionRequest extends FormRequest
{
    use ValidatesInstallmentPlan;

    public function authorize(TransactionService $transactions): bool
    {
        $transactions->findOwned($this->user(), (int) $this->route('id'));

        return true;
    }

    public function rules(): array
    {
        return [
            'category_id' => [
                'sometimes',
                'required',
                'integer',
                Rule::exists('categories', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'goal_id' => [
                'sometimes',
                'nullable',
                'integer',
                Rule::exists('goals', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'type' => ['sometimes', 'required', 'string', Rule::in(Transaction::TYPES)],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'date' => ['sometimes', 'required', 'date_format:Y-m-d'],
            'total_amount' => ['sometimes', 'required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],

            'installments' => ['sometimes', 'array', 'min:1', 'max:120', 'prohibits:installments_count,period_unit,period_interval'],
            'installments.*.amount' => ['required_with:installments', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
            'installments.*.date' => ['required_with:installments', 'date_format:Y-m-d'],

            'installments_count' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:120'],
            'period_unit' => ['sometimes', 'nullable', 'string', Rule::in(Transaction::PERIOD_UNITS)],
            'period_interval' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:365'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(fn (Validator $validator) => $this->checkInstallmentsSumMatchesTotal($validator));
    }
}
