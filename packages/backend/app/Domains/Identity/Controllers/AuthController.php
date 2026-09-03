<?php

namespace App\Domains\Identity\Controllers;

use App\Domains\Identity\Requests\RequestOtpRequest;
use App\Domains\Identity\Requests\VerifyOtpRequest;
use App\Domains\Identity\Resources\UserResource;
use App\Domains\Identity\Services\AuthService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private readonly AuthService $auth,
    ) {}

    public function requestOtp(RequestOtpRequest $request): JsonResponse
    {
        $this->auth->requestOtp($request->validated('email'));

        return response()->json(['message' => 'Code sent.'], 202);
    }

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

    public function logout(Request $request): JsonResponse
    {
        $this->auth->logout($request->user());

        return response()->json(['message' => 'Logged out.']);
    }
}
