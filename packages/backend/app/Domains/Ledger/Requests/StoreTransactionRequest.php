<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Ledger\Models\Transaction;
use App\Domains\Ledger\Requests\Concerns\ValidatesInstallmentPlan;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class StoreTransactionRequest extends FormRequest
{
    use ValidatesInstallmentPlan;

    public function rules(): array
    {
        return [
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
            'date' => ['required', 'date_format:Y-m-d'],
            'total_amount' => ['required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],

            'installments' => [
                'nullable',
                'array',
                'min:1',
                'max:120',
                'prohibits:installments_count,period_unit,period_interval',
                'prohibited_if:type,transfer',
            ],
            'installments.*.amount' => ['required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
            'installments.*.date' => ['required', 'date_format:Y-m-d'],

            'installments_count' => ['nullable', 'integer', 'min:1', 'max:120'],
            'period_unit' => [
                'nullable',
                'string', Rule::in(Transaction::PERIOD_UNITS),
                'prohibited_if:type,transfer',
            ],
            'period_interval' => [
                'nullable',
                'integer',
                'min:1',
                'max:365',
                'prohibited_if:type,transfer',
            ],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $this->checkInstallmentsSumMatchesTotal($validator);

            $hasExplicitInstallments = is_array($this->input('installments'));
            $installmentsCount = (int) ($this->input('installments_count') ?? 1);
            $isTransfer = $this->input('type') === Transaction::TYPE_TRANSFER;

            if (! $isTransfer && ! $hasExplicitInstallments && $installmentsCount > 1 && ! $this->filled('period_unit')) {
                $validator->errors()->add(
                    'period_unit',
                    'A period is required when splitting a transaction into more than one installment.',
                );
            }

            if ($isTransfer && $installmentsCount > 1) {
                $validator->errors()->add(
                    'installments_count',
                    'Transfers cannot be split into multiple installments.',
                );
            }
        });
    }
}
