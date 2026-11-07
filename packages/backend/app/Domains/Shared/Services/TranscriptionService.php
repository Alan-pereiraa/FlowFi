<?php

namespace App\Domains\Shared\Services;

use Illuminate\Http\UploadedFile;
use Illuminate\Validation\ValidationException;

class TranscriptionService
{
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
            'audio' => 'Este formato de áudio não é suportado.',
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
                'audio' => 'Não foi possível entender o áudio. Grave novamente ou digite a transação.',
            ]);
        }

        return $transcript;
    }
}
