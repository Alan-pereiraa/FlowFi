<?php

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        //
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $wantsJson = fn (Request $request) => $request->is('api/*') || $request->expectsJson();

        $exceptions->shouldRenderJsonWhen($wantsJson);

        $exceptions->render(function (AuthenticationException $e, Request $request) use ($wantsJson) {
            if ($wantsJson($request)) {
                return response()->json(['message' => 'Não autenticado.'], 401);
            }
        });

        $exceptions->render(function (HttpExceptionInterface $e, Request $request) use ($wantsJson) {
            $message = match ($e->getStatusCode()) {
                403 => 'Ação não autorizada.',
                404 => 'Não encontrado.',
                405 => 'Método não permitido.',
                429 => 'Muitas tentativas. Aguarde um momento.',
                500 => 'Erro interno do servidor.',
                default => null,
            };

            if ($message !== null && $wantsJson($request)) {
                return response()->json(['message' => $message], $e->getStatusCode(), $e->getHeaders());
            }
        });

        $exceptions->render(function (Throwable $e, Request $request) use ($wantsJson) {
            $handledElsewhere = $e instanceof HttpExceptionInterface
                || $e instanceof AuthenticationException
                || $e instanceof ValidationException
                || $e instanceof HttpResponseException;

            if (! $handledElsewhere && ! config('app.debug') && $wantsJson($request)) {
                return response()->json(['message' => 'Erro interno do servidor.'], 500);
            }
        });
    })->create();
