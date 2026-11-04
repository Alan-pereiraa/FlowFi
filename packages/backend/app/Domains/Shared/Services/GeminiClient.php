<?php

namespace App\Domains\Shared\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpKernel\Exception\HttpException;

class GeminiClient
{
    public function interact(array $body): string
    {
        try {
            $response = Http::baseUrl((string) config('services.gemini.url'))
                ->withHeaders(['x-goog-api-key' => (string) config('services.gemini.key')])
                ->acceptJson()
                ->timeout((int) config('services.gemini.timeout'))
                ->post('interactions', [...$body, 'store' => false]);
        } catch (ConnectionException $exception) {
            throw $this->failure($exception->getMessage());
        }

        if ($response->failed() || $response->json('status') !== 'completed') {
            throw $this->failure(
                (string) ($response->json('error.message') ?? $response->json('status') ?? 'unexpected response'),
                $response->status(),
            );
        }

        return collect($response->json('steps', []))
            ->where('type', 'model_output')
            ->flatMap(fn (array $step): array => $step['content'] ?? [])
            ->where('type', 'text')
            ->pluck('text')
            ->implode('');
    }

    private function failure(string $reason, ?int $status = null): HttpException
    {
        Log::warning('Gemini request failed.', ['status' => $status, 'reason' => $reason]);

        return in_array($status, [429, 503], true)
            ? new HttpException(503, 'The AI provider is busy. Try again in a moment.')
            : new HttpException(502, 'The AI provider could not process this request. Try again or fill in the transaction manually.');
    }
}
