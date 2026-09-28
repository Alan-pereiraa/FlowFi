<?php

namespace App\Domains\Notification\Controllers;

use App\Domains\Notification\Enums\DevicePlatform;
use App\Domains\Notification\Requests\RegisterDeviceTokenRequest;
use App\Domains\Notification\Requests\UnregisterDeviceTokenRequest;
use App\Domains\Notification\Resources\DeviceTokenResource;
use App\Domains\Notification\Service\NotificationService;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;

class DeviceTokenController extends Controller
{
    public function __construct(
        private readonly NotificationService $notifications
    ) {}

    public function store(RegisterDeviceTokenRequest $request): JsonResponse
    {
        $device = $this->notifications->registerDevice(
            $request->user(),
            $request->validated('token'),
            $request->enum('platform', DevicePlatform::class)
        );

        return (new DeviceTokenResource($device))
            ->response()
            ->setStatusCode($device->wasRecentlyCreated ? Response::HTTP_CREATED : Response::HTTP_OK);
    }

    public function destroy(UnregisterDeviceTokenRequest $request): Response
    {
        $this->notifications->unregisterDevice($request->user(), $request->validated('token'));

        return response()->noContent();
    }
}
