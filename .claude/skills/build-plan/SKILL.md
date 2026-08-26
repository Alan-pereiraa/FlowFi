---
name: build-plan
description: Explore the codebase and produce a structured implementation plan. No code written until you explicitly approve.
argument-hint: "[task to plan] (e.g., 'add expense categories to the API')"
allowed-tools: Read Glob Grep Bash(ls *) Bash(cat *) Bash(git log *) Bash(git diff *) Bash(git show *) Bash(git blame *) Bash(php artisan route:list *) Bash(composer show *) WebFetch WebSearch AskUserQuestion ExitPlanMode EnterPlanMode
---

# Plan

Explore the codebase and produce a structured implementation plan. No code written until you explicitly approve.

## Arguments

$ARGUMENTS — The task to plan (e.g., "add expense categories to the API", "implement PDF export for financial reports", "add Sanctum token abilities to transaction endpoints")

## Rules

**NEVER** use Write, Edit, MultiEdit, or NotebookEdit. No Bash command that writes to, moves, copies, or deletes files.

Read-only tools only: Read, Glob, Grep, Bash (read-only commands like `ls`, `cat`, `git log`, `git diff`, `git show`, `git blame`, `php artisan route:list`, `composer show`), WebFetch, WebSearch.

**MODE: READ-ONLY PLANNING.** If you notice code that could be improved, do not improve it. If you find a bug, do not fix it. Surface everything as findings or plan items only.

## Steps

### 1. Understand

Restate the goal in 1-2 sentences. If anything is ambiguous, use AskUserQuestion to resolve critical unknowns **before** exploring or drafting — do not make assumptions or defer them to "open questions."

### 2. Explore

Before drafting anything, read the relevant code:

- Use Glob and Grep to locate affected files
- Read existing patterns, conventions, and types in those areas
- Read any `CLAUDE.md` or `AGENTS.md` in the relevant directory before starting
- Check `packages/backend/routes/` (`api.php`, `web.php`) to understand routing for the area being investigated
- Check for related tests in `packages/backend/tests/Feature/` and `tests/Unit/`
- Cross-reference config files (`composer.json`, `vite.config.js`, `config/database.php`, `config/auth.php`) when architecture is involved
- Check frontend assets in `packages/backend/resources/js/` and `resources/css/` when investigating frontend behavior
- Check Blade views and layouts in `packages/backend/resources/views/` for rendering chains
- Look at models in `app/Models/`, controllers in `app/Http/Controllers/`, and middleware in `app/Http/Middleware/`
- Check the Flutter app in `platform/frontend/lib/` (and `pubspec.yaml`, `platform/frontend/test/`) when the task touches the mobile client

**Timebox exploration**: if you've read 10+ files without a clear picture, stop and surface open questions rather than keep digging.

### 3. Draft the Plan

Before writing anything, apply these rules:

- **ALWAYS model existing patterns** — find a real example in the codebase before proposing any new file structure, component shape, or API design
- **NEVER introduce a new pattern when an existing one covers the need** — if a pattern already exists, use it; explicitly justify any deviation
- **Cite the pattern** — for each proposed approach, name a specific file that demonstrates it (e.g., "following the pattern in `packages/backend/app/Http/Controllers/TransactionController.php`")
- **ALWAYS follow framework and language best practices** — apply idiomatic conventions for the relevant stack (e.g., Laravel: prefer Form Requests for validation, resource controllers with RESTful actions, Eloquent scopes and eager loading, policies for authorization; PHP: explicit type declarations, guard clauses, follow existing naming conventions; frontend: follow the existing Blade + Vite + Tailwind patterns in `packages/backend/resources/` and idiomatic Flutter/Dart widget structure in `platform/frontend/lib/`)

Structure the plan as:

**Goal**: One sentence.

**Approach**: Why this approach, and what alternatives were considered (2-4 sentences).

**Files to change**:

| # | File | Change | Reason |
|---|------|--------|--------|
| 1 | `path/to/File.php` | Description of what changes | Reason this file is affected |

**Files to create**:

| # | File | Purpose |
|---|------|---------|
| 1 | `path/to/NewFile.php` | What this file will do |

**Tests**:

| # | File | What to test |
|---|------|-------------|
| 1 | `tests/Feature/Path/FileTest.php` | Description of test coverage |

**Out of scope**: At least 2 things this plan explicitly does not cover.

**Rollback / cleanup**: How to undo this change if something goes wrong (especially relevant for schema changes, feature flags, shared dependencies, or data migrations).

**Open questions**: Anything uncertain that couldn't be resolved before planning and must be answered during implementation.

### 4. Enter Plan Mode

Call EnterPlanMode. End with: _"Let me know if you'd like to adjust anything — or run `/polish` for a structured review before approving."_

Do NOT write, edit, or create any files until the plan is approved.
