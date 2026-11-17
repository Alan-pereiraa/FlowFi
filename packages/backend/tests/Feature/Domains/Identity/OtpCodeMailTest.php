<?php

namespace Tests\Feature\Domains\Identity;

use App\Domains\Identity\Mail\OtpCodeMail;
use Tests\TestCase;

/**
 * TIPO: TESTE UNITÁRIO DE COMPONENTE (o mais "unitário" de todos os arquivos de teste
 * do OTP), embora esteja na pasta "Feature" e estenda o TestCase do Laravel.
 *
 * POR QUÊ:
 *  - Testa UMA única classe, o e-mail OtpCodeMail, sem passar por rota, controller,
 *    service nem banco de dados (repare que não há RefreshDatabase aqui).
 *  - Não é 100% isolado: o Laravel precisa estar carregado para renderizar o template
 *    Blade do e-mail e ler a configuração (por isso estende TestCase). Por isso o
 *    nome mais preciso é "teste de componente", e não "unitário puro".
 *  - Não é integração nem E2E: não há HTTP, banco, fila nem envio de e-mail de verdade.
 *    O e-mail só é montado e renderizado em memória.
 *
 * O QUE COBRE: o conteúdo do e-mail do código de acesso — assunto, código, prazo de
 * expiração, nome do app e renderização do template sem erro.
 *
 */
class OtpCodeMailTest extends TestCase
{
    // CONTEÚDO: o assunto do e-mail é exatamente o esperado.
    public function test_o_assunto_do_email_esta_correto(): void
    {
        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 10);

        $mail->assertHasSubject('Seu código de acesso ao FlowFi');
    }

    // CONTEÚDO: o código aparece no e-mail, nas duas versões que o Laravel gera
    // a partir do template markdown: HTML (para o app de e-mail) e texto puro.
    public function test_o_email_mostra_o_codigo(): void
    {
        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 10);

        $mail->assertSeeInHtml('123456');
        $mail->assertSeeInText('123456');
    }

    // CONTEÚDO DINÂMICO: o prazo vem do parâmetro, e não de um texto fixo. Usa 15 (e não
    // o 10 dos outros testes) para provar que o valor mostrado muda conforme o informado.
    public function test_o_email_mostra_o_tempo_de_expiracao(): void
    {
        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 15);

        $mail->assertSeeInHtml('expira em 15 minutos');
    }

    // CONTEÚDO: o nome do app aparece no e-mail. O config() fixa o nome dentro do teste,
    // para o resultado não depender do valor do .env de cada máquina.
    public function test_o_email_mostra_o_nome_do_app(): void
    {
        config(['app.name' => 'FlowFi']);

        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 10);

        $mail->assertSeeInHtml('FlowFi');
    }

    // TESTE DE FUMAÇA: o template renderiza sem lançar erro e devolve algo não vazio.
    // Pega problemas como variável faltando ou erro de sintaxe no Blade.
    public function test_o_template_renderiza_sem_erro(): void
    {
        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 10);

        $this->assertNotEmpty($mail->render());
    }
}