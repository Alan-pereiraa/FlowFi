<?php

namespace App\Domains\Ledger\Requests\Concerns;

use App\Domains\Shared\Casts\Money;
use Illuminate\Validation\Validator;
use InvalidArgumentException;

trait ValidatesInstallmentPlan
{
    /**
     * Whenever both an explicit `installments` list and a `total_amount` are present (either
     * may come from the request or, on update, be filled in from the existing transaction),
     * the two must agree in cents. Malformed values are left alone here — the field-level
     * rules already report those.
     */
    protected function checkInstallmentsSumMatchesTotal(Validator $validator): void
    {
        $installments = $this->input('installments');
        $totalAmount = $this->input('total_amount');

        if (! is_array($installments) || $totalAmount === null) {
            return;
        }

        $sum = 0;

        foreach ($installments as $index => $installment) {
            if (! isset($installment['amount'])) {
                return;
            }

            try {
                $sum += Money::toCents($installment['amount'], "installments.{$index}.amount");
            } catch (InvalidArgumentException) {
                return;
            }
        }

        try {
            if ($sum !== Money::toCents($totalAmount, 'total_amount')) {
                $validator->errors()->add('installments', 'The installment amounts must add up to the total amount.');
            }
        } catch (InvalidArgumentException) {
            // Malformed total_amount is already reported by its own rule.
        }
    }
}
