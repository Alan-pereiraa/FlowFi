---
name: adapt-skills
description: Audit all skills against current project conventions, report issues, and fix them. Supports dry-run. Use after copying skills.
argument-hint: "[optional: 'dry-run' to report only without fixing]"
allowed-tools: Read Glob Grep Edit Write Bash(ls *)
---

# Adapt Skills

Audit every skill in `.claude/skills/` against the current project's conventions, report what's wrong, and fix each skill in place. Designed for when skills are copied from another project and need to conform to the new codebase.

## Arguments

$ARGUMENTS — Optional. Pass `dry-run` to only report issues without modifying any files. If empty, audit and fix all skills.

## Rules

- **Audit ALL skills** in `.claude/skills/` — do not skip any.
- **Fix in place.** Edit each SKILL.md directly. Do not create new files or delete existing ones.
- **Preserve skill intent.** Only change structure, formatting, frontmatter, and codebase-specific references. Do not change what the skill does.
- **`dry-run` mode**: If $ARGUMENTS contains `dry-run`, report all issues but do NOT edit any files.
- **Skip self.** Do not audit or modify `.claude/skills/adapt-skills/SKILL.md`.
- **Adapt `create-skill` templates.** If `create-skill` exists, also update its embedded templates (body structure, allowed-tools examples, convention references) to match the detected project conventions.

## Steps

### 1. Detect Project Conventions

Read the project to determine its stack and conventions:

- Check `Gemfile` or `package.json` for framework (Rails, Next.js, etc.)
- Check `config/routes.rb`, `app/javascript/controllers/`, `spec/` for patterns
- Check for `CLAUDE.md` or `AGENTS.md` at the project root
- Note: test framework (RSpec/Minitest/Jest), ORM (ActiveRecord/Prisma), CSS (Tailwind/custom), JS (Stimulus/React/Vue), language (Ruby/TypeScript/Python)

Build a **convention profile**:

```
Framework: Rails 8 / Next.js 16 / etc.
Language: Ruby / TypeScript / Python
Tests: RSpec + Fabrication / Jest / Minitest
CSS: Tailwind
JS: Stimulus / React
Auth: Devise / Clerk
Locale: pt-BR / en
```

### 2. Load All Skills

```bash
ls .claude/skills/
```

Read every `SKILL.md` file. For each skill, check:

**Frontmatter:**
- `name` matches directory name
- `description` is 110-170 chars, action + outcome format
- `argument-hint` present if skill takes arguments
- `allowed-tools` matches the skill's mode:
  - Read-only skills must NOT have Write/Edit
  - Write-capable skills must have Write and/or Edit
  - Bash patterns are specific (not blanket `Bash(*)`)
  - `AskUserQuestion` present if Rules/Steps reference it

**Structure:**
- Has `# Heading` as first content line
- Has `## Arguments` if skill takes input (references `$ARGUMENTS`)
- Has `## Rules` section with bold constraints
- Has `## Steps` section with numbered subsections
- Has summary/output section at the end

**Codebase alignment** (compare against the convention profile from Step 1):
- Test framework references match the profile (e.g., if project uses RSpec + Fabrication, skills should not reference Jest or Factory)
- JS framework references match the profile (e.g., if project uses Stimulus, skills should not reference React or `useEffect`)
- CSS references match the profile (e.g., if project uses Tailwind, skills should not reference styled-components)
- Auth library references match the profile (e.g., if project uses Devise, skills should not reference Clerk)
- Bash commands use project tools (e.g., if Ruby project, `bundle exec` not `npm run`; if Node project, `npx` not `bin/rails`)
- File paths match project structure (e.g., Rails: `app/controllers/`; Next.js: `src/app/`)

### 3. Report Issues

For each skill, produce a checklist:

```
## <skill-name>

- [x] name matches directory
- [x] description length OK (N chars)
- [ ] ISSUE: allowed-tools missing AskUserQuestion (Rules reference it)
- [ ] ISSUE: references React but project uses Stimulus
- [x] structure complete
```

### 4. Fix Issues (unless dry-run)

If not in `dry-run` mode, edit each SKILL.md to resolve all reported issues:

- Fix frontmatter fields (description length, missing allowed-tools, name mismatch)
- Replace framework-specific references with the correct ones from the convention profile
- Replace file path patterns with project-accurate paths
- Replace Bash commands with project-accurate commands
- Do NOT rewrite the entire file — make surgical edits only

### 5. Summary

**Skills audited**: `<N>`

**Issues found**: `<N>`

**Issues fixed**: `<N>` (or "0 — dry-run mode")

**Per-skill results**:

| Skill | Issues | Status |
|-------|--------|--------|
| `research` | 0 | OK |
| `commit` | 2 | Fixed |
| `design` | 1 | Fixed |

**Convention profile used**:
```
Framework: <detected>
Tests: <detected>
CSS: <detected>
JS: <detected>
```
