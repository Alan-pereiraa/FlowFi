<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Ledger\Services\GoalService;
use App\Domains\Shared\Constants\IconCatalog;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateGoalRequest extends FormRequest
{
    /**
     * Entitlement is checked here, not only in the controller, because
     * authorize() is the one hook that runs before validation. Without it a
     * malformed body aimed at someone else's goal would answer 422 before the
     * request ever reached the 404. Same exception to "Request = shape only"
     * as UpdateUserRequest; the rule itself lives in GoalService.
     *
     * @throws ModelNotFoundException
     */
    public function authorize(GoalService $goals): bool
    {
        $goals->findOwned($this->user(), (int) $this->route('id'));

        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'icon' => ['sometimes', 'required', 'string', Rule::in(IconCatalog::names())],
            'color' => ['sometimes', 'required', 'string', 'hex_color', 'size:7'],
            'target_amount' => ['sometimes', 'required', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
            'expires_at' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
        ];
    }
}
