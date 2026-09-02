---
name: plan-critique
description: Structured devil's advocate review of an implementation plan. Surfaces gaps, risks, and missing pieces — then applies amendments directly. Append "dry-run" to only report.
argument-hint: "[optional: path to plan file] [optional: 'dry-run' to report only]"
allowed-tools: Read Glob Grep Edit Bash(ls *) Bash(cat *) Bash(git log *) Bash(git diff *) Bash(git show *) Bash(git blame *) Bash(php artisan route:list *) Bash(cd packages/backend && php artisan route:list *) Bash(composer show *) Bash(cd packages/backend && composer show *) WebFetch WebSearch AskUserQuestion
---

# Plan Critique

Review the current implementation plan as a structured devil's advocate. Surface gaps, risks, and missing pieces — then apply amendments directly to the plan.

## Arguments

$ARGUMENTS — Optional path to a plan file, and/or `dry-run` to only report without applying changes (e.g., "docs/plans/expense-categories.md", "dry-run", "docs/plans/expense-categories.md dry-run"). If empty, defaults to critique-and-fix mode against the current plan.

**Locating the plan** (in order):

1. A file path in $ARGUMENTS.
2. The active plan-mode plan file (the plan produced by `/build-plan` or EnterPlanMode).
3. The most recent plan written in this conversation.

If none exists, use AskUserQuestion to ask where the plan is — do not invent one.

## Rules

- **Default mode: critique and fix.** After reporting issues, apply all critical amendments and suggestions directly to the plan.
- **`dry-run` mode**: If $ARGUMENTS contains `dry-run`, report all issues but do NOT modify the plan.
- **Preserve plan intent.** Fix gaps, risks, and missing pieces — do not change the overall goal or approach unless it's fundamentally flawed.
- **Surgical amendments only.** Add missing steps, fix incorrect assumptions, strengthen weak areas — do not rewrite the entire plan.
- **Never touch source code.** The only file this skill edits is the plan itself. Findings about code become plan amendments, not fixes.
- **Evidence, not opinion.** Every critical issue must cite the file (and line where useful) that proves it — e.g., "`app/Providers/DomainServiceProvider.php:18` has no binding for the new repository".
- **Read conventions first.** Read `packages/backend/CLAUDE.md` before reviewing; its domain-slice rules are the baseline the plan is judged against.
- **Timebox verification.** If you've read 15+ files and a lens is still unresolved, record it as an open question in the plan instead of digging further.

## Steps

Work through each of these lenses systematically. For each, actively search the codebase to verify — don't rely on what's already been stated in the plan.

### 1. Completeness

- Are all affected files listed? Grep for imports and usages of every class, method, and route being changed.
- Are there files that will break if the listed changes are made but aren't included in the plan?
- Is there a test plan? Are the right test files identified (`packages/backend/tests/Feature/<Domain>/`, Flutter tests in `platform/frontend/test/`)?
- Are database migrations accounted for if schema changes are involved? Do factories and seeders in `database/factories/` / `database/seeders/` need updating too?
- Are route changes reflected in the domain's `routes.php` and, for a new domain, mounted in `packages/backend/routes/api.php` under the `v1` prefix? Verify with `php artisan route:list --path=api`.
- New repository interface → is the binding added to `$bindings` in `app/Providers/DomainServiceProvider.php`?
- New model outside `App\Models` → is `#[UseFactory(...)]` on the model and a factory planned?
- Does the plan have the sections `/build-plan` produces (Files to change/create, Tests, Out of scope, Rollback / cleanup, Open questions)? Missing sections are gaps to fill.

### 2. Correctness of Approach

- Are there simpler alternatives that weren't considered?
- Does the approach follow the domain-slice layering in `packages/backend/CLAUDE.md`? Controller ~3 lines → Service → Repository interface; validation in a FormRequest; JSON shaped only by a Resource; no raw models returned.
- Does it put business logic in a controller or Request, or query Eloquent directly from a Service instead of through the repository interface?
- Does this approach introduce technical debt or cut against existing conventions? Compare against the `Identity` domain — it is the reference slice.
- Is the proposed file/class/method naming consistent with the rest of the codebase (`<Name>RepositoryInterface` + `Eloquent<Name>Repository`, `<Action><Domain>Request`, `<Model>Resource`)?
- Are the right Laravel/PHP idioms being used (route-model binding, `Route::apiResource`/`apiSingleton`, Eloquent scopes and eager loading, policies for authorization, explicit type declarations)? For Flutter changes, idiomatic Dart widget structure in `platform/frontend/lib/`.

### 3. Risks & Edge Cases

- What could go wrong during implementation?
- Are there null states, error paths, loading states, or race conditions unaccounted for?
- Are there shared dependency or singleton concerns?
- Could this break existing functionality in other areas?
- Are there authorization/permission checks that need updating? Is every new route behind `auth:sanctum`, and is data scoped to the authenticated user (ownership checks, policies)?
- Does an API contract change (new/renamed fields, status codes, endpoints) affect the Flutter client in `platform/frontend/lib/`? If so, is the client change in the plan or explicitly out of scope?
- Soft-delete interactions: does the change respect `SoftDeletes` on `User` (token revocation, cascading, unique constraints on soft-deleted rows)?
- Are there performance implications (N+1 queries, large data sets, missing indexes)?

### 4. Assumptions

- What does the plan assume to be true? List them explicitly.
- Which assumptions are most likely to be wrong or worth verifying first?
- Are there implicit dependencies on external services, Composer/pub packages, or config (`config/auth.php`, `config/database.php`, `phpunit.xml`)? Confirm packages with `composer show`.

### 5. Scope

- Is the plan doing too much? Could it be split into safer, smaller steps?
- Is it doing too little — will the result be incomplete or require immediate follow-up?
- Are there related changes that should be bundled together to avoid a broken intermediate state?

## Output Format

**Verdict**: Ready to approve / Needs revision

**Critical issues** _(must resolve before implementing)_:
- Issue — evidence (`path/to/file.php:NN`)

**Suggestions** _(nice-to-have improvements)_:
- ...

**Looks solid**:
- ...

### After reporting (default mode — not dry-run):

Apply all critical issues and suggestions directly to the plan using Edit on the plan file. Amend the plan in place — add missing steps, fix incorrect file references, add edge case handling, strengthen test coverage, add unresolved items to Open questions, etc. If the plan exists only in the conversation (no file), output the full amended plan instead. Then summarize:

**Amendments applied**:
1. Section — what was changed and why
2. ...

If no critical issues were found and the verdict is "Ready to approve", say so and skip amendments unless a suggestion is trivially safe to add.

### After reporting (dry-run mode):

Do not modify the plan. End with the report above — the user decides next steps.
