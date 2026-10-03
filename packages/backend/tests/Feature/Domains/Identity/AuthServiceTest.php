<?php

namespace Tests\Feature\Domains\Identity;

use App\Domains\Identity\Mail\OtpCodeMail;
use App\Domains\Identity\Models\User;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use App\Domains\Identity\Services\AuthService;
use App\Domains\Identity\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;
use Tests\TestCase;

class AuthServiceTest extends TestCase
{
    use RefreshDatabase;

    private const EMAIL = 'user@example.com';

    private const INVALID = 'The code is invalid or has expired.';

    private const DEACTIVATED = 'This account has been deactivated.';

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

    // ------------------------------------------------------------------
    // requestOtp()
    // ------------------------------------------------------------------

    public function test_request_otp_envia_o_codigo_mesmo_para_email_sem_conta(): void
    {
        $this->auth()->requestOtp(self::EMAIL);

        Mail::assertSent(
            OtpCodeMail::class,
            fn (OtpCodeMail $mail) => $mail->hasTo(self::EMAIL)
        );

        // Pedir o código não cria conta: ela só nasce na verificação.
        $this->assertNull($this->users()->findByEmailWithTrashed(self::EMAIL));
    }

    // ------------------------------------------------------------------
    // verifyOtp()
    // ------------------------------------------------------------------

    public function test_verify_otp_cria_a_conta_quando_o_email_ainda_nao_existe(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $result = $this->auth()->verifyOtp(self::EMAIL, $code);

        $this->assertSame(self::EMAIL, $result['user']->email);
        $this->assertNotNull($result['user']->email_verified_at);
        $this->assertNotNull($this->users()->findByEmailWithTrashed(self::EMAIL));
    }

    public function test_verify_otp_reaproveita_a_conta_que_ja_existe(): void
    {
        $existing = $this->createUser(['email_verified_at' => now()]);
        $code = $this->issueCode(self::EMAIL);

        $result = $this->auth()->verifyOtp(self::EMAIL, $code);

        $this->assertTrue($result['user']->is($existing));
        $this->assertSame(1, User::withTrashed()->where('email', self::EMAIL)->count());
    }

    public function test_verify_otp_marca_o_email_como_verificado_quando_ainda_nao_era(): void
    {
        $user = $this->createUser();
        $code = $this->issueCode(self::EMAIL);

        $this->auth()->verifyOtp(self::EMAIL, $code);

        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    public function test_verify_otp_nao_altera_a_data_de_verificacao_que_ja_existe(): void
    {
        $verifiedAt = now()->subDays(30)->startOfSecond();
        $user = $this->createUser(['email_verified_at' => $verifiedAt]);
        $code = $this->issueCode(self::EMAIL);

        $this->auth()->verifyOtp(self::EMAIL, $code);

        $this->assertSame(
            $verifiedAt->timestamp,
            $user->fresh()->email_verified_at->timestamp
        );
    }

    public function test_verify_otp_devolve_um_token_que_pertence_ao_usuario(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $result = $this->auth()->verifyOtp(self::EMAIL, $code);

        $accessToken = PersonalAccessToken::findToken($result['token']);

        $this->assertNotNull($accessToken);
        $this->assertTrue($accessToken->tokenable->is($result['user']));
    }

    public function test_verify_otp_recusa_conta_desativada_e_nao_gera_token(): void
    {
        $user = $this->createUser(['email_verified_at' => now()]);
        $user->delete();
        $code = $this->issueCode(self::EMAIL);

        $this->assertVerifyFails(self::EMAIL, $code, 'email', self::DEACTIVATED);

        $this->assertDatabaseCount('personal_access_tokens', 0);
        // A conta desativada continua sendo a única com esse e-mail.
        $this->assertSame(1, User::withTrashed()->where('email', self::EMAIL)->count());
    }

    public function test_verify_otp_com_codigo_errado_nao_cria_conta_nem_token(): void
    {
        $code = $this->issueCode(self::EMAIL);
        $wrong = $code === '000000' ? '111111' : '000000';

        $this->assertVerifyFails(self::EMAIL, $wrong, 'code', self::INVALID);

        $this->assertNull($this->users()->findByEmailWithTrashed(self::EMAIL));
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    // ------------------------------------------------------------------
    // logout()
    // ------------------------------------------------------------------

    public function test_logout_apaga_o_token_usado_na_requisicao(): void
    {
        $user = $this->createUser(['email_verified_at' => now()]);
        $token = $user->createToken('api');
        $user->withAccessToken($token->accessToken);

        $this->auth()->logout($user);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_logout_preserva_os_tokens_de_outros_dispositivos(): void
    {
        $user = $this->createUser(['email_verified_at' => now()]);
        $current = $user->createToken('api');
        $other = $user->createToken('api');
        $user->withAccessToken($current->accessToken);

        $this->auth()->logout($user);

        $this->assertDatabaseCount('personal_access_tokens', 1);
        $this->assertDatabaseHas('personal_access_tokens', ['id' => $other->accessToken->id]);
    }

    public function test_logout_sem_token_atual_nao_causa_erro(): void
    {
        $user = $this->createUser(['email_verified_at' => now()]);

        $this->auth()->logout($user);

        $this->expectNotToPerformAssertions();
    }

    // ------------------------------------------------------------------
    // Auxiliares
    // ------------------------------------------------------------------

    private function auth(): AuthService
    {
        return app(AuthService::class);
    }

    private function users(): UserRepositoryInterface
    {
        return app(UserRepositoryInterface::class);
    }

    /**
     * Cria um usuário pelo repositório (sem depender de factory).
     * Se a tabela users exigir outras colunas (name, password...), acrescente aqui.
     */
    private function createUser(array $attributes = []): User
    {
        return $this->users()->create(array_merge(['email' => self::EMAIL], $attributes));
    }

    /** Pede um código e devolve o valor que foi enviado por e-mail. */
    private function issueCode(string $email): string
    {
        app(OtpService::class)->issue($email);

        return Mail::sent(OtpCodeMail::class)->last()->code;
    }

    private function assertVerifyFails(string $email, string $code, string $field, string $message): void
    {
        try {
            $this->auth()->verifyOtp($email, $code);
        } catch (ValidationException $e) {
            $this->assertSame([$message], $e->errors()[$field]);

            return;
        }

        $this->fail('Era esperada uma ValidationException, mas a verificação passou.');
    }
}
