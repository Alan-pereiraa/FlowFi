<?php

namespace Database\Factories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Ledger\Models\Transaction;
use Illuminate\Database\Eloquent\Factories\Factory;

class TransactionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'category_id' => Category::factory(),
            'goal_id' => null,
            'type' => fake()->randomElement(Transaction::TYPES),
            'total_amount' => number_format(fake()->randomFloat(2, 10, 5000), 2, '.', ''),
            'date' => fake()->dateTimeBetween('-3 months', 'now')->format('Y-m-d'),
            'description' => fake()->optional()->sentence(),
            'installments_count' => 1,
            'schedule_type' => Transaction::SCHEDULE_SINGLE,
            'period_unit' => null,
            'period_interval' => null,
        ];
    }
}
