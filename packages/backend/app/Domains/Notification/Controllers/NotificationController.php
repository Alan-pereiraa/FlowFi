<?php

namespace App\Domains\Notification\Controllers;

use App\Domains\Notification\Resources\NotificationResource;
use App\Domains\Notification\Service\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use App\Http\Controllers\Controller;
use App\Domains\Notification\Requests\ListNotificationsRequest;

class NotificationController extends Controller
{
    public function __construct(
        private readonly NotificationService $notifications
    ) {}

    public function index(ListNotificationsRequest $request): AnonymousResourceCollection
    {
        return NotificationResource::collection($this->notifications->list(
            $request->user(),
            min(max($request->integer('per_page', 20), 1), 100),
            $request->validated('status')
        ));
    }

    public function markAsRead(Request $request, int $id): NotificationResource
    {
        return new NotificationResource($this->notifications->markAsRead(
            $this->notifications->findOwned($request->user(), $id)
        ));
    }

    public function destroy(Request $request, int $id): Response
    {
        $this->notifications->delete(
            $this->notifications->findOwned($request->user(), $id)
        );

        return response()->noContent();
    }
}