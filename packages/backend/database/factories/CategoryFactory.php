<?php

namespace Database\Factories;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use App\Domains\Shared\Constants\IconCatalog;
use Illuminate\Database\Eloquent\Factories\Factory;

class CategoryFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => fake()->unique()->words(2, true),
            'type' => Category::TYPE_EXPENSE,
            'icon' => fake()->randomElement(IconCatalog::names()),
            'color' => strtoupper(fake()->hexColor()),
            'limit_amount' => fake()->optional()->passthrough(
                number_format(fake()->randomFloat(2, 50, 10000), 2, '.', ''),
            ),
        ];
    }

    public function income(): static
    {
        return $this->state(['type' => Category::TYPE_INCOME]);
    }
}
