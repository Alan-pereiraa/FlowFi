<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Foundation\Console\ServeCommand;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->shareEnvironmentWithServeCommand();
        $this->configureRateLimiting();
    }

    /**
     * `php artisan serve` only forwards a fixed whitelist of environment
     * variables to the process that actually handles requests; everything else
     * is stripped and the request falls back to whatever `.env` says. The API
     * container is configured through compose `environment:`, so the mail
     * variables have to be added to that whitelist or Docker would silently
     * mail through the host's `.env` settings instead of Mailpit.
     */
    private function shareEnvironmentWithServeCommand(): void
    {
        if (! class_exists(ServeCommand::class)) {
            return;
        }

        ServeCommand::$passthroughVariables = array_unique(array_merge(
            ServeCommand::$passthroughVariables,
            [
                'MAIL_MAILER',
                'MAIL_SCHEME',
                'MAIL_HOST',
                'MAIL_PORT',
                'MAIL_USERNAME',
                'MAIL_PASSWORD',
                'MAIL_FROM_ADDRESS',
                'MAIL_FROM_NAME',
            ],
        ));
    }

    /**
     * Named limiters referenced as `throttle:<name>` in domain routes.
     */
    private function configureRateLimiting(): void
    {
        RateLimiter::for('otp-request', function (Request $request): array {
            $email = strtolower(trim((string) $request->input('email')));

            return [
                Limit::perMinute(3)->by('email:'.($email !== '' ? $email : $request->ip())),
                Limit::perMinute(10)->by('ip:'.$request->ip()),
            ];
        });

        RateLimiter::for('otp-verify', function (Request $request): Limit {
            return Limit::perMinute(10)->by('ip:'.$request->ip());
        });
    }
}
