<?php

namespace Tests\Feature\Domains\Notification;

use App\Domains\Identity\Models\User;
use App\Domains\Identity\Repositories\UserRepositoryInterface;
use App\Domains\Notification\Contracts\PushSender;
use App\Domains\Notification\Enums\DevicePlatform;
use App\Domains\Notification\Enums\NotificationType;
use App\Domains\Notification\Exceptions\InvalidDeviceToken;
use App\Domains\Notification\Jobs\SendPushNotification;
use App\Domains\Notification\Repositories\DeviceTokenRepositoryInterface;
use App\Domains\Notification\Service\NotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Bus;
use Tests\TestCase;

/**
 * TESTE DE INTEGRAÇÃO
 *
 * Verifica a integração entre o serviço de notificações, os repositórios,
 * o banco de dados e o sistema de filas do Laravel.
 *
 * Avalia a criação de notificações, o envio de push para dispositivos
 * registrados, a prevenção de duplicidades e a remoção de tokens inválidos.
 */

class NotificationServiceTest extends TestCase
{
    // Reinicia o banco de dados antes de cada teste.
    use RefreshDatabase;

    private const EMAIL = 'user@example.com';

    public function test_notify_cria_a_notificacao_e_despacha_um_push_por_dispositivo_registrado(): void
    {
        // Simula o sistema de filas para verificar os Jobs sem executá-los.
        Bus::fake();

        $user = $this->createUser();
        $tokenA = $this->registerDevice($user, 'token-aparelho-a');
        $tokenB = $this->registerDevice($user, 'token-aparelho-b');

        // Cria a notificação e solicita o envio para os dispositivos registrados.
        $notification = $this->service()->notify(
            $user,
            'Meta atingida',
            'Você completou sua meta de economia.',
            NotificationType::Success,
            'goal',
            42
        );

        // Verifica os dados da notificação criada.
        $this->assertSame('Meta atingida', $notification->title);
        $this->assertSame('goal', $notification->subject);

        // Verifica se foi despachado um Job para cada dispositivo.
        Bus::assertDispatchedTimes(SendPushNotification::class, 2);

        // Confirma se cada Job está associado ao token e à notificação corretos.
        foreach ([$tokenA, $tokenB] as $token) {
            Bus::assertDispatched(
                SendPushNotification::class,
                fn (SendPushNotification $job) => $job->token === $token
                    && $job->notification->is($notification)
            );
        }
    }

    public function test_notify_sem_dispositivo_registrado_cria_a_notificacao_mas_nao_despacha_push(): void
    {
        Bus::fake();

        $user = $this->createUser();

        // Cria uma notificação para um usuário sem dispositivos registrados.
        $notification = $this->service()->notify(
            $user,
            'Lembrete',
            'Sua fatura vence amanhã.',
            NotificationType::Warning,
            'invoice',
            7
        );

        // Confirma que a notificação foi criada, mesmo sem dispositivos.
        $this->assertNotNull($notification->id);

        // Garante que nenhum Job de envio push foi despachado.
        Bus::assertNothingDispatched();
    }

    public function test_notify_once_nao_duplica_notificacao_do_mesmo_assunto_dentro_da_janela(): void
    {
        Bus::fake();

        $user = $this->createUser();

        // Define uma janela de verificação iniciada uma hora antes.
        $since = now()->subHour();

        // Realiza a primeira tentativa de criação da notificação.
        $first = $this->service()->notifyOnce(
            $user,
            'Gasto incomum',
            'Detectamos um gasto fora do seu padrão.',
            NotificationType::Warning,
            'anomaly',
            101,
            $since
        );

        // Tenta criar novamente a mesma notificação dentro da janela.
        $second = $this->service()->notifyOnce(
            $user,
            'Gasto incomum',
            'Detectamos um gasto fora do seu padrão.',
            NotificationType::Warning,
            'anomaly',
            101,
            $since
        );

        // Confirma que a primeira notificação foi criada.
        $this->assertNotNull($first);

        // Confirma que a segunda tentativa foi bloqueada para evitar duplicidade.
        $this->assertNull($second);

        // Verifica que nenhum Job de envio push foi despachado.
        Bus::assertDispatchedTimes(SendPushNotification::class, 0);
    }

    public function test_registrar_e_remover_dispositivo_reflete_em_quem_recebe_push(): void
    {
        $user = $this->createUser();

        // Registra um dispositivo Android e verifica sua inclusão.
        $this->service()->registerDevice($user, 'token-novo', DevicePlatform::Android);
        $this->assertSame(['token-novo'], $this->deviceTokens()->tokensFor($user));

        // Remove o dispositivo e verifica se o token foi excluído.
        $this->service()->unregisterDevice($user, 'token-novo');
        $this->assertSame([], $this->deviceTokens()->tokensFor($user));
    }

    public function test_job_remove_o_dispositivo_quando_o_push_sender_recusa_por_token_invalido(): void
    {
        Bus::fake();

        $user = $this->createUser();
        $this->registerDevice($user, 'token-expirado');

        $notification = $this->service()->notify(
            $user,
            'Categoria sem limite',
            'Configure um limite para essa categoria.',
            NotificationType::Info,
            'category',
            5
        );

        // Simula um serviço de envio que rejeita tokens inválidos.
        $rejectingSender = new class implements PushSender
        {
            public function send(string $token, string $title, string $body, array $data = []): void
            {
                throw new InvalidDeviceToken('Token não é mais válido.');
            }
        };

        // Executa o Job e verifica o tratamento da exceção de token inválido.
        $job = new SendPushNotification($notification, 'token-expirado');
        $job->handle($rejectingSender, $this->service());

        // Confirma que o dispositivo com token inválido foi removido.
        $this->assertSame([], $this->deviceTokens()->tokensFor($user));
    }

    // Obtém os serviços e repositórios por meio do container de dependências do Laravel.
    private function service(): NotificationService
    {
        return app(NotificationService::class);
    }

    private function deviceTokens(): DeviceTokenRepositoryInterface
    {
        return app(DeviceTokenRepositoryInterface::class);
    }

    // Cria um usuário de teste utilizando o repositório correspondente.
    private function createUser(): User
    {
        return app(UserRepositoryInterface::class)->create([
            'email' => self::EMAIL,
            'email_verified_at' => now(),
        ]);
    }

    // Registra um dispositivo Android e retorna seu token.
    private function registerDevice(User $user, string $token): string
    {
        $this->service()->registerDevice($user, $token, DevicePlatform::Android);

        return $token;
    }
}
