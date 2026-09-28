<?php

namespace App\Domains\Identity\Controllers;

use App\Domains\Identity\Requests\UpdateUserRequest;
use App\Domains\Identity\Resources\UserResource;
use App\Domains\Identity\Services\UserService;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use OpenApi\Attributes as OA;

class UserController extends Controller
{
    public function __construct(
        private readonly UserService $users,
    ) {}

    #[OA\Get(
        path: '/users/{id}',
        operationId: 'getUser',
        tags: ['Users'],
        summary: 'Get user',
        description: 'Only the authenticated user\'s own ID is accessible; any other ID returns 404.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'User',
                content: new OA\JsonContent(ref: '#/components/schemas/UserResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function show(Request $request, int $id): UserResource
    {
        return new UserResource($this->users->findOwned($request->user(), $id));
    }

    #[OA\Put(
        path: '/users/{id}',
        operationId: 'putUser',
        tags: ['Users'],
        summary: 'Update user (PUT)',
        description: 'Uses the same partial-update behavior as PATCH.',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateUserRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'User updated',
                content: new OA\JsonContent(ref: '#/components/schemas/UserResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    #[OA\Patch(
        path: '/users/{id}',
        operationId: 'updateUser',
        tags: ['Users'],
        summary: 'Update user',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(ref: '#/components/schemas/UpdateUserRequest'),
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: 'User updated',
                content: new OA\JsonContent(ref: '#/components/schemas/UserResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function update(UpdateUserRequest $request, int $id): UserResource
    {
        $user = $this->users->findOwned($request->user(), $id);

        return new UserResource($this->users->update($user, $request->validated()));
    }

    #[OA\Delete(
        path: '/users/{id}',
        operationId: 'deleteUser',
        tags: ['Users'],
        summary: 'Delete user',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(response: 204, description: 'Deleted'),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function destroy(Request $request, int $id): Response
    {
        $this->users->delete($this->users->findOwned($request->user(), $id));

        return response()->noContent();
    }
}
