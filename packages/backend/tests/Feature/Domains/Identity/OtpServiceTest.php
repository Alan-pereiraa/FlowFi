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

/**
 * TIPO: TESTE DE INTEGRAÇÃO (nível de serviço) — fica na pasta "Feature" do Laravel.
 *
 * POR QUÊ:
 *  - Não é unitário: o OtpService não é isolado. Ele roda de verdade junto com o
 *    repositório, o banco (SQLite em memória), o gerador de hash e o relógio do
 *    Laravel. Nada interno é substituído por mock.
 *  - Não é E2E: não há HTTP, navegador, rede nem app Flutter. Os métodos do serviço
 *    (issue e consume) são chamados direto.
 *  - O único "fake" é Mail::fake(), na fronteira do sistema (nenhum e-mail real).
 *
 * POR QUE É O ARQUIVO MAIS IMPORTANTE DO OTP: aqui estão as regras de segurança do
 * código de acesso — gerar, guardar só o hash, expirar, limitar tentativas, usar uma
 * única vez e aceitar apenas o código mais recente.
 *
 * O QUE COBRE: duas operações do serviço.
 *   issue()   -> gerar o código, salvar (com hash) e enviar por e-mail.
 *   consume() -> validar o código informado e marcá-lo como usado.
 */
class OtpServiceTest extends TestCase
{
    use RefreshDatabase;

    // Mensagens de erro esperadas (em português, após a tradução feita pela equipe).
    private const INVALID = 'O código é inválido ou expirou.';

    private const TOO_MANY_ATTEMPTS = 'Muitas tentativas. Solicite um novo código.';

    private const EMAIL = 'user@example.com';

    protected function setUp(): void
    {
        parent::setUp();

        // Fronteira do sistema: nenhum e-mail real é enviado.
        Mail::fake();

        // Fixa as regras do OTP para o teste não depender do .env:
        // validade de 10 min, no máximo 3 tentativas, código de 6 dígitos.
        config([
            'auth.otp.expire' => 10,
            'auth.otp.max_attempts' => 3,
            'auth.otp.length' => 6,
        ]);
    }

    // ==================================================================
    // issue(): gerar, salvar e enviar o código
    // ==================================================================

    // CAMINHO FELIZ: ao emitir o código, o e-mail é enviado para o destinatário certo.
    public function test_issue_envia_o_email_para_o_destinatario(): void
    {
        $this->service()->issue(self::EMAIL);

        Mail::assertSent(
            OtpCodeMail::class,
            fn (OtpCodeMail $mail) => $mail->hasTo(self::EMAIL)
        );
    }

    // VALOR-LIMITE: o código só tem dígitos e o tamanho configurado (4, 6 e 8). Repete 20
    // vezes cada tamanho porque o código é aleatório; assim pega o caso de zero à esquerda
    // (ex.: "004821") que sumiria se o número fosse tratado como inteiro.
    public function test_issue_gera_codigo_numerico_com_o_tamanho_configurado(): void
    {
        foreach ([4, 6, 8] as $length) {
            config(['auth.otp.length' => $length]);

            for ($i = 0; $i < 20; $i++) {
                $code = $this->issueCode(self::EMAIL);

                $this->assertMatchesRegularExpression('/^\d{'.$length.'}$/', $code);
            }
        }
    }

    // CONTEÚDO DINÂMICO: o prazo informado no e-mail vem da configuração (15), e não de
    // um valor fixo no código.
    public function test_issue_informa_o_tempo_de_expiracao_no_email(): void
    {
        config(['auth.otp.expire' => 15]);

        $this->service()->issue(self::EMAIL);

        Mail::assertSent(
            OtpCodeMail::class,
            fn (OtpCodeMail $mail) => $mail->expiresInMinutes === 15
        );
    }

    // SEGURANÇA: o banco guarda só o hash do código, nunca o código em texto puro.
    // Se o banco vazar, os códigos não ficam expostos. Hash::check prova que o hash
    // salvo corresponde ao código enviado.
    public function test_issue_salva_o_hash_e_nao_o_codigo_em_texto_puro(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $record = $this->latestRecord(self::EMAIL);

        $this->assertNotSame($code, $record->code_hash);
        $this->assertTrue(Hash::check($code, $record->code_hash));
    }

    // ESTADO INICIAL: o código nasce válido (não expirado), não usado e com 0 tentativas.
    // Este teste também confere que a coluna "attempts" tem valor inicial 0 no banco.
    public function test_issue_cria_um_codigo_novo_valido_e_sem_tentativas(): void
    {
        $this->service()->issue(self::EMAIL);

        $record = $this->latestRecord(self::EMAIL);

        $this->assertFalse($record->isExpired());
        $this->assertFalse($record->isConsumed());
        $this->assertSame(0, $record->attempts);
    }

    // CÁLCULO: a expiração fica exatamente 10 minutos à frente. O freezeTime() congela o
    // relógio, senão o "agora" mudaria entre a emissão e a conferência e o teste ficaria instável.
    public function test_issue_define_a_expiracao_conforme_a_configuracao(): void
    {
        $this->freezeTime();

        $this->service()->issue(self::EMAIL);

        $this->assertSame(
            now()->addMinutes(10)->timestamp,
            $this->latestRecord(self::EMAIL)->expires_at->timestamp
        );
    }

    // SEGURANÇA: o hash do código também não aparece quando o registro é convertido em
    // array/JSON (campo escondido no model). Evita vazar o hash numa resposta da API.
    public function test_o_hash_do_codigo_nao_aparece_quando_o_registro_e_serializado(): void
    {
        $this->service()->issue(self::EMAIL);

        $this->assertArrayNotHasKey(
            'code_hash',
            $this->latestRecord(self::EMAIL)->toArray()
        );
    }

    // ==================================================================
    // consume(): validar o código informado
    // ==================================================================

    // CAMINHO FELIZ: o código correto é aceito e o registro fica marcado como usado.
    public function test_consume_aceita_o_codigo_correto_e_marca_como_usado(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->service()->consume(self::EMAIL, $code);

        $this->assertTrue($this->latestRecord(self::EMAIL)->isConsumed());
    }

    // SEGURANÇA: uso único. O mesmo código, depois de aceito, não vale uma segunda vez.
    public function test_consume_rejeita_um_codigo_que_ja_foi_usado(): void
    {
        $code = $this->issueCode(self::EMAIL);
        $this->service()->consume(self::EMAIL, $code);

        $this->assertConsumeFails(self::EMAIL, $code, self::INVALID);
    }

    // TESTE NEGATIVO: código errado devolve o erro genérico "inválido ou expirou". A mensagem
    // é a mesma para errado, expirado e inexistente, para não dar pistas a quem tenta adivinhar.
    public function test_consume_rejeita_codigo_errado(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->assertConsumeFails(self::EMAIL, $this->wrongCodeFor($code), self::INVALID);
    }

    // SEGURANÇA (importante): a tentativa errada é CONTADA mesmo quando o erro é lançado.
    // Se o erro desfizesse a transação do banco, o contador voltaria a 0 e o limite de
    // tentativas (proteção contra força bruta) deixaria de funcionar.
    public function test_consume_conta_a_tentativa_errada_mesmo_lancando_erro(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->assertConsumeFails(self::EMAIL, $this->wrongCodeFor($code), self::INVALID);

        $this->assertSame(1, $this->latestRecord(self::EMAIL)->attempts);
    }

    // VALOR-LIMITE: com limite de 3, errar 2 vezes ainda deixa a 3ª tentativa (a certa)
    // passar. Prova que o bloqueio não acontece cedo demais.
    public function test_consume_aceita_o_codigo_correto_depois_de_erros_dentro_do_limite(): void
    {
        $code = $this->issueCode(self::EMAIL);
        $wrong = $this->wrongCodeFor($code);

        $this->assertConsumeFails(self::EMAIL, $wrong, self::INVALID);
        $this->assertConsumeFails(self::EMAIL, $wrong, self::INVALID);

        $this->service()->consume(self::EMAIL, $code);

        $this->assertTrue($this->latestRecord(self::EMAIL)->isConsumed());
    }

    // SEGURANÇA / VALOR-LIMITE: depois de 3 erros, até o código CORRETO é recusado, com a
    // mensagem "Muitas tentativas". Impede adivinhar o código por tentativa e erro.
    public function test_consume_bloqueia_depois_do_limite_de_tentativas(): void
    {
        $code = $this->issueCode(self::EMAIL);
        $wrong = $this->wrongCodeFor($code);

        for ($i = 0; $i < 3; $i++) {
            $this->assertConsumeFails(self::EMAIL, $wrong, self::INVALID);
        }

        $this->assertConsumeFails(self::EMAIL, $code, self::TOO_MANY_ATTEMPTS);
        $this->assertFalse($this->latestRecord(self::EMAIL)->isConsumed());
    }

    // EXPIRAÇÃO: o travelTo() avança o relógio 11 minutos (a validade é 10) e o código
    // deixa de valer. É assim que se testa tempo sem esperar de verdade.
    public function test_consume_rejeita_codigo_expirado(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->travelTo(now()->addMinutes(11));

        $this->assertConsumeFails(self::EMAIL, $code, self::INVALID);
    }

    // EXPIRAÇÃO (lado oposto): aos 9 minutos o código ainda vale. Junto com o teste
    // anterior, cerca o limite de 10 minutos pelos dois lados.
    public function test_consume_aceita_codigo_ainda_dentro_do_prazo(): void
    {
        $code = $this->issueCode(self::EMAIL);

        $this->travelTo(now()->addMinutes(9));

        $this->service()->consume(self::EMAIL, $code);

        $this->assertTrue($this->latestRecord(self::EMAIL)->isConsumed());
    }

    // TESTE NEGATIVO: e-mail que nunca pediu código recebe o mesmo erro genérico, sem
    // exceção inesperada (nada de erro 500) e sem revelar que não há registro.
    public function test_consume_rejeita_email_que_nunca_pediu_codigo(): void
    {
        $this->assertConsumeFails('ninguem@example.com', '123456', self::INVALID);
    }

    // REGRA: só o código mais recente vale. Pedir um novo código invalida o anterior,
    // mesmo ele ainda estando dentro do prazo. O travelTo de 1 segundo garante datas de
    // criação diferentes; o do-while evita o raríssimo caso de dois códigos iguais.
    public function test_consume_considera_apenas_o_codigo_mais_recente(): void
    {
        $first = $this->issueCode(self::EMAIL);

        $this->travelTo(now()->addSecond());

        do {
            $second = $this->issueCode(self::EMAIL);
        } while ($second === $first);

        $this->assertConsumeFails(self::EMAIL, $first, self::INVALID);

        $this->service()->consume(self::EMAIL, $second);

        $this->assertTrue($this->latestRecord(self::EMAIL)->isConsumed());
    }

    // SEGURANÇA / ISOLAMENTO: o código emitido para um e-mail não funciona para outro.
    // O while evita o raro caso de os dois e-mails sortearem o mesmo código.
    public function test_consume_nao_aceita_o_codigo_de_outro_email(): void
    {
        $codeA = $this->issueCode('a@example.com');
        $codeB = $this->issueCode('b@example.com');

        while ($codeA === $codeB) {
            $codeB = $this->issueCode('b@example.com');
        }

        $this->assertConsumeFails('b@example.com', $codeA, self::INVALID);
    }

    // ------------------------------------------------------------------
    // Auxiliares (não são testes)
    // ------------------------------------------------------------------

    private function service(): OtpService
    {
        return app(OtpService::class);
    }

    // Emite um código e devolve o valor enviado no e-mail (capturado pelo Mail::fake).
    private function issueCode(string $email): string
    {
        $this->service()->issue($email);

        return Mail::sent(OtpCodeMail::class)->last()->code;
    }

    // Busca no banco o registro de código mais recente do e-mail, para conferir o estado.
    private function latestRecord(string $email)
    {
        return app(OtpCodeRepositoryInterface::class)->findLatestByEmail($email);
    }

    // Devolve um código com o mesmo formato, mas garantidamente diferente do verdadeiro.
    private function wrongCodeFor(string $code): string
    {
        $wrong = str_repeat('0', strlen($code));

        return $wrong === $code ? str_repeat('1', strlen($code)) : $wrong;
    }

    // Confere que consume() falha com ValidationException no campo "code" e com a mensagem esperada.
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
