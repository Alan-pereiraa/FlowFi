---
name: skill-critique
description: Structured devil's advocate review of a Claude Code skill (SKILL.md). Surfaces gaps, ambiguities, and improvements to make the skill more effective.
argument-hint: "[skill name to critique]"
allowed-tools: Read Glob Grep Edit Write Bash(ls *) Bash(cat *) Bash(git log *) Bash(git diff *) Bash(git show *) WebFetch WebSearch AskUserQuestion
---

# Skill Critique

Review a Claude Code skill (SKILL.md) as a structured devil's advocate. Surface gaps, ambiguities, and improvements — then apply fixes directly.

## Arguments

$ARGUMENTS — The skill name to critique (e.g., "research", "polish", "design"). Append `dry-run` to only report without editing (e.g., "research dry-run"). If empty, list all available skills and use AskUserQuestion to ask which one to review.

## Rules

- **Default mode: critique and fix.** After reporting issues, apply all suggested improvements directly to the SKILL.md file.
- **`dry-run` mode**: If $ARGUMENTS contains `dry-run`, report all issues but do NOT edit any files.
- **Preserve skill intent.** Fix structure, frontmatter, and references — do not change what the skill does.
- **Surgical edits only.** Do not rewrite the entire file. Edit specific sections that have issues.

## Steps

### 1. Load the Skill

- Read `.claude/skills/$ARGUMENTS/SKILL.md`
- If not found, list all skills in `.claude/skills/` and ask which one to review
- Read any related skills to understand the overall skill ecosystem and avoid overlap

### 2. Frontmatter Review

Check the YAML frontmatter for:

- **name**: Does it match the directory name? Is it short, lowercase, hyphenated?
- **description**: Is it specific enough for Claude to decide when to auto-trigger? Max 250 chars. Does it clearly state *what* the skill does and *when* to use it?
- **argument-hint**: Is it present? Does it give a useful autocomplete hint?
- **allowed-tools**: Are the right tools listed? Too broad (security risk)? Too narrow (skill will fail mid-execution)?
  - Are MCP tools included if the skill references them in the body?
  - Are destructive tools (Write, Edit, Bash write commands) excluded if the skill is read-only?
  - Are read-only tools missing that the steps require?
- **Optional fields**: Would `disable-model-invocation`, `context: fork`, `agent`, or `model` improve the skill?

### 3. Clarity & Precision

- **Goal statement**: Can someone understand what this skill does in the first 2 sentences?
- **Arguments section**: Is `$ARGUMENTS` clearly explained with examples? Does it handle the empty case?
- **Rules section**: Are rules specific and enforceable? Or vague enough to be ignored?
  - Are there contradictions between rules and steps?
  - Are there implicit rules that should be explicit?
- **Steps**: Is each step actionable? Could Claude follow them without guessing?
  - Are steps ordered correctly (gather context before acting)?
  - Are there missing steps? (e.g., validation, error handling, edge cases)
  - Are any steps redundant or could be merged?
- **Output format**: Is the expected output structure defined? Will the user get consistent results across runs?

### 4. Effectiveness

Test the skill mentally against realistic scenarios:

- **Happy path**: If the user provides a clear, well-scoped argument, will the skill produce the right result?
- **Ambiguous input**: If the argument is vague ("fix the thing"), does the skill handle it?
- **Empty input**: Does the skill ask for clarification or fail silently?
- **Large scope**: If the argument implies touching 20+ files, does the skill timebox or scope-limit?
- **Edge cases**: What happens if the referenced code doesn't exist? If the project has no tests? If the skill is run on a clean repo?

### 5. Codebase Alignment

- Does the skill reference this project's actual conventions? (Laravel monorepo under `packages/backend/`, Eloquent, PHPUnit, factories, Sanctum, Blade, Vite, Tailwind, Pint; Flutter app under `platform/frontend/`)
- Does it reference tools/patterns that don't exist in this project? (e.g., Rails, RSpec, React, TypeScript, Django)
- Are file paths, commands, and examples realistic for this codebase?
- Does it overlap with or contradict other skills?

### 6. Comparison with Best Practices

- Compare against the other skills in `.claude/skills/` — is the format consistent?
- Are there patterns from the best skills that this one should adopt?
- Is the skill too long (loses focus) or too short (insufficient guidance)?

## Output Format

**Verdict**: Ready to use / Needs revision

**Critical issues** _(skill will produce wrong or confusing results)_:
- ...

**Suggestions** _(would make the skill noticeably better)_:
- ...

**Looks solid**:
- ...

### After reporting (default mode — not dry-run):

Apply all critical issues and suggestions directly to the SKILL.md file using Edit. Then summarize:

**Changes applied**:
1. `file:line` — what was changed
2. ...

### After reporting (dry-run mode):

Do not modify any files. End with the report above — the user decides next steps.
