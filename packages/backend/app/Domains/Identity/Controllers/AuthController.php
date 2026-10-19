<?php

namespace App\Domains\Identity\Controllers;

use App\Domains\Identity\Requests\LogoutRequest;
use App\Domains\Identity\Requests\RequestOtpRequest;
use App\Domains\Identity\Requests\VerifyOtpRequest;
use App\Domains\Identity\Resources\UserResource;
use App\Domains\Identity\Services\AuthService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use OpenApi\Attributes as OA;
class AuthController extends Controller
{
    public function __construct(
        private readonly AuthService $auth,
    ) {}

    #[OA\Post(
        path: '/auth/otp/request',
        operationId: 'requestOtp',
        tags: ['Autenticação'],
        summary: 'Solicitar código OTP',
        description: 'Envia por e-mail um código de uso único (config auth.otp.length dígitos, 6 por padrão) que expira em config auth.otp.expire minutos. Limitado por e-mail e por IP.',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/RequestOtpRequest'),
        ),
        responses: [
            new OA\Response(
                response: 202,
                description: 'Código enviado para o e-mail',
                content: new OA\JsonContent(ref: '#/components/schemas/MessageResponse'),
            ),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
            new OA\Response(response: 429, ref: '#/components/responses/TooManyRequestsResponse'),
        ],
    )]
    public function requestOtp(RequestOtpRequest $request): JsonResponse
    {
        $this->auth->requestOtp($request->validated('email'));

        return response()->json(['message' => 'Code sent.'], 202);
    }

    #[OA\Post(
        path: '/auth/otp/verify',
        operationId: 'verifyOtp',
        tags: ['Autenticação'],
        summary: 'Verificar OTP e entrar',
        description: 'Consome o código. Cria a conta no primeiro login. Contas desativadas recebem 422.',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/VerifyOtpRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Login realizado',
                content: new OA\JsonContent(ref: '#/components/schemas/AuthTokenResponse'),
            ),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
            new OA\Response(response: 429, ref: '#/components/responses/TooManyRequestsResponse'),
        ],
    )]
    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        $result = $this->auth->verifyOtp(
            $request->validated('email'),
            $request->validated('code'),
        );

        return response()->json([
            'user' => new UserResource($result['user']),
            'token' => $result['token'],
        ]);
    }

    #[OA\Post(
        path: '/auth/logout',
        operationId: 'logout',
        tags: ['Autenticação'],
        summary: 'Sair (revoga o token atual)',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Sessão encerrada',
                content: new OA\JsonContent(ref: '#/components/schemas/MessageResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
        ],
    )]

    public function logout(LogoutRequest $request): JsonResponse
    {
        $this->auth->logout($request->user(), $request->validated('device_token'));

        return response()->json(['message' => 'Logged out.']);
    }
}
