<?php

namespace Database\Seeders;

use App\Domains\Identity\Models\User;
use App\Domains\Ledger\Models\Goal;
use Illuminate\Database\Seeder;

class GoalSeeder extends Seeder
{
    private const array DEFAULTS = [
        ['name' => 'Reserva de emergência', 'icon' => 'savings', 'color' => '#2E7D32', 'target_amount' => '10000.00', 'expires_in_months' => null],
        ['name' => 'Viagem dos sonhos', 'icon' => 'flight_takeoff', 'color' => '#5C6BC0', 'target_amount' => '8000.00', 'expires_in_months' => 18],
        ['name' => 'Trocar de carro', 'icon' => 'directions_car', 'color' => '#42A5F5', 'target_amount' => '25000.00', 'expires_in_months' => 24],
        ['name' => 'Entrada do apartamento', 'icon' => 'house', 'color' => '#8D6E63', 'target_amount' => '50000.00', 'expires_in_months' => 36],
        ['name' => 'Fundo de aposentadoria', 'icon' => 'account_balance', 'color' => '#00897B', 'target_amount' => '100000.00', 'expires_in_months' => null],
        ['name' => 'Curso ou capacitação', 'icon' => 'school', 'color' => '#7E57C2', 'target_amount' => '3000.00', 'expires_in_months' => 12],
    ];

    public function run(): void
    {
        User::all()->each(function (User $user): void {
            foreach (self::DEFAULTS as $goal) {
                Goal::firstOrCreate(
                    ['user_id' => $user->id, 'name' => $goal['name']],
                    [
                        'icon' => $goal['icon'],
                        'color' => $goal['color'],
                        'target_amount' => $goal['target_amount'],
                        'expires_at' => $goal['expires_in_months'] !== null
                            ? now()->addMonths($goal['expires_in_months'])->toDateString()
                            : null,
                    ],
                );
            }
        });
    }
}
