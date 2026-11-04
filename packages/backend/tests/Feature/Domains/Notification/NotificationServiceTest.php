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

class NotificationServiceTest extends TestCase
{
    use RefreshDatabase;

    private const EMAIL = 'user@example.com';

    public function test_notify_cria_a_notificacao_e_despacha_um_push_por_dispositivo_registrado(): void
    {
        Bus::fake();

        $user = $this->createUser();
        $tokenA = $this->registerDevice($user, 'token-aparelho-a');
        $tokenB = $this->registerDevice($user, 'token-aparelho-b');

        $notification = $this->service()->notify(
            $user,
            'Meta atingida',
            'Você completou sua meta de economia.',
            NotificationType::Success,
            'goal',
            42
        );

        $this->assertSame('Meta atingida', $notification->title);
        $this->assertSame('goal', $notification->subject);

        Bus::assertDispatchedTimes(SendPushNotification::class, 2);

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

        $notification = $this->service()->notify(
            $user,
            'Lembrete',
            'Sua fatura vence amanhã.',
            NotificationType::Warning,
            'invoice',
            7
        );

        $this->assertNotNull($notification->id);
        Bus::assertNothingDispatched();
    }

    public function test_notify_once_nao_duplica_notificacao_do_mesmo_assunto_dentro_da_janela(): void
    {
        Bus::fake();

        $user = $this->createUser();
        $since = now()->subHour();

        $first = $this->service()->notifyOnce(
            $user,
            'Gasto incomum',
            'Detectamos um gasto fora do seu padrão.',
            NotificationType::Warning,
            'anomaly',
            101,
            $since
        );

        $second = $this->service()->notifyOnce(
            $user,
            'Gasto incomum',
            'Detectamos um gasto fora do seu padrão.',
            NotificationType::Warning,
            'anomaly',
            101,
            $since
        );

        $this->assertNotNull($first);
        $this->assertNull($second);

        Bus::assertDispatchedTimes(SendPushNotification::class, 0);
    }

    public function test_registrar_e_remover_dispositivo_reflete_em_quem_recebe_push(): void
    {
        $user = $this->createUser();

        $this->service()->registerDevice($user, 'token-novo', DevicePlatform::Android);
        $this->assertSame(['token-novo'], $this->deviceTokens()->tokensFor($user));

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

        $rejectingSender = new class implements PushSender
        {
            public function send(string $token, string $title, string $body, array $data = []): void
            {
                throw new InvalidDeviceToken('Token não é mais válido.');
            }
        };

        $job = new SendPushNotification($notification, 'token-expirado');
        $job->handle($rejectingSender, $this->service());

        $this->assertSame([], $this->deviceTokens()->tokensFor($user));
    }

    private function service(): NotificationService
    {
        return app(NotificationService::class);
    }

    private function deviceTokens(): DeviceTokenRepositoryInterface
    {
        return app(DeviceTokenRepositoryInterface::class);
    }

    private function createUser(): User
    {
        return app(UserRepositoryInterface::class)->create([
            'email' => self::EMAIL,
            'email_verified_at' => now(),
        ]);
    }

    private function registerDevice(User $user, string $token): string
    {
        $this->service()->registerDevice($user, $token, DevicePlatform::Android);

        return $token;
    }
}
