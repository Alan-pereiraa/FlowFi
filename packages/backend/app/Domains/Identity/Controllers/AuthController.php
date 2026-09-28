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
        tags: ['Authentication'],
        summary: 'Request an OTP code',
        description: 'Emails a one-time code (config auth.otp.length digits, 6 by default) that expires in config auth.otp.expire minutes. Throttled per email and per IP.',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/RequestOtpRequest'),
        ),
        responses: [
            new OA\Response(
                response: 202,
                description: 'Code sent to the email address',
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
        tags: ['Authentication'],
        summary: 'Verify OTP and log in',
        description: 'Consumes the code. Creates the account on the first login. Deactivated accounts get 422.',
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/VerifyOtpRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'Login successful',
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
        tags: ['Authentication'],
        summary: 'Log out (revoke current token)',
        security: [['sanctum' => []]],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Logged out',
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
