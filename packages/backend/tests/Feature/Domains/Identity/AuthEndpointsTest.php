<?php

namespace Tests\Feature\Domains\Identity;

use App\Domains\Identity\Mail\AccountDeactivatedMail;
use App\Domains\Identity\Mail\OtpCodeMail;
use App\Domains\Identity\Models\User;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class AuthEndpointsTest extends TestCase
{
    use RefreshDatabase;

    private const REQUEST_OTP_URL = '/api/v1/auth/otp/request';

    private const VERIFY_OTP_URL = '/api/v1/auth/otp/verify';

    private const LOGOUT_URL = '/api/v1/auth/logout';

    private const LOGOUT_METHOD = 'POST';

    private const EMAIL = 'user@example.com';

    protected function setUp(): void
    {
        parent::setUp();

        Mail::fake();

        config([
            'auth.otp.expire' => 10,
            'auth.otp.max_attempts' => 3,
            'auth.otp.length' => 6,
        ]);
    }

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

    public function test_pedir_codigo_responde_igual_para_email_com_e_sem_conta(): void
    {
        $this->createUser('existe@example.com');

        $withAccount = $this->postJson(self::REQUEST_OTP_URL, ['email' => 'existe@example.com']);
        $withoutAccount = $this->postJson(self::REQUEST_OTP_URL, ['email' => 'nao-existe@example.com']);

        $withAccount->assertStatus(202);
        $withoutAccount->assertStatus(202);
        $this->assertSame($withAccount->json(), $withoutAccount->json());
    }

    public function test_pedir_codigo_sem_email_devolve_422_e_nao_envia_email(): void
    {
        $this->postJson(self::REQUEST_OTP_URL, [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);

        Mail::assertNothingSent();
    }

    public function test_pedir_codigo_com_email_invalido_devolve_422_e_nao_envia_email(): void
    {
        $this->postJson(self::REQUEST_OTP_URL, ['email' => 'isto-nao-e-um-email'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email']);

        Mail::assertNothingSent();
    }

    public function test_verificar_com_codigo_correto_devolve_usuario_e_token(): void
    {
        $code = $this->requestCode(self::EMAIL);

        $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => $code])
            ->assertOk()
            ->assertJsonStructure(['user', 'token']);
    }

    public function test_verificar_com_codigo_errado_devolve_422_e_nenhum_token(): void
    {
        $code = $this->requestCode(self::EMAIL);
        $wrong = $code === '000000' ? '111111' : '000000';

        $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => $wrong])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['code'])
            ->assertJsonMissingPath('token');

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_verificar_sem_os_campos_obrigatorios_devolve_422(): void
    {
        $this->postJson(self::VERIFY_OTP_URL, [])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['email', 'code']);
    }

    public function test_pedir_codigo_para_conta_desativada_nao_envia_codigo_e_avisa_por_email(): void
    {
        $this->createUser(self::EMAIL)->delete();

        $this->postJson(self::REQUEST_OTP_URL, ['email' => self::EMAIL])->assertStatus(202);

        Mail::assertNotSent(OtpCodeMail::class);
        Mail::assertSent(AccountDeactivatedMail::class, fn ($mail) => $mail->hasTo(self::EMAIL));
    }

    public function test_o_token_recebido_da_acesso_a_uma_rota_protegida(): void
    {
        $token = $this->loginAndGetToken(self::EMAIL);

        $this->withToken($token)
            ->json(self::LOGOUT_METHOD, self::LOGOUT_URL)
            ->assertOk();
    }

    public function test_logout_sem_token_devolve_401(): void
    {
        $this->json(self::LOGOUT_METHOD, self::LOGOUT_URL)
            ->assertUnauthorized();
    }

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

    public function test_verificar_com_codigo_de_formato_invalido_devolve_422(): void
    {
        $this->requestCode(self::EMAIL);

        foreach (['12345', '1234567', 'abcdef', '12 456'] as $invalidCode) {
            $this->postJson(self::VERIFY_OTP_URL, ['email' => self::EMAIL, 'code' => $invalidCode])
                ->assertStatus(422)
                ->assertJsonValidationErrors(['code']);
        }
    }

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

    public function test_codigo_pedido_com_email_em_maiusculas_vale_para_o_email_em_minusculas(): void
    {
        $code = $this->requestCode('User@Example.COM');

        $this->postJson(self::VERIFY_OTP_URL, ['email' => 'user@example.com', 'code' => $code])
            ->assertOk();
    }

    public function test_codigo_pedido_com_email_em_minusculas_vale_para_o_email_em_maiusculas(): void
    {
        $code = $this->requestCode('user@example.com');

        $this->postJson(self::VERIFY_OTP_URL, ['email' => 'User@Example.COM', 'code' => $code])
            ->assertOk();
    }

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

    private function requestCode(string $email): string
    {
        $this->postJson(self::REQUEST_OTP_URL, ['email' => $email])->assertStatus(202);

        return Mail::sent(OtpCodeMail::class)->last()->code;
    }

    private function loginAndGetToken(string $email): string
    {
        $code = $this->requestCode($email);

        return $this->postJson(self::VERIFY_OTP_URL, ['email' => $email, 'code' => $code])
            ->assertOk()
            ->json('token');
    }

    private function createUser(string $email): User
    {
        return app(UserRepositoryInterface::class)->create([
            'email' => $email,
            'email_verified_at' => now(),
        ]);
    }
}
