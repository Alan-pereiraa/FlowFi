<?php

namespace Tests\Feature\Domains\Identity;

use App\Domains\Identity\Mail\OtpCodeMail;
use App\Domains\Identity\Repositories\OtpCodeRepositoryInterface;
use App\Domains\Identity\Services\OtpService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

class OtpServiceTest extends TestCase
{
    use RefreshDatabase;

    private const INVALID = 'The code is invalid or has expired.';

    private const TOO_MANY_ATTEMPTS = 'Too many attempts. Request a new code.';

    private const EMAIL = 'user@example.com';

    protected function setUp(): void
    {
        parent::setUp();

        // Impede o envio real de e-mails e guarda o que "seria" enviado.
        Mail::fake();

        config([
            'auth.otp.expire' => 10,
            'auth.otp.max_attempts' => 3,
            'auth.otp.length' => 6,
        ]);
    }

    // ------------------------------------------------------------------
    // issue(): gerar e enviar o código
    // ------------------------------------------------------------------

    public function test_issue_envia_o_email_para_o_destinatario(): void
    {
        $this->service()->issue(self::EMAIL);

        Mail::assertSent(
            OtpCodeMail::class,
            fn (OtpCodeMail $mail) => $mail->hasTo(self::EMAIL)
        );
    }

    public function test_issue_gera_codigo_numerico_com_o_tamanho_configurado(): void
    {
        foreach ([4, 6, 8] as $length) {
            config(['auth.otp.length' => $length]);

            // Repete várias vezes: garante que zeros à esquerda não somem.
            for ($i = 0; $i < 20; $i++) {
                $code = $this->issueCode(self::EMAIL);

                $this->assertMatchesRegularExpression('/^\d{'.$length.'}$/', $code);
            }
        }
    }

    public function test_issue_informa_o_tempo_de_expiracao_no_email(): void
    {
        config(['auth.otp.expire' => 15]);

        $this->service()->issue(self::EMAIL);

        Mail::assertSent(
            OtpCodeMail::class,
            fn (OtpCodeMail $mail) => $mail->expiresInMinutes === 15
        );
    }

    public function test_issue_salva_o_hash_e_nao_o_codigo_em_texto_puro(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $record = $this->latestRecord(self::EMAIL);

        $this->assertNotSame($code, $record->code_hash);
        $this->assertTrue(Hash::check($code, $record->code_hash));
    }

    public function test_issue_cria_um_codigo_novo_valido_e_sem_tentativas(): void
    {
        $this->service()->issue(self::EMAIL);

        $record = $this->latestRecord(self::EMAIL);

        $this->assertFalse($record->isExpired());
        $this->assertFalse($record->isConsumed());
        $this->assertSame(0, $record->attempts);
    }

    public function test_issue_define_a_expiracao_conforme_a_configuracao(): void
    {
        $this->freezeTime();

        $this->service()->issue(self::EMAIL);

        $this->assertSame(
            now()->addMinutes(10)->timestamp,
            $this->latestRecord(self::EMAIL)->expires_at->timestamp
        );
    }

    public function test_o_hash_do_codigo_nao_aparece_quando_o_registro_e_serializado(): void
    {
        $this->service()->issue(self::EMAIL);

        $this->assertArrayNotHasKey(
            'code_hash',
            $this->latestRecord(self::EMAIL)->toArray()
        );
    }

    // ------------------------------------------------------------------
    // consume(): validar o código
    // ------------------------------------------------------------------

    public function test_consume_aceita_o_codigo_correto_e_marca_como_usado(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->service()->consume(self::EMAIL, $code);

        $this->assertTrue($this->latestRecord(self::EMAIL)->isConsumed());
    }

    public function test_consume_rejeita_um_codigo_que_ja_foi_usado(): void
    {
        $code = $this->issueCode(self::EMAIL);
        $this->service()->consume(self::EMAIL, $code);

        $this->assertConsumeFails(self::EMAIL, $code, self::INVALID);
    }

    public function test_consume_rejeita_codigo_errado(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->assertConsumeFails(self::EMAIL, $this->wrongCodeFor($code), self::INVALID);
    }

    public function test_consume_conta_a_tentativa_errada_mesmo_lancando_erro(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->assertConsumeFails(self::EMAIL, $this->wrongCodeFor($code), self::INVALID);

        // Se a exceção desfizesse a transação, isso voltaria para 0.
        $this->assertSame(1, $this->latestRecord(self::EMAIL)->attempts);
    }

    public function test_consume_aceita_o_codigo_correto_depois_de_erros_dentro_do_limite(): void
    {
        $code = $this->issueCode(self::EMAIL);
        $wrong = $this->wrongCodeFor($code);

        $this->assertConsumeFails(self::EMAIL, $wrong, self::INVALID);
        $this->assertConsumeFails(self::EMAIL, $wrong, self::INVALID);

        // Limite é 3: a terceira tentativa ainda é permitida.
        $this->service()->consume(self::EMAIL, $code);

        $this->assertTrue($this->latestRecord(self::EMAIL)->isConsumed());
    }

    public function test_consume_bloqueia_depois_do_limite_de_tentativas(): void
    {
        $code = $this->issueCode(self::EMAIL);
        $wrong = $this->wrongCodeFor($code);

        for ($i = 0; $i < 3; $i++) {
            $this->assertConsumeFails(self::EMAIL, $wrong, self::INVALID);
        }

        // Mesmo o código CORRETO é recusado depois de estourar o limite.
        $this->assertConsumeFails(self::EMAIL, $code, self::TOO_MANY_ATTEMPTS);
        $this->assertFalse($this->latestRecord(self::EMAIL)->isConsumed());
    }

    public function test_consume_rejeita_codigo_expirado(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->travelTo(now()->addMinutes(11));

        $this->assertConsumeFails(self::EMAIL, $code, self::INVALID);
    }

    public function test_consume_aceita_codigo_ainda_dentro_do_prazo(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->travelTo(now()->addMinutes(9));

        $this->service()->consume(self::EMAIL, $code);

        $this->assertTrue($this->latestRecord(self::EMAIL)->isConsumed());
    }

    public function test_consume_rejeita_email_que_nunca_pediu_codigo(): void
    {
        $this->assertConsumeFails('ninguem@example.com', '123456', self::INVALID);
    }

    public function test_consume_considera_apenas_o_codigo_mais_recente(): void
    {
        $first = $this->issueCode(self::EMAIL);

        // Garante created_at diferente entre os dois códigos.
        $this->travelTo(now()->addSecond());

        do {
            $second = $this->issueCode(self::EMAIL);
        } while ($second === $first);

        $this->assertConsumeFails(self::EMAIL, $first, self::INVALID);

        $this->service()->consume(self::EMAIL, $second);

        $this->assertTrue($this->latestRecord(self::EMAIL)->isConsumed());
    }

    public function test_consume_nao_aceita_o_codigo_de_outro_email(): void
    {
        $codeA = $this->issueCode('a@example.com');
        $codeB = $this->issueCode('b@example.com');

        // Evita o (raríssimo) caso de os dois códigos sorteados serem iguais.
        while ($codeA === $codeB) {
            $codeB = $this->issueCode('b@example.com');
        }

        $this->assertConsumeFails('b@example.com', $codeA, self::INVALID);
    }

    // ------------------------------------------------------------------
    // Auxiliares
    // ------------------------------------------------------------------

    private function service(): OtpService
    {
        return app(OtpService::class);
    }

    /** Pede um código e devolve o valor que foi enviado por e-mail. */
    private function issueCode(string $email): string
    {
        $this->service()->issue($email);

        return Mail::sent(OtpCodeMail::class)->last()->code;
    }

    private function latestRecord(string $email)
    {
        return app(OtpCodeRepositoryInterface::class)->findLatestByEmail($email);
    }

    /** Devolve um código com o mesmo formato, mas garantidamente diferente. */
    private function wrongCodeFor(string $code): string
    {
        $wrong = str_repeat('0', strlen($code));

        return $wrong === $code ? str_repeat('1', strlen($code)) : $wrong;
    }

    private function assertConsumeFails(string $email, string $code, string $message): void
    {
        try {
            $this->service()->consume($email, $code);
        } catch (ValidationException $e) {
            $this->assertSame([$message], $e->errors()['code']);

            return;
        }

        $this->fail('Era esperada uma ValidationException, mas o código foi aceito.');
    }
}
