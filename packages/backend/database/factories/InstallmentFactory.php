<?php

namespace Database\Factories;

use App\Domains\Ledger\Models\Installment;
use App\Domains\Ledger\Models\Transaction;
use Illuminate\Database\Eloquent\Factories\Factory;

class InstallmentFactory extends Factory
{
    public function definition(): array
    {
        return [
            'transaction_id' => Transaction::factory(),
            'step' => 1,
            'amount' => number_format(fake()->randomFloat(2, 10, 5000), 2, '.', ''),
            'status' => Installment::STATUS_PENDING,
            'date' => fake()->dateTimeBetween('now', '+2 months')->format('Y-m-d'),
            'paid_at' => null,
        ];
    }
}
