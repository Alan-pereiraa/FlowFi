<?php

namespace Database\Factories;

use App\Domains\Identity\Models\User;
use App\Domains\Shared\Constants\IconCatalog;
use Illuminate\Database\Eloquent\Factories\Factory;

class GoalFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => fake()->words(3, true),
            'icon' => fake()->randomElement(IconCatalog::names()),
            'color' => strtoupper(fake()->hexColor()),
            'target_amount' => number_format(fake()->randomFloat(2, 100, 50000), 2, '.', ''),
            'expires_at' => fake()->optional()->dateTimeBetween('+1 month', '+2 years'),
        ];
    }
}
