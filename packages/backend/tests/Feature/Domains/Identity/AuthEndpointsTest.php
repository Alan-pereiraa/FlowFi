<?php

namespace Tests\Feature\Domains\Identity;

use App\Domains\Identity\Mail\AccountDeactivatedMail;
use App\Domains\Identity\Mail\OtpCodeMail;
use App\Domains\Identity\Models\User;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

/**
 * TIPO: TESTE DE INTEGRAÇÃO (nível API) — no Laravel, um "Feature Test".
 *
 * POR QUÊ:
 *  - Não é unitário: nenhuma classe interna é isolada. Cada teste atravessa as
 *    camadas reais do login por OTP: rota -> throttle (limite de requisições)
 *    -> validação (Request) -> AuthService -> OtpService -> Repository -> banco
 *    -> JSON de resposta.
 *  - Não é E2E: a requisição HTTP é simulada dentro do próprio PHP (postJson),
 *    sem navegador, sem rede e sem o app Flutter.
 *  - O único "fake" é Mail::fake(), que fica na fronteira do sistema: impede o
 *    envio real de e-mail e permite conferir o que seria enviado. Todo o resto
 *    (banco SQLite em memória, services, repositórios) é real.
 *
 * O QUE COBRE: pedir código, verificar código, login com token, logout,
 * validação de dados, normalização de e-mail, conta desativada e rate limit.
 */
class AuthEndpointsTest extends TestCase
{
    use RefreshDatabase;

    // Caminhos das rotas (prefixo /api/v1 vem do arquivo de rotas).
    private const REQUEST_OTP_URL = '/api/v1/auth/otp/request';

    private const VERIFY_OTP_URL = '/api/v1/auth/otp/verify';

    private const LOGOUT_URL = '/api/v1/auth/logout';

    private const LOGOUT_METHOD = 'POST';

    private const EMAIL = 'user@example.com';

    protected function setUp(): void
    {
        parent::setUp();

        // Fronteira do sistema: nenhum e-mail real é enviado; fica tudo registrado
        // para os asserts (Mail::assertSent / assertNothingSent).
        Mail::fake();

        // Fixa as regras do OTP para os testes não dependerem do .env:
        // validade de 10 min, no máximo 3 tentativas, código de 6 dígitos.
        config([
            'auth.otp.expire' => 10,
            'auth.otp.max_attempts' => 3,
            'auth.otp.length' => 6,
        ]);
    }

    // CAMINHO FELIZ: e-mail válido devolve 202 (aceito) e dispara o e-mail com o código.
    public function test_pedir_codigo_com_email_valido_devolve_202_e_envia_o_email(): void
    {
        $this->postJson(self::REQUEST_OTP_URL, ['email' => self::EMAIL])
            ->assertStatus(202)
            ->assertExactJson(['message' => 'Código enviado.']);

        Mail::assertSent(
            OtpCodeMail::class,
            fn (OtpCodeMail $mail) => $mail->hasTo(self::EMAIL)
        );
    }

    // SEGURANÇA: a resposta é idêntica para e-mail com conta e sem conta, para que
    // ninguém consiga descobrir quem está cadastrado (enumeração de usuários).
    public function test_pedir_codigo_responde_igual_para_email_com_e_sem_conta(): void
    {
        $this->createUser('existe@example.com');

        $withAccount = $this->postJson(self::REQUEST_OTP_URL, ['email' => 'existe@example.com']);
        $withoutAccount = $this->postJson(self::REQUEST_OTP_URL, ['email' => 'nao-existe@example.com']);

        $withAccount->assertStatus(202);
        $withoutAccount->assertStatus(202);
        $this->assertSame($withAccount->json(), $withoutAccount->json());
    }

    // TESTE NEGATIVO: sem e-mail -> 422 (erro de validação) e nenhum e-mail é enviado.
    public function test_pedir_codigo_sem_email_devolve_422_e_nao_envia_email(): void
    {
        $this->postJson(self::REQUEST_OTP_URL, [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);

        Mail::assertNothingSent();
    }

    // TESTE NEGATIVO: e-mail com formato inválido -> 422 e nenhum e-mail é enviado.
    public function test_pedir_codigo_com_email_invalido_devolve_422_e_nao_envia_email(): void
    {
        $this->postJson(self::REQUEST_OTP_URL, ['email' => 'isto-nao-e-um-email'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);

        Mail::assertNothingSent();
    }

    // CAMINHO FELIZ: código correto -> 200 com os dados do usuário e o token de acesso.
    public function test_verificar_com_codigo_correto_devolve_usuario_e_token(): void
    {
        $code = $this->requestCode(self::EMAIL);

        $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => $code])
            ->assertOk()
            ->assertJsonStructure(['user', 'token']);
    }

    // TESTE NEGATIVO: código errado -> 422, sem token e sem registro de token no banco.
    public function test_verificar_com_codigo_errado_devolve_422_e_nenhum_token(): void
    {
        $code = $this->requestCode(self::EMAIL);
        // Garante um código diferente do verdadeiro, mesmo no raro caso de sorteio igual.
        $wrong = $code === '000000' ? '111111' : '000000';

        $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => $wrong])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['code'])
            ->assertJsonMissingPath('token');

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    // TESTE NEGATIVO: corpo vazio -> 422 com erro nos dois campos obrigatórios.
    public function test_verificar_sem_os_campos_obrigatorios_devolve_422(): void
    {
        $this->postJson(self::VERIFY_OTP_URL, [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email', 'code']);
    }

    // REGRA DE NEGÓCIO (nova): conta desativada não recebe código de login; em vez disso,
    // recebe um e-mail avisando que a conta foi desativada. A resposta continua 202 para
    // não revelar ao cliente que a conta existe.
    public function test_pedir_codigo_para_conta_desativada_nao_envia_codigo_e_avisa_por_email(): void
    {
        $this->createUser(self::EMAIL)->delete();

        $this->postJson(self::REQUEST_OTP_URL, ['email' => self::EMAIL])->assertStatus(202);

        Mail::assertNotSent(OtpCodeMail::class);
        Mail::assertSent(AccountDeactivatedMail::class, fn ($mail) => $mail->hasTo(self::EMAIL));
    }

    // CAMINHO FELIZ: o token recebido no login realmente dá acesso a uma rota protegida
    // (usa o logout como exemplo de rota que exige autenticação).
    public function test_o_token_recebido_da_acesso_a_uma_rota_protegida(): void
    {
        $token = $this->loginAndGetToken(self::EMAIL);

        $this->withToken($token)
            ->json(self::LOGOUT_METHOD, self::LOGOUT_URL)
            ->assertOk();
    }

    // SEGURANÇA: rota protegida sem token -> 401 (não autenticado).
    public function test_logout_sem_token_devolve_401(): void
    {
        $this->json(self::LOGOUT_METHOD, self::LOGOUT_URL)
            ->assertUnauthorized();
    }

    // CAMINHO FELIZ: logout devolve 200 e apaga o token do banco. A conferência é feita
    // no banco (e não repetindo a requisição) porque, dentro de um mesmo teste, o Laravel
    // guarda em cache o usuário já autenticado e uma segunda chamada poderia passar.
    public function test_logout_com_token_devolve_200_e_apaga_o_token(): void
    {
        $token = $this->loginAndGetToken(self::EMAIL);
        $this->assertDatabaseCount('personal_access_tokens', 1);

        $this->withToken($token)
            ->json(self::LOGOUT_METHOD, self::LOGOUT_URL)
            ->assertOk()
            ->assertExactJson(['message' => 'Sessão encerrada.']);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    // TESTE NEGATIVO / VALOR-LIMITE: o código precisa ter exatamente 6 dígitos numéricos.
    // Testa curto (5), longo (7), com letras e com espaço no meio.
    public function test_verificar_com_codigo_de_formato_invalido_devolve_422(): void
    {
        $this->requestCode(self::EMAIL);

        foreach (['12345', '1234567', 'abcdef', '12 456'] as $invalidCode) {
            $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => $invalidCode])
                ->assertStatus(422)
                ->assertJsonValidationErrors(['code']);
        }
    }

    // SEGURANÇA/REGRA: código com formato inválido é barrado na validação e NÃO gasta
    // tentativas. Depois de 5 envios ruins (o limite é 3), o código correto ainda funciona.
    public function test_codigo_com_formato_invalido_nao_gasta_tentativas(): void
    {
        $code = $this->requestCode(self::EMAIL);

        for ($i = 0; $i < 5; $i++) {
            $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => '123'])
                ->assertStatus(422);
        }

        $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => $code])
            ->assertOk();
    }

    // BORDA: normalização de e-mail. Pedir com maiúsculas e verificar com minúsculas
    // (e o contrário, no teste seguinte) deve funcionar: "User@Example.COM" = "user@example.com".
    public function test_codigo_pedido_com_email_em_maiusculas_vale_para_o_email_em_minusculas(): void
    {
        $code = $this->requestCode('User@Example.COM');

        $this->postJson(self::VERIFY_OTP_URL, ['email' => 'user@example.com', 'code' => $code])
            ->assertOk();
    }

    // BORDA: o inverso do teste anterior.
    public function test_codigo_pedido_com_email_em_minusculas_vale_para_o_email_em_maiusculas(): void
    {
        $code = $this->requestCode('user@example.com');

        $this->postJson(self::VERIFY_OTP_URL, ['email' => 'User@Example.COM', 'code' => $code])
            ->assertOk();
    }

    // SEGURANÇA (rate limit): repetir o pedido de código até o limite devolve 429
    // (muitas requisições) com o cabeçalho Retry-After. O laço pára assim que bloqueia
    // (máximo de 100 tentativas).
    public function test_pedir_codigo_muitas_vezes_seguidas_acaba_em_429(): void
    {
        $response = null;

        for ($i = 0; $i < 100; $i++) {
            $response = $this->postJson(self::REQUEST_OTP_URL, ['email' => self::EMAIL]);

            if ($response->status() === 429) {
                break;
            }
        }

        $response->assertStatus(429);
        $response->assertHeader('Retry-After');
    }

    // SEGURANÇA (rate limit): o mesmo para a verificação, que protege contra tentativa
    // de adivinhar o código por força bruta.
    public function test_verificar_muitas_vezes_seguidas_acaba_em_429(): void
    {
        $response = null;

        for ($i = 0; $i < 100; $i++) {
            $response = $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => '000000']);

            if ($response->status() === 429) {
                break;
            }
        }

        $response->assertStatus(429);
        $response->assertHeader('Retry-After');
    }

    // ------------------------------------------------------------------
    // Auxiliares (não são testes)
    // ------------------------------------------------------------------

    // Pede o código pela API e devolve o valor que foi enviado no e-mail (capturado pelo Mail::fake).
    private function requestCode(string $email): string
    {
        $this->postJson(self::REQUEST_OTP_URL, ['email' => $email])->assertStatus(202);

        return Mail::sent(OtpCodeMail::class)->last()->code;
    }

    // Faz o fluxo completo (pedir + verificar) e devolve o token de acesso.
    private function loginAndGetToken(string $email): string
    {
        $code = $this->requestCode($email);

        return $this->postJson(self::VERIFY_OTP_URL, ['email' => $email, 'code' => $code])
            ->assertOk()
            ->json('token');
    }

    // Cria um usuário pelo repositório (sem depender de factory).
    private function createUser(string $email): User
    {
        return app(UserRepositoryInterface::class)->create([
            'email' => $email,
            'email_verified_at' => now(),
        ]);
    }
}
