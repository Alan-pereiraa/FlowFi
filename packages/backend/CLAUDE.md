# FlowFi Backend

Laravel 13 API backend for FlowFi. Pure JSON API — no Blade pages, no web sessions (the only Blade files are Markdown mail templates under `resources/views/mail/`). The client is the Flutter app in `platform/frontend/`. Auth is passwordless: an emailed one-time code is exchanged for a Laravel Sanctum bearer token.

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

- **Identity** — users and authentication (OTP request/verify, logout, and `users.show`/`update`/`destroy`). Complete; use it as the reference when building a new slice. Auth flow: `POST /auth/otp/request` mails a 6-digit code (`OtpService::issue`, row appended to `otp_codes`, never pruned), `POST /auth/otp/verify` burns it and finds-or-creates the user (`AuthService::verifyOtp`). Only `email` is required on `users`; there is no password column. Knobs live in `config/auth.php` under `otp`; throttling in `AppServiceProvider`. Mail is sent synchronously (no queue worker in dev) and lands in Mailpit at http://localhost:8025.
  - Self-service CRUD is `GET|PUT|PATCH|DELETE /api/v1/users/{id}`. Entitlement lives in exactly one place, `UserService::findOwned()`, which throws `ModelNotFoundException` when the id is not the caller's. **Every failure is a 404, never a 403** — a 403 would confirm the account exists. `UpdateUserRequest::authorize()` calls the same method so the 404 beats validation; this is a deliberate exception to the "Request: input shape validation only" rule below. There is no `index` or `store` route and no admin surface: an admin would belong at `/admin/users/{id}` with its own authorization.
- **Ledger** — money records (FlowFi core): goals, categories, transactions and installments (see `docs/erd.md`). Goals and categories are full CRUD at `/api/v1/goals[/{id}]` and `/api/v1/categories[/{id}]`, scoped to the caller through `User::goals()` / `User::categories()`: the repository's `findFor()` returns null for a foreign, missing or soft-deleted id and the service's `findOwned()` turns that into a generic 404 (`new ModelNotFoundException('Not found.')`), same reasoning as Identity. `Update*Request::authorize()` runs the same gate so 404 beats 422. The two slices are file-for-file twins (`Goal*` / `Category*`); when one changes shape, mirror it in the other. Money columns are integer cents behind the `Money` cast (below); the API speaks decimals. In both, `name` is unique per user among live rows, enforced only by `Rule::unique(...)->where('user_id')->whereNull('deleted_at')` in the FormRequests — there is deliberately no DB unique index because it would block re-using a soft-deleted name (the categories migration comment explains). Comparison is case-sensitive on SQLite. Category-only: `limit_amount` is a nullable cap (null = no limit).
  - **Transactions & installments** — full CRUD at `/api/v1/transactions[/{id}]`, plus `PATCH /transactions/{transactionId}/installments/{installmentId}/pay`. `GET /transactions` is paginated (`per_page`, default 20, max 100) and takes optional filters `type`, `category_id`, `date_from` and `date_to`; the date range is matched against the installments, so a transaction is listed only when it started and ended inside it (its first installment is on or after `date_from` and its last is on or before `date_to`; either bound may be omitted). `Installment` is an auxiliary table of `Transaction`, not a sibling module: it has no CRUD controller or service of its own — only the `pay` action — and every write to it goes through `TransactionService`. A transaction always owns 1..n installments, generated one of three ways depending on what's in the request body: (1) neither `installments` nor `installments_count` sent → a single installment for the full amount, due on the transaction's `date` (`schedule_type = single`); (2) `installments_count` (+ optional `period_unit`/`period_interval`, default `month`/`1`) → an even split, one installment every period, with any leftover cent front-loaded onto the first installments so the sum always matches `total_amount` exactly (`schedule_type = periodic`); (3) an explicit `installments: [{amount, date}, ...]` array → each installment's own amount and due date, in any order (sorted chronologically on save), so gaps between installments don't have to be uniform (`schedule_type = custom`). `total_amount` and the sum of an explicit `installments` list must always agree in cents. All of this scheduling logic lives in `InstallmentPlanner` (pure, no persistence: `planFromInput()` turns the request body into the schedule and `transactionScheduleAttributes()` derives the schedule columns stored on the transaction row) plus `TransactionService` (orchestration, ownership, the DB transaction). Installments have no repository of their own: `EloquentTransactionRepository` also owns their persistence (`replaceInstallments`, `findInstallmentFor`, `markInstallmentPaid`) and stays dumb. Editing a transaction re-derives the *entire* schedule whenever any of `total_amount` / `installments` / `installments_count` / `period_unit` / `period_interval` is present in the `PATCH` body — merging omitted fields in from the transaction's current values, so e.g. sending only `{"period_unit": "day", "period_interval": 15}` re-plans the existing amount and installment count onto a new cadence. Plain fields (`category_id`, `goal_id`, `type`, `description`, `date`) update independently and never touch the schedule on their own. Once any installment has `status = paid`, the schedule is frozen: a `PATCH` that would regenerate it gets a 422 (`TransactionService::guardAgainstPaidInstallments()`) instead of silently reshuffling money that already moved. Deleting a transaction soft-deletes its installments too (`TransactionService::delete()`) — the FK's `cascadeOnDelete()` never fires for this since `SoftDeletes` turns `delete()` into an `UPDATE`, not a real SQL `DELETE`, so it's cascaded explicitly in the service instead.
- **Shared** — cross-domain utilities, not a business domain. `Constants/IconCatalog` (Flutter Material `Icons` names, categorized; served at `GET /api/v1/icons`), `Casts/Money` (integer cents in the database, `"1500.00"` strings in PHP and JSON), and `Services/AppearanceService` + `Contracts/HasAppearance` (icon/color handling for any decorated model: call `normalize()` on create and `apply()` on update so stored colors are always `#RRGGBB` uppercase). Goal and Category both use all three; add new shared helpers here only when a second domain actually needs them.

Everything outside `app/Domains/` is framework plumbing: `app/Http/Controllers/Controller.php` (base controller), `app/Providers/` (wiring), `bootstrap/`, `config/`, `routes/`.

Cross-slice references are allowed but should stay rare and explicit. Today: `Identity\Models\User::goals()` and `User::categories()` point at `Ledger\Models\Goal` / `Category`, and Ledger depends on Shared.

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
- Owned collections: query through the relation on `User` (`$user->goals()`, `$user->categories()`), never `Model::where('user_id', ...)`; every miss is a 404 with the generic message, never a 403.
- Money: store cents in an unsigned integer column and cast with `App\Domains\Shared\Casts\Money`; validate input with `numeric`, `decimal:0,2`; never do float arithmetic on amounts.
- SQLite does not index foreign keys on its own: write `foreignId(...)->index()->constrained()`, in that order (`index()` after `constrained()` is a silent no-op).
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
- There is no password: authenticate in tests with `$this->withToken($user->createToken('api')->plainTextToken)`.
- Reference: `tests/Feature/Identity/AuthTest.php` (token-protected profile read, guest 401, logout) and `tests/Feature/Ledger/TransactionTest.php` (all three installment-generation strategies, re-planning on update, the paid-installment lock, and the 404-not-403 rule). The OTP flow, the goals CRUD and the categories CRUD are currently covered by curl smoke suites, not PHPUnit.
