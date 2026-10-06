<?php

namespace Tests\Feature\Domains\Identity;

use App\Domains\Identity\Mail\OtpCodeMail;
use Tests\TestCase;

class OtpCodeMailTest extends TestCase
{
    public function test_o_assunto_do_email_esta_correto(): void
    {
        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 10);

        $mail->assertHasSubject('Your FlowFi sign-in code');
    }

    public function test_o_email_mostra_o_codigo(): void
    {
        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 10);

        $mail->assertSeeInHtml('123456');
        $mail->assertSeeInText('123456');
    }

    public function test_o_email_mostra_o_tempo_de_expiracao(): void
    {
        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 15);

        $mail->assertSeeInHtml('expires in 15 minutes');
    }

    public function test_o_email_mostra_o_nome_do_app(): void
    {
        config(['app.name' => 'FlowFi']);

        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 10);

        $mail->assertSeeInHtml('FlowFi');
    }

    public function test_o_template_renderiza_sem_erro(): void
    {
        $mail = new OtpCodeMail(code: '123456', expiresInMinutes: 10);

        $this->assertNotEmpty($mail->render());
    }
}
