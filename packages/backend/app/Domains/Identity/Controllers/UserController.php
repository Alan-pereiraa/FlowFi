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

    public function show(Request $request, int $id): UserResource
    {
        return new UserResource($this->users->findOwned($request->user(), $id));
    }

    public function update(UpdateUserRequest $request, int $id): UserResource
    {
        $user = $this->users->findOwned($request->user(), $id);

        return new UserResource($this->users->update($user, $request->validated()));
    }

    public function destroy(Request $request, int $id): Response
    {
        $this->users->delete($this->users->findOwned($request->user(), $id));

        return response()->noContent();
    }
}
