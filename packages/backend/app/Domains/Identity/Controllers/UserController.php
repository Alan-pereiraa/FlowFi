<?php

namespace App\Domains\Identity\Controllers;

use App\Domains\Identity\Requests\UpdateUserRequest;
use App\Domains\Identity\Resources\UserResource;
use App\Domains\Identity\Services\UserService;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class UserController extends Controller
{
    public function __construct(
        private readonly UserService $users,
    ) {}

    public function show(Request $request): UserResource
    {
        $user = $this->users->find($request->user()->id);

        return new UserResource($user);
    }

    public function update(UpdateUserRequest $request): UserResource
    {
        $user = $this->users->update($request->user(), $request->validated());

        return new UserResource($user);
    }

    public function destroy(Request $request): Response
    {
        $this->users->delete($request->user());

        return response()->noContent();
    }
}
