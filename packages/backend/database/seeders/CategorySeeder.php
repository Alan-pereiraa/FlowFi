<?php

namespace Database\Seeders;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    private const array DEFAULTS = [
        ['name' => 'Alimentação', 'icon' => 'restaurant', 'color' => '#FF7043'],
        ['name' => 'Moradia', 'icon' => 'home', 'color' => '#8D6E63'],
        ['name' => 'Transporte', 'icon' => 'directions_car', 'color' => '#42A5F5'],
        ['name' => 'Saúde', 'icon' => 'local_hospital', 'color' => '#EF5350'],
        ['name' => 'Educação', 'icon' => 'school', 'color' => '#7E57C2'],
        ['name' => 'Lazer', 'icon' => 'sports_esports', 'color' => '#FFCA28'],
        ['name' => 'Compras', 'icon' => 'shopping_bag', 'color' => '#EC407A'],
        ['name' => 'Tecnologia', 'icon' => 'laptop', 'color' => '#26C6DA'],
        ['name' => 'Família', 'icon' => 'family_restroom', 'color' => '#66BB6A'],
        ['name' => 'Viagem', 'icon' => 'flight', 'color' => '#5C6BC0'],
        ['name' => 'Salário', 'icon' => 'attach_money', 'color' => '#2E7D32'],
        ['name' => 'Investimentos', 'icon' => 'trending_up', 'color' => '#00897B'],
    ];

    public function run(): void
    {
        User::all()->each(function (User $user): void {
            foreach (self::DEFAULTS as $category) {
                Category::firstOrCreate(
                    ['user_id' => $user->id, 'name' => $category['name']],
                    ['icon' => $category['icon'], 'color' => $category['color']],
                );
            }
        });
    }
}
