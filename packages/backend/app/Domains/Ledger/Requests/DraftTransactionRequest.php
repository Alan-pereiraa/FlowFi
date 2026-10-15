<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Shared\Services\TranscriptionService;
use Illuminate\Foundation\Http\FormRequest;

class DraftTransactionRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'audio' => [
                'required_without:raw_context',
                'prohibits:raw_context',
                'file',
                'mimes:'.implode(',', array_keys(TranscriptionService::MIME_TYPES)),
                'max:2048',
            ],
            'raw_context' => ['required_without:audio', 'string', 'max:1000'],
        ];
    }
}
