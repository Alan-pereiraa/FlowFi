---
name: polish
description: Review all current changes for quality, correctness, and consistency before committing or raising a PR. Find and fix issues directly.
allowed-tools: Read Glob Grep Edit Write Bash(git diff *) Bash(git status *) Bash(git log *) Bash(ls *) Bash(cat *) Bash(php artisan test *) Bash(vendor/bin/pint *) Bash(composer *)
---

# Polish Changes

Review all current changes for quality, correctness, and consistency before committing or raising a PR. Find and fix issues directly in the files, then produce a summary.

You are a senior engineer performing a final polish pass on in-progress work. Your goal is to catch problems that are easy to miss mid-flow: dead code, style inconsistencies, anti-patterns, and violations of codebase conventions.

## Rules

- **Be surgical** — fix what's wrong, leave what's right. Only touch code within the current diff; do not refactor unrelated files you happen to read.
- **Read conventions first** — before starting, check for a `CLAUDE.md` or `AGENTS.md` in the current project directory and read it. Follow any project-specific conventions it defines.
- **Run backend commands from `packages/backend/`** — `php artisan`, `vendor/bin/pint`, and `composer` all expect that working directory.
- **Never fix pre-existing failures** — surface them in the Flagged section instead.

## Steps

### 1. Understand the Diff

```bash
git diff HEAD
git status
```

- All unstaged + staged changes
- New files not yet tracked

If the diff is empty and there are no untracked files, state that the working tree is clean and stop.

Read every changed and new file in full. Understand the intent before judging the implementation.

### 2. Run Verification (baseline)

Run the project's lint, type check, and test commands before making any edits so you know which failures pre-exist vs. which you introduce:

```bash
cd packages/backend
vendor/bin/pint --test
php artisan test
```

Note any pre-existing failures. Failures introduced by this pass must be resolved before it is complete. Pre-existing failures should be surfaced in the **Flagged** section — do not attempt to fix them.

### 3. PHP & Laravel Hygiene

Check each changed file for:

- **Unused variables / assignments** — remove any local variable assigned but never read
- **Dead code** — remove commented-out code, `dd()`/`dump()`/`var_dump()`/`ray()` statements; move any TODO comments to the Flagged section with a note on what they're blocking
- **N+1 queries** — check controller actions and scopes for missing `with()`/`load()` eager loading; flag if a loop triggers individual queries
- **Missing request validation** — ensure controller actions validate input via Form Requests or `$request->validate()`; guard mass assignment with `$fillable`/`$guarded` on models
- **Middleware hygiene** — route middleware should be scoped to the routes that need it; model events/observers should not have hidden side effects
- **Scope & query safety** — prefer Eloquent scopes and the query builder over raw SQL; use parameter bindings, never string interpolation in `whereRaw`/`DB::raw`
- **Validation completeness** — validation rules should cover presence/format/uniqueness where migrations define `NOT NULL` or unique constraints
- **Route conventions** — RESTful resource routes preferred; no orphan routes pointing to non-existent controller actions

### 4. View & Frontend Hygiene

Check changed Blade and JavaScript files for:

- **Blade escaping** — use `{{ }}` (escaped) by default; `{!! !!}` (raw) only when explicitly safe HTML is intended
- **Asset wiring** — JS/CSS entry points referenced via `@vite()` match entries in `vite.config.js`; no dead script/style references
- **Tailwind consistency** — follow existing patterns in the codebase (e.g., color palette, spacing conventions); no inline styles when Tailwind classes exist
- **Component extraction** — if a view block is duplicated across files in the diff, extract to a Blade component or partial (`@include`/`<x-*>`)
- **I18n** — user-facing strings should use `__()` helpers with keys in `lang/`; hardcoded Portuguese strings are acceptable only if the app is pt-BR only and follows existing patterns

### 5. Test Hygiene

Check changed test files for:

- **Factory usage** — use `Model::factory()->create()` not `Model::create()` directly; ensure factories exist in `database/factories/`
- **Missing tests** — new public controller actions or model methods should have corresponding tests in `tests/Feature/` or `tests/Unit/`
- **Deterministic tests** — no reliance on database ordering without explicit `orderBy()`; no time-dependent tests without `$this->travelTo()`/`Carbon::setTestNow()`
- **Laravel test helpers** — prefer `assertDatabaseHas()`, `assertJson()`, `RefreshDatabase`, and HTTP test helpers (`$this->getJson()`, `postJson()`) over hand-rolled assertions

### 6. Codebase Pattern Compliance

Check against patterns already established in this repo:

- **Controller structure** — follows the existing pattern in `app/Http/Controllers/` (route-model binding, thin actions, validation delegated to Form Requests)
- **Migrations** — schema changes go through new migrations in `database/migrations/`; never edit an already-run migration
- **Shared logic** — reusable behavior belongs in traits, base classes, or dedicated support classes, not duplicated across controllers/models
- **Namespacing** — new controllers, models, and requests follow the existing `App\` PSR-4 structure; API routes grouped consistently in `routes/api.php`
- **Service extraction** — complex business logic should not live in controllers; suggest extraction if a controller action exceeds ~20 lines of business logic

### 7. Security Quick-Check

- **Authorization** — controller actions that modify data should have appropriate checks (policies/gates, or ownership scoping like `$request->user()->transactions()`); API routes protected by `auth:sanctum` where needed
- **CSRF** — web form submissions should include `@csrf`; no routes excluded from CSRF verification unless justified
- **Mass assignment** — no unguarded `$request->all()` passed into `create()`/`update()`; use `$request->validated()`
- **File uploads** — uploads should validate content type and file size via validation rules (`file`, `mimes`, `max`)

### 8. Summary

After all fixes are applied, produce:

**Changes made**: A numbered list of every edit, with file path and one-line description.

**Flagged** (do not fix): Pre-existing issues, TODOs found in diff, or problems outside the scope of current changes.

**Verification result**: Output of lint/test/security commands after your edits — confirm no new failures were introduced.
