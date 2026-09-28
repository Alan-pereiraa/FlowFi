<?php

namespace App\Domains\Notification\Controllers;

use App\Domains\Notification\Requests\ListNotificationsRequest;
use App\Domains\Notification\Resources\NotificationResource;
use App\Domains\Notification\Service\NotificationService;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use OpenApi\Attributes as OA;

class NotificationController extends Controller
{
    public function __construct(
        private readonly NotificationService $notifications
    ) {}

    #[OA\Get(
        path: '/notifications',
        operationId: 'listNotifications',
        tags: ['Notifications'],
        summary: 'List notifications (paginated)',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(
                name: 'per_page',
                in: 'query',
                description: 'Page size; values outside 1-100 are clamped',
                schema: new OA\Schema(type: 'integer', minimum: 1, maximum: 100, default: 20),
            ),
            new OA\Parameter(
                name: 'status',
                in: 'query',
                schema: new OA\Schema(type: 'string', enum: ['read', 'unread']),
            ),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Paginated notifications',
                content: new OA\JsonContent(ref: '#/components/schemas/NotificationPageResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 422, ref: '#/components/responses/ValidationErrorResponse'),
        ],
    )]
    public function index(ListNotificationsRequest $request): AnonymousResourceCollection
    {
        return NotificationResource::collection($this->notifications->list(
            $request->user(),
            min(max($request->integer('per_page', 20), 1), 100),
            $request->validated('status')
        ));
    }

    #[OA\Patch(
        path: '/notifications/{id}/read',
        operationId: 'markNotificationAsRead',
        tags: ['Notifications'],
        summary: 'Mark notification as read',
        security: [['sanctum' => []]],
        parameters: [
            new OA\Parameter(ref: '#/components/parameters/IdPath'),
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: 'Notification marked as read',
                content: new OA\JsonContent(ref: '#/components/schemas/NotificationResponse'),
            ),
            new OA\Response(response: 401, ref: '#/components/responses/UnauthorizedResponse'),
            new OA\Response(response: 404, ref: '#/components/responses/NotFoundResponse'),
        ],
    )]
    public function markAsRead(Request $request, int $id): NotificationResource
    {
        return new NotificationResource($this->notifications->markAsRead(
            $this->notifications->findOwned($request->user(), $id)
        ));
    }

    #[OA\Delete(
        path: '/notifications/{id}',
        operationId: 'deleteNotification',
        tags: ['Notifications'],
        summary: 'Delete notification',
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
        $this->notifications->delete(
            $this->notifications->findOwned($request->user(), $id)
        );

        return response()->noContent();
    }
}
