<?php

namespace Database\Seeders;

use App\Domains\Identity\Models\User;
use App\Domains\Notification\Models\Notification;
use Illuminate\Database\Seeder;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::first();

        Notification::factory()->count(5)->for($user)->create();
        Notification::factory()->count(3)->for($user)->read()->create();
    }
}
