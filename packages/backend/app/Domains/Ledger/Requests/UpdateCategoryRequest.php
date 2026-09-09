<?php

namespace App\Domains\Ledger\Requests;

use App\Domains\Ledger\Services\CategoryService;
use App\Domains\Shared\Constants\IconCatalog;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateCategoryRequest extends FormRequest
{
    /**
     * Entitlement is checked here, not only in the controller, because
     * authorize() is the one hook that runs before validation. Without it a
     * malformed body aimed at someone else's category would answer 422 before
     * the request ever reached the 404. Same exception to "Request = shape
     * only" as UpdateUserRequest; the rule itself lives in CategoryService.
     *
     * @throws ModelNotFoundException
     */
    public function authorize(CategoryService $categories): bool
    {
        $categories->findOwned($this->user(), (int) $this->route('id'));

        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name' => [
                'sometimes',
                'required',
                'string',
                'max:255',
                Rule::unique('categories', 'name')
                    ->where('user_id', $this->user()->id)
                    ->whereNull('deleted_at')
                    ->ignore((int) $this->route('id')),
            ],
            'icon' => ['sometimes', 'required', 'string', Rule::in(IconCatalog::names())],
            'color' => ['sometimes', 'required', 'string', 'hex_color', 'size:7'],
            'limit_amount' => ['sometimes', 'nullable', 'numeric', 'decimal:0,2', 'min:0.01', 'max:99999999.99'],
        ];
    }
}
