---
name: pipeline
description: Phase-aware orchestrator for feature work — grill → build → handoff → codex QA → ship. Detects current phase from git state. Use whenever starting a new feature or advancing one through QA/ship.
---

# Feature Pipeline

You orchestrate feature work end-to-end. There is ONE entry point and ONE command.
You detect current phase from git state and act accordingly. The user has signed
up for explicit checkpoints at key boundaries — never skip them.

## Detect current phase

1. Run `git rev-parse --is-inside-work-tree`. If not in a repo, abort with a
   clear error explaining the pipeline only works inside a git repo.
2. Get current branch: `git branch --show-current`.
3. If on `main` or `master`, this is **Phase 1** (new feature).
4. Otherwise, derive feature slug from branch name (strip `feat/` prefix) and
   inspect `docs/features/<slug>/`:
   - No `design.md`                                  → **Phase 1**
   - `design.md` only                                → **Phase 3** (build assumed done)
   - `design.md` + `handoff.md` + `qa.md`            → **Phase 6** (ship)
   - Anything else (e.g. handoff but no qa)          → ask user which phase to run

When state is ambiguous (multiple feature dirs, partial files, dirty working
tree at a phase boundary), STOP and ask. Do not guess destructively.

## Phase 1 — Scope

1. If user didn't pass a description with `/pipeline`, ask for:
   - a short feature slug in kebab-case
   - a one-line description
2. Create branch: `git checkout -b feat/<slug>` (only if currently on main/master;
   otherwise confirm the user wants to switch).
3. Invoke `/grill` with the description. Tell grill to write the brief to
   `docs/features/<slug>/design.md` (override its default path).
4. After grill returns and the file exists, commit:
   ```
   git add docs/features/<slug>/design.md
   git commit -m "scope(<slug>): design doc"
   ```
5. End Phase 1 with this exact handoff message to the user:
   > Design committed on `feat/<slug>`. Build the feature with normal Claude Code
   > workflow. When you're done coding and tests pass locally, run `/pipeline`
   > again to advance to QA.

Then stop. Do not start building.

## Phase 3 — Handoff + Codex QA

1. Verify the working tree is clean: `git status --porcelain`. If dirty, tell
   user to commit pending changes first and stop.
2. Derive slug from branch.
3. Write `docs/features/<slug>/handoff.md` using the **Handoff template** below.
   Fill the sections by reading `design.md` and running:
   - `git diff --stat $(git merge-base HEAD main)..HEAD`
   - `git diff $(git merge-base HEAD main)..HEAD` (skim for context)
4. Commit:
   ```
   git add docs/features/<slug>/handoff.md
   git commit -m "handoff(<slug>): pre-QA handoff"
   ```
5. Run codex QA via Bash (see **Codex QA invocation** below). Output goes to
   `docs/features/<slug>/qa.md`.
6. If codex command fails (not on PATH, auth error), STOP and tell the user
   exactly what failed plus install instructions. Do not silently substitute.
7. Commit:
   ```
   git add docs/features/<slug>/qa.md
   git commit -m "qa(<slug>): codex verdict"
   ```
8. Parse the verdict. Show the user:
   - The Blockers list
   - The Non-blocking issues list
   - The Verdict (SHIP / NO_SHIP)
   - Codex's reasoning
9. **PAUSE FOR HUMAN INPUT.** Ask: "Fix blockers (back to build) / ship anyway / stop?"
   Do not auto-fix. Do not auto-advance.

## Phase 6 — Ship

Invoke `/ship`. It runs the full pre-PR gate and opens the PR. Done.

## Handoff template

Write this exact structure to `handoff.md`, filling each section from the diff
and the design doc. Keep it tight — bullets over paragraphs.

```markdown
# Feature Handoff: <slug>

## Goal
<one sentence pulled from design.md>

## Files changed
<paste output of: git diff --stat $(git merge-base HEAD main)..HEAD>

## How to run
<exact commands to start the app and exercise the feature>

## Expected behavior
- <bullet>
- <bullet>

## Test plan
<what's covered by automated tests; what needs manual check>

## Known risks
<what could break; where to look first if something does>

## Open questions
<anything deferred or unresolved>
```

## Codex QA invocation

Default invocation (edit the `codex` line if your CLI uses different syntax):

```bash
codex exec "$(cat <<'EOF'
You are reviewing a feature implementation as a second-opinion QA reviewer.
Read these files from the current working directory:
- Design:  docs/features/<slug>/design.md
- Handoff: docs/features/<slug>/handoff.md

Also run `git diff $(git merge-base HEAD main)..HEAD` yourself and read it.

Check:
- Does the implementation match the design doc?
- Are tests meaningful (test behavior, not implementation details)?
- Any security or data-handling risks?
- Any regression risk in untouched code paths?
- Is the handoff honest — do claimed changes match the actual diff?
- For UI changes: would this render correctly? Flag suspect states or missing
  loading/error/empty branches.

Respond ONLY in this format. No preamble, no extra sections.

## Blockers
- (specific must-fix issues before ship; cite file:line where possible)

## Non-blocking issues
- (should-fix later; not ship-stoppers)

## Suggested tests
- (uncovered scenarios worth adding)

## Verdict
SHIP | NO_SHIP

## Reasoning
(2-3 sentences justifying the verdict)
EOF
)" > docs/features/<slug>/qa.md
```

If `codex` is not on PATH, abort Phase 3 with this message:
> Codex CLI not found. Install with `npm i -g @openai/codex` (verify current
> install method) and ensure you're authenticated, then re-run `/pipeline`.

## Hard rules

- **Never skip the Phase 3 triage checkpoint.** The user explicitly opted in.
- **Never auto-fix codex blockers.** Always pause and let the user decide.
- **Commit between every phase.** Each phase boundary is a clean rollback point.
- **If anything is ambiguous, stop and ask.** Multiple feature dirs, unexpected
  files, dirty tree, codex error — all stop the pipeline cleanly.
- **Don't try to script the build phase.** It happens between calls to
  `/pipeline`, with the user driving normally.
- **Don't invent codex command flags.** If the default doesn't work, tell the
  user and let them fix the skill file.
