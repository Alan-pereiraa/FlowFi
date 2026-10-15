<?php

namespace App\Domains\Shared\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Validation\ValidationException;

class TranscriptionService
{
    /** Extension guessed from the upload's content => MIME type the Gemini API accepts for it. */
    public const array MIME_TYPES = [
        'm4a' => 'audio/m4a',
        'mp4' => 'audio/m4a',
        'weba' => 'audio/webm',
        'webm' => 'audio/webm',
        'ogg' => 'audio/ogg',
        'mp3' => 'audio/mp3',
        'wav' => 'audio/wav',
        'flac' => 'audio/flac',
        'aac' => 'audio/aac',
        'adts' => 'audio/aac',
    ];

    public function __construct(
        private readonly GeminiClient $gemini,
    ) {}

    public function transcribe(UploadedFile $audio): string
    {
        $mimeType = self::MIME_TYPES[$audio->guessExtension()] ?? throw ValidationException::withMessages([
            'audio' => 'This audio format is not supported.',
        ]);

        $transcript = trim($this->gemini->interact([
            'model' => config('services.gemini.transcribe_model'),
            'input' => [[
                'type' => 'audio',
                'data' => base64_encode($audio->get()),
                'mime_type' => $mimeType,
            ]],
            'generation_config' => [
                'transcription_config' => [
                    'mode' => 'smart',
                    'language_codes' => ['pt-BR'],
                ],
            ],
        ]));

        if ($transcript === '') {
            throw ValidationException::withMessages([
                'audio' => 'The audio could not be understood. Record it again or type the transaction.',
            ]);
        }

        return $transcript;
    }
}
