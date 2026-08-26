# FlowFi Backend

Laravel 13 API backend for FlowFi. Pure JSON API — no Blade views, no web sessions. The client is the Flutter app in `platform/frontend/`. Auth is token-based via Laravel Sanctum.

## Architecture: domain slices

Business code is organized by domain, not by layer. Each domain under `app/Domains/` is a self-contained vertical slice owning its own controllers, services, repositories, models, requests, and resources:

```
app/Domains/<Domain>/
├── Controllers/     # thin HTTP layer — validate via Request, call Service, return Resource
├── Models/          # Eloquent models belonging to this domain
├── Repositories/    # <Name>RepositoryInterface + Eloquent<Name>Repository
├── Requests/        # FormRequest classes (input validation lives here, never in controllers)
├── Resources/       # JsonResource classes (output shaping for the Flutter client)
├── Services/        # business logic — one class per area, injected into controllers
└── routes.php       # this domain's routes, mounted under /api/v1
```

Current domains:

- **Identity** — users and authentication (register, login, logout, me). Complete; use it as the reference when building a new slice.
- **Ledger** — accounts and transactions (FlowFi core). Skeleton only; see `app/Domains/Ledger/README.md`.

Everything outside `app/Domains/` is framework plumbing: `app/Http/Controllers/Controller.php` (base controller), `app/Providers/` (wiring), `bootstrap/`, `config/`, `routes/`.

## Layer responsibilities

- **Controller**: ~3 lines per action. Receives a FormRequest, delegates to a Service, wraps the result in a Resource. No business logic, no queries.
- **Service**: all business logic for the domain. Depends on repository *interfaces*, never concrete Eloquent classes. Throws `ValidationException` (or domain exceptions) for business-rule failures.
- **Repository**: data access behind an interface. Interface + `Eloquent*` implementation live side by side in the domain's `Repositories/` folder.
- **Request**: input shape validation only. Business rules belong in the Service.
- **Resource**: the only place response JSON is shaped. Never return raw models from controllers.

## Wiring a new domain slice

1. Copy the `Identity/` folder shape.
2. Create the model in `<Domain>/Models/` plus a migration in `database/migrations/`.
   - Factory discovery breaks outside `App\Models`, so annotate the model with `#[UseFactory(YourFactory::class)]` (see `Identity/Models/User.php`).
3. Repository interface + Eloquent implementation, then add one line to the `$bindings` array in `app/Providers/DomainServiceProvider.php`.
4. Service with the business logic; inject the repository interface via constructor.
5. Domain `routes.php`, then mount it in `routes/api.php` inside the existing `v1` prefix group with `require app_path('Domains/<Domain>/routes.php');`.
6. Feature tests in `tests/Feature/<Domain>/` (in-memory SQLite, `RefreshDatabase`).

## Conventions

- All endpoints live under `/api/v1/...`. Never add unversioned API routes.
- Protected routes use the `auth:sanctum` middleware; clients send `Authorization: Bearer <token>`.
- `use App\Domains\Identity\Models\User;` — the User model is NOT in `App\Models` (that folder no longer exists). `config/auth.php`, `UserFactory`, and `DatabaseSeeder` already point at the domain path.
- Code style is enforced by Pint: run `./vendor/bin/pint --dirty` before committing.

## Commands

```sh
composer setup          # first-time install (env, key, migrate, npm build)
composer dev            # run the dev server
php artisan test        # run the test suite (in-memory SQLite)
php artisan route:list --path=api   # inspect registered API routes
./vendor/bin/pint --dirty           # format changed files
```

## Testing

- Feature tests hit real HTTP through the full stack (`tests/Feature/<Domain>/`), using in-memory SQLite configured in `phpunit.xml`.
- `User::factory()` default password is `password`.
- Reference: `tests/Feature/Identity/AuthTest.php` covers the full auth flow.
