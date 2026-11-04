<?php

namespace App\Domains\Ledger\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionDraftResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'transcript' => $this->resource['transcript'],
            'kind' => $this->resource['kind'],
            'draft' => $this->resource['draft'],
        ];
    }
}
