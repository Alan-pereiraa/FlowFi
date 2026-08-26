---
name: create-skill
description: Scaffold a new Claude Code skill following this project's conventions. Produces a complete SKILL.md ready to use.
argument-hint: "[skill name and purpose]"
allowed-tools: Read Glob Grep Write Bash(ls *) Bash(mkdir *) AskUserQuestion
---

# Create Skill

Scaffold a new Claude Code skill (SKILL.md) that matches this project's conventions. Reads existing skills to stay consistent, then writes a complete, ready-to-use skill file.

## Arguments

$ARGUMENTS — The skill name and a brief description of what it should do (e.g., "migrate - run and verify Laravel migrations", "audit-deps - check for outdated or vulnerable composer packages").

## Rules

- If $ARGUMENTS is empty, use AskUserQuestion to ask what skill to create.
- **Follow project conventions exactly** — read at least 2 existing skills before writing anything.
- **One skill per invocation.** If the user asks for multiple skills, create the first and suggest the rest.
- **Do not create skills that duplicate existing ones.** Check `.claude/skills/` first.
- The skill file MUST be immediately usable after creation — no placeholders, no TODOs.

## Steps

### 1. Parse the Request

Extract from $ARGUMENTS:

- **Skill name**: lowercase, hyphenated (e.g., `audit-deps`, `db-seed`, `migrate`)
- **Purpose**: what the skill does in one sentence
- **Mode**: is it read-only (research, critique) or write-capable (fix, create, refactor)?

If any of these are unclear, use AskUserQuestion to clarify.

### 2. Check for Duplicates

```bash
ls .claude/skills/
```

Read the description of any skill that might overlap. If a duplicate exists, tell the user and suggest extending the existing skill instead.

### 3. Study Existing Patterns

Read 2-3 existing SKILL.md files to calibrate tone, structure, and depth. Choose skills with a similar mode:

- **Read-only skill?** → Read `research` and `build-plan`
- **Write-capable skill?** → Read `polish` and `skill-critique`
- **Tooling/workflow skill?** → Read `build-plan` and `adapt-skills`

Note the patterns:

- Frontmatter fields: `name`, `description`, `argument-hint`, `allowed-tools`
- Section order: `# Heading` → `## Arguments` → `## Rules` → `## Steps` → `## Summary/Output`
- Description format: action + outcome (1st sentence), scope/constraint (2nd sentence), 110-170 chars total
- Argument-hint format: `[placeholder in square brackets]`
- Rules: imperative, bold emphasis on constraints, explicit about what NOT to do
- Steps: numbered subsections, ordered understand → explore → act → verify → summarize
- Allowed-tools: explicit Bash patterns for read-only skills (`Bash(git log *)`, `Bash(ls *)`), broader for write skills

### 4. Draft the Frontmatter

```yaml
---
name: <skill-name>
description: <110-170 chars, action + outcome, then scope/constraint>
argument-hint: "<[placeholder with examples or alternatives]>"
allowed-tools: <tool list matching the skill's mode>
---
```

**Allowed-tools guidelines:** Check the existing skills with the same mode (from Step 3) and mirror their `allowed-tools` list. Common additions by need:

- **Needs user input** → Add `AskUserQuestion`
- **Planning workflow** → Add `EnterPlanMode ExitPlanMode`
- **Needs web access** → Add `WebFetch WebSearch`

### 5. Draft the Body

Follow this structure:

```markdown
# <Skill Title>

<One-paragraph intro: what the skill does, when to use it, what it produces.>

## Arguments

$ARGUMENTS — <Description of expected input. List formats accepted (description, file:line, URL, etc.).>

## Rules

- <3-8 rules, bold key constraints, explicit about NEVER/ALWAYS behaviors>
- <Reference this project's conventions: Laravel in `packages/backend/`, Model::factory(), PHPUnit, Sanctum, Blade, Tailwind, Pint; Flutter app in `platform/frontend/` — where relevant>
- <Handle empty $ARGUMENTS: use AskUserQuestion>

## Steps

### 1. <Understand/Gather Context>
<What to read, check, or ask before acting>

### 2. <Core Action>
<The main thing the skill does>

### 3. <Verify/Validate>
<How to confirm the result is correct>

### N. Summary
<Structured output format: Bug/Fix/Spec, Changes made, Flagged items, etc.>
```

**Calibration checks before writing:**

- Every step must be actionable — no vague instructions
- Rules must be enforceable — no "try to" or "consider"
- Include codebase-specific references where relevant (Laravel, Eloquent, PHPUnit, factories, Sanctum, Blade, Vite, Tailwind, Pint; Flutter/Dart in `platform/frontend/`)
- The Summary/Output section must define a consistent format so results are predictable across runs

### 6. Write the Skill

```bash
mkdir -p .claude/skills/<skill-name>
```

Write the SKILL.md file to `.claude/skills/<skill-name>/SKILL.md`.

### 7. Verify

- Read the written file back to confirm no formatting issues
- Verify the `name` matches the directory name
- Verify `allowed-tools` matches the skill's mode (no Write/Edit in read-only skills, no missing tools for write skills)
- Verify the description is under 170 characters

### 8. Summary

**Skill created**: `.claude/skills/<name>/SKILL.md`

**Name**: `<name>`

**Type**: read-only / write-capable / planning

**Usage**: `/<name> <example argument>`

**Next step**: Run `/skill-critique <name>` to review before committing.
