---
name: research
description: Investigate how something works in the codebase and produce a clear written explanation. Read-only — no files are created, edited, or deleted.
argument-hint: "[what to investigate]"
allowed-tools: Read Glob Grep Bash(ls *) Bash(cat *) Bash(git log *) Bash(git diff *) Bash(git show *) Bash(git blame *) Bash(php artisan route:list *) Bash(composer show *) WebFetch WebSearch AskUserQuestion
---

# Research

Investigate how something works in the codebase and produce a clear written explanation. No files are created, edited, or deleted — ever.

## Arguments

$ARGUMENTS — What to investigate (e.g., "how does the transaction flow work", "how are API routes protected", "how does Sanctum auth integrate with the app")

## Rules

**NEVER** use Write, Edit, MultiEdit, or NotebookEdit. No Bash command that writes to, moves, copies, or deletes files.

Read-only tools only: Read, Glob, Grep, Bash (read-only commands like `ls`, `cat`, `git log`, `git diff`, `git show`, `git blame`, `php artisan route:list`), WebFetch, WebSearch.

If you find something worth fixing while researching, **note it in the output** under "Incidental findings" — do not fix it.

**MODE: READ-ONLY INVESTIGATION.** If you notice code that could be improved, do not improve it. If you find a bug, do not fix it. Surface everything as findings only.

## Steps

### 1. Understand the Question

If $ARGUMENTS is empty, use AskUserQuestion to ask what to investigate before proceeding.

Restate what is being investigated in 1-2 sentences. If the scope is ambiguous, use AskUserQuestion to clarify before exploring.

### 2. Explore

Start from the entry point named in $ARGUMENTS, then follow imports and call chains inward:

- Use Glob and Grep to locate relevant files
- Read entry points, then follow the call chain inward (routes → controllers → models → views/resources)
- Check `packages/backend/routes/` (`api.php`, `web.php`) to understand routing for the area being investigated
- Check for related tests in `packages/backend/tests/Feature/` and `tests/Unit/`
- Read any `CLAUDE.md` or `AGENTS.md` in the relevant directory before starting
- Cross-reference config files (`composer.json`, `vite.config.js`, `config/database.php`, `config/auth.php`) when architecture is involved
- Check frontend assets in `packages/backend/resources/js/` and `resources/css/` when investigating frontend behavior
- Check Blade views and layouts in `packages/backend/resources/views/` for rendering chains
- Look at models in `app/Models/`, controllers in `app/Http/Controllers/`, and middleware in `app/Http/Middleware/`
- **Timebox**: if you've read 10+ files without a clear model forming, surface what you've found so far and ask a clarifying question rather than continuing to dig

### 3. Synthesise

Produce a structured explanation covering:

**How it works**: A plain-language description of the mechanism, flow, or architecture. Use concrete file references (`path/to/File.php:42`) so the reader can navigate directly to the relevant code.

**Data / control flow**: A step-by-step trace from entry point to outcome (e.g., request → route → middleware → controller action → Eloquent query → JSON response / Blade render). Omit only if the question is purely about static structure (e.g., config values).

**Key files**:

| File | Role |
|------|------|
| `path/to/File.php` | What this file does in the context of the question |

**Boundaries and ownership**: What is this system responsible for, and what does it hand off to something else? (e.g., "The `TransactionController` handles CRUD and delegates validation to a Form Request — it does not manage authentication, which is handled by Sanctum middleware")

**Incidental findings** (only if any): Issues, dead code, potential bugs, or improvements spotted during research. Do not fix — just list them with file references.
