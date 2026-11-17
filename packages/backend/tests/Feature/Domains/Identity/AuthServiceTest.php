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

/**
 * TIPO: TESTE DE INTEGRAÇÃO (nível de serviço) — fica na pasta "Feature" do Laravel.
 *
 * POR QUÊ:
 *  - Não é unitário: o AuthService não é isolado. Ele é chamado de verdade junto
 *    com o OtpService, os repositórios, o banco (SQLite em memória) e o Sanctum
 *    (que gera os tokens). Nada interno é substituído por mock.
 *  - Não é E2E: não há navegador, rede nem app Flutter.
 *  - Diferença para o AuthEndpointsTest: aqui NÃO existe HTTP. Os métodos do serviço
 *    são chamados direto (requestOtp, verifyOtp, logout). Isso permite testar as
 *    regras de negócio sem o "ruído" de rotas, validação e rate limit.
 *  - O único "fake" é Mail::fake(), na fronteira do sistema (nenhum e-mail real).
 *
 * O QUE COBRE: criação e reaproveitamento de conta no primeiro login, verificação
 * de e-mail, emissão do token, bloqueio de conta desativada e logout.
 */
class AuthServiceTest extends TestCase
{
    use RefreshDatabase;

    private const EMAIL = 'user@example.com';

    // Mensagens de erro esperadas (em português, após a tradução feita pela equipe).
    private const INVALID = 'O código é inválido ou expirou.';

    private const DEACTIVATED = 'Esta conta foi desativada.';

    protected function setUp(): void
    {
        parent::setUp();

        // Fronteira do sistema: nenhum e-mail real é enviado.
        Mail::fake();

        // Fixa as regras do OTP para o teste não depender do .env.
        config([
            'auth.otp.expire' => 10,
            'auth.otp.max_attempts' => 3,
            'auth.otp.length' => 6,
        ]);
    }

    // REGRA: pedir o código envia o e-mail mesmo sem conta, mas NÃO cria a conta.
    // A conta só nasce na verificação (próximos testes).
    public function test_request_otp_envia_o_codigo_mesmo_para_email_sem_conta(): void
    {
        $this->auth()->requestOtp(self::EMAIL);

        Mail::assertSent(
            OtpCodeMail::class,
            fn (OtpCodeMail $mail) => $mail->hasTo(self::EMAIL)
        );

        $this->assertNull($this->users()->findByEmailWithTrashed(self::EMAIL));
    }

    // CAMINHO FELIZ: primeiro login. O e-mail ainda não existe, então a conta é criada
    // já com o e-mail marcado como verificado (o código provou que ele é dono do e-mail).
    public function test_verify_otp_cria_a_conta_quando_o_email_ainda_nao_existe(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $result = $this->auth()->verifyOtp(self::EMAIL, $code);

        $this->assertSame(self::EMAIL, $result['user']->email);
        $this->assertNotNull($result['user']->email_verified_at);
        $this->assertNotNull($this->users()->findByEmailWithTrashed(self::EMAIL));
    }

    // CAMINHO FELIZ: segundo login. Reaproveita a conta existente em vez de duplicar
    // (confere que só há 1 usuário com esse e-mail, contando até os apagados).
    public function test_verify_otp_reaproveita_a_conta_que_ja_existe(): void
    {
        $existing = $this->createUser(['email_verified_at' => now()]);
        $code = $this->issueCode(self::EMAIL);

        $result = $this->auth()->verifyOtp(self::EMAIL, $code);

        $this->assertTrue($result['user']->is($existing));
        $this->assertSame(1, User::withTrashed()->where('email', self::EMAIL)->count());
    }

    // REGRA: conta que existia sem e-mail verificado passa a ficar verificada após o login.
    public function test_verify_otp_marca_o_email_como_verificado_quando_ainda_nao_era(): void
    {
        $user = $this->createUser();
        $code = $this->issueCode(self::EMAIL);

        $this->auth()->verifyOtp(self::EMAIL, $code);

        $this->assertNotNull($user->fresh()->email_verified_at);
    }

    // BORDA: se o e-mail já estava verificado, a data original é preservada (não é
    // sobrescrita por um novo login). O startOfSecond evita diferença de frações de segundo.
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

    // CAMINHO FELIZ: o token devolvido existe no banco (Sanctum) e pertence ao usuário certo.
    public function test_verify_otp_devolve_um_token_que_pertence_ao_usuario(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $result = $this->auth()->verifyOtp(self::EMAIL, $code);

        $accessToken = PersonalAccessToken::findToken($result['token']);

        $this->assertNotNull($accessToken);
        $this->assertTrue($accessToken->tokenable->is($result['user']));
    }

    // TESTE NEGATIVO / SEGURANÇA: conta desativada (soft delete) não consegue entrar,
    // mesmo com um código válido nas mãos. Nenhum token é gerado e a conta não é duplicada.
    // O código é emitido direto pelo OtpService (issueCode) para simular um código que já
    // existia, já que o pedido normal de código para conta desativada agora é bloqueado.
    public function test_verify_otp_recusa_conta_desativada_e_nao_gera_token(): void
    {
        $user = $this->createUser(['email_verified_at' => now()]);
        $user->delete();
        $code = $this->issueCode(self::EMAIL);

        $this->assertVerifyFails(self::EMAIL, $code, 'email', self::DEACTIVATED);

        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->assertSame(1, User::withTrashed()->where('email', self::EMAIL)->count());
    }

    // TESTE NEGATIVO: código errado não cria conta nem token (nenhum efeito colateral).
    public function test_verify_otp_com_codigo_errado_nao_cria_conta_nem_token(): void
    {
        $code = $this->issueCode(self::EMAIL);
        // Garante um código diferente do verdadeiro, mesmo no raro caso de sorteio igual.
        $wrong = $code === '000000' ? '111111' : '000000';

        $this->assertVerifyFails(self::EMAIL, $wrong, 'code', self::INVALID);

        $this->assertNull($this->users()->findByEmailWithTrashed(self::EMAIL));
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    // CAMINHO FELIZ: o logout apaga o token usado na requisição.
    public function test_logout_apaga_o_token_usado_na_requisicao(): void
    {
        $user = $this->createUser(['email_verified_at' => now()]);
        $token = $user->createToken('api');
        // Simula o usuário autenticado com esse token (o que o Sanctum faz numa requisição real).
        $user->withAccessToken($token->accessToken);

        $this->auth()->logout($user);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    // REGRA: o logout encerra só a sessão atual; o token de outro dispositivo continua válido.
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

    // BORDA: logout sem token atual não pode dar erro. O teste não tem assert comum:
    // ele passa se nenhuma exceção for lançada (por isso o expectNotToPerformAssertions).
    public function test_logout_sem_token_atual_nao_causa_erro(): void
    {
        $user = $this->createUser(['email_verified_at' => now()]);

        $this->auth()->logout($user);

        $this->expectNotToPerformAssertions();
    }

    // ------------------------------------------------------------------
    // Auxiliares (não são testes)
    // ------------------------------------------------------------------

    private function auth(): AuthService
    {
        return app(AuthService::class);
    }

    private function users(): UserRepositoryInterface
    {
        return app(UserRepositoryInterface::class);
    }

    // Cria um usuário pelo repositório (sem depender de factory).
    private function createUser(array $attributes = []): User
    {
        return $this->users()->create(array_merge(['email' => self::EMAIL], $attributes));
    }

    // Emite um código pelo OtpService e devolve o valor enviado no e-mail (capturado pelo Mail::fake).
    private function issueCode(string $email): string
    {
        app(OtpService::class)->issue($email);

        return Mail::sent(OtpCodeMail::class)->last()->code;
    }

    // Confere que a verificação falha com ValidationException, no campo e com a mensagem esperados.
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