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
                'prohibited_if:type,transfer,withdrawal',
                'integer',
                Rule::exists('categories', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'goal_id' => [
                'nullable',
                'required_if:type,transfer,withdrawal',
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
                'prohibited_if:type,transfer,income,withdrawal',
            ],
            'installments.*.amount' => ['required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
            'installments.*.date' => ['required', 'date_format:Y-m-d'],

            'installments_count' => ['nullable', 'integer', 'min:1', 'max:120'],
            'period_unit' => [
                'nullable',
                'string', Rule::in(Transaction::PERIOD_UNITS),
                'prohibited_if:type,transfer,income,withdrawal',
            ],
            'period_interval' => [
                'nullable',
                'integer',
                'min:1',
                'max:365',
                'prohibited_if:type,transfer,income,withdrawal',
            ],
        ];
    }

    public function messages(): array
    {
        $onlyExpenses = 'Somente saídas podem ser parceladas.';

        return [
            'installments.prohibited_if' => $onlyExpenses,
            'period_unit.prohibited_if' => $onlyExpenses,
            'period_interval.prohibited_if' => $onlyExpenses,
            'category_id.prohibited_if' => 'Transferências e resgates não usam categoria.',
            'goal_id.required_if' => 'Informe a meta.',
            'goal_id.prohibited_if' => 'Entradas não podem ter meta.',
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $this->checkInstallmentsSumMatchesTotal($validator);

            $isExpense = $this->input('type') === Transaction::TYPE_EXPENSE;
            $hasExplicitInstallments = is_array($this->input('installments'));
            $installmentsCount = (int) ($this->input('installments_count') ?? 1);

            if (! $isExpense && $installmentsCount > 1) {
                $validator->errors()->add(
                    'installments_count',
                    'Somente saídas podem ser parceladas.',
                );
            }

            if ($isExpense && ! $hasExplicitInstallments && $installmentsCount > 1 && ! $this->filled('period_unit')) {
                $validator->errors()->add(
                    'period_unit',
                    'Informe o período para dividir a transação em parcelas.',
                );
            }
        });
    }
}
