<?php

namespace Tests\Feature\Identity;

use App\Domains\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_fetch_profile(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        $response = $this->withToken($token)->getJson("/api/v1/users/{$user->id}");

        $response->assertOk()->assertJsonPath('data.email', $user->email);
    }

    public function test_guest_cannot_fetch_profile(): void
    {
        $this->getJson('/api/v1/users/1')->assertUnauthorized();
    }

    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }
}
