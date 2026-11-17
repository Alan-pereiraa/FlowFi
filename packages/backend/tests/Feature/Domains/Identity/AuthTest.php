<?php

namespace Tests\Feature\Identity;

use App\Domains\Identity\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * TIPO: TESTE DE INTEGRAÇÃO (nível API) — no Laravel, um "Feature Test".
 *
 * POR QUÊ:
 *  - Não é unitário: nenhuma classe é isolada nem simulada (sem mocks). Cada teste
 *    atravessa rota -> autenticação (Sanctum) -> controller -> service -> banco
 *    -> JSON de resposta.
 *  - Não é E2E: a requisição HTTP é simulada dentro do próprio PHP (getJson/postJson),
 *    sem navegador, sem rede e sem o app Flutter.
 *  - O usuário é criado por factory direto no banco (SQLite em memória, via
 *    RefreshDatabase), então o teste não depende do fluxo de login por OTP.
 *
 * O QUE COBRE: o "básico" de acesso — ver o próprio perfil, ser barrado sem login
 * e encerrar a sessão (logout). É um teste de fumaça (smoke test) da autenticação.
 */
class AuthTest extends TestCase
{
    use RefreshDatabase;

    // CAMINHO FELIZ: usuário logado (com token) consegue ver o próprio perfil,
    // e o e-mail devolvido é o dele.
    public function test_authenticated_user_can_fetch_profile(): void
    {
        $user = User::factory()->create();
        // Cria um token do Sanctum, como se o usuário tivesse feito login.
        $token = $user->createToken('api')->plainTextToken;

        $response = $this->withToken($token)->getJson("/api/v1/users/{$user->id}");

        $response->assertOk()->assertJsonPath('data.email', $user->email);
    }

    // SEGURANÇA: sem token, a rota de perfil responde 401 (não autenticado).
    // O id 1 é qualquer um: o acesso é barrado antes de procurar o usuário.
    public function test_guest_cannot_fetch_profile(): void
    {
        $this->getJson('/api/v1/users/1')->assertUnauthorized();
    }

    // CAMINHO FELIZ: o logout responde 200 e apaga o token do banco. A conferência é
    // feita no banco (contagem em zero), o que prova que a sessão foi realmente revogada.
    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }
}
