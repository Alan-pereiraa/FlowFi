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

    private Transaction $transaction;

    public function authorize(TransactionService $transactions): bool
    {
        $this->transaction = $transactions->findOwned($this->user(), (int) $this->route('id'));

        return true;
    }

    public function rules(): array
    {
        $type = $this->transaction->type;
        $isExpense = $type === Transaction::TYPE_EXPENSE;
        $movesGoal = in_array($type, [Transaction::TYPE_TRANSFER, Transaction::TYPE_WITHDRAWAL], true);

        return [
            'category_id' => [
                'sometimes',
                Rule::prohibitedIf($movesGoal),
                'nullable',
                'integer',
                Rule::exists('categories', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'goal_id' => [
                'sometimes',
                Rule::prohibitedIf($type === Transaction::TYPE_INCOME),
                Rule::requiredIf($movesGoal),
                'nullable',
                'integer',
                Rule::exists('goals', 'id')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at'),
            ],
            'type' => ['prohibited'],
            'description' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'date' => ['sometimes', 'required', 'date_format:Y-m-d'],
            'total_amount' => ['sometimes', 'required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],

            'installments' => [
                'sometimes',
                Rule::prohibitedIf(! $isExpense),
                'array',
                'min:1',
                'max:120',
                'prohibits:installments_count,period_unit,period_interval',
            ],
            'installments.*.amount' => ['required_with:installments', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
            'installments.*.date' => ['required_with:installments', 'date_format:Y-m-d'],

            'installments_count' => ['sometimes', 'nullable', 'integer', 'min:1', 'max:120'],
            'period_unit' => ['sometimes', Rule::prohibitedIf(! $isExpense), 'nullable', 'string', Rule::in(Transaction::PERIOD_UNITS)],
            'period_interval' => ['sometimes', Rule::prohibitedIf(! $isExpense), 'nullable', 'integer', 'min:1', 'max:365'],
        ];
    }

    public function messages(): array
    {
        $onlyExpenses = 'Somente saídas podem ser parceladas.';

        return [
            'installments.prohibited' => $onlyExpenses,
            'period_unit.prohibited' => $onlyExpenses,
            'period_interval.prohibited' => $onlyExpenses,
            'category_id.prohibited' => 'Transferências e resgates não usam categoria.',
            'goal_id.required' => 'Informe a meta.',
            'goal_id.prohibited' => 'Entradas não podem ter meta.',
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $this->checkInstallmentsSumMatchesTotal($validator);

            if ($this->transaction->type !== Transaction::TYPE_EXPENSE && (int) $this->input('installments_count', 1) > 1) {
                $validator->errors()->add(
                    'installments_count',
                    'Somente saídas podem ser parceladas.',
                );
            }
        });
    }
}
