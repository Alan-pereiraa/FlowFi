<?php

namespace App\Domains\Ledger\Requests\Concerns;

use App\Domains\Shared\Casts\Money;
use Illuminate\Validation\Validator;
use InvalidArgumentException;

trait ValidatesInstallmentPlan
{
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
        }
    }
}
