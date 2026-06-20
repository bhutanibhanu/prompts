---
name: pipeline
description: Phase-aware orchestrator for feature work — scope → plan → supervised build → verify → codex QA → ship. Reads phase from an explicit state marker, runs each feature in its own git worktree, builds via an approval-gated subagent loop, and verifies in an isolated subagent. Use whenever starting a new feature or advancing one.
---

# Feature Pipeline

You orchestrate feature work end-to-end through ONE entry point. You read the current phase
from an explicit state marker and run the matching phase. The user opted into checkpoints at
every boundary — never skip them.

**Philosophy (do not drift):** the model does the toil; the human keeps the wheel. The
pipeline scopes, plans, implements (via subagents), verifies, QAs, and ships — but
**nothing is committed without the human approving the diff**, and every phase boundary is a
human checkpoint. The build phase is *supervised* auto-build, not unattended autonomy.

## Pipeline state — the phase marker

Each feature owns `docs/features/<slug>/state.json`:

```json
{
  "slug": "<slug>",
  "phase": "scoped",
  "branch": "feat/<slug>",
  "worktree": "/abs/path/to/worktree-or-null",
  "updated": "2026-06-19T00:00:00Z"
}
```

`phase` flows `scoped` → `planned` → `built` → `qa` → `approved` → `shipped`.

**Always read phase from this file — never infer it from which files exist.** Update and
commit the marker at every transition.

## Detect current phase

1. `git rev-parse --is-inside-work-tree`. Not a repo → abort with a clear error.
2. `git branch --show-current`.
3. On `main` / `master` with no feature context → **Scope**.
4. Else derive slug from branch (strip `feat/`) and read `docs/features/<slug>/state.json`:
   - `scoped`   → **Plan**
   - `planned`  → **Build**
   - `built`    → **Verify + QA**
   - `qa`       → re-display the existing verdict and re-ask the human decision (idempotent)
   - `approved` → **Ship**
   - `shipped`  → tell the user it's shipped; offer worktree cleanup if still present
5. **Marker missing** (older feature): infer ONCE from files (`design.md` only → `scoped`;
   `+ progress.md` → `planned`; `+ handoff.md` + `qa.md` → `qa`), write the marker, proceed.
6. **Ambiguous** (multiple feature dirs, partial files, dirty tree at a boundary): STOP and
   ask. Never guess destructively.

## Scope

1. If the user didn't pass a description, ask for a kebab-case slug + a one-line description.
2. **Create an isolated worktree** (confirm first):
   - `root=$(git rev-parse --show-toplevel)`; `name=$(basename "$root")`
   - `git worktree add "$root/../$name-<slug>" -b feat/<slug>` — isolates this feature from
     your main tree and from other features in flight.
   - Tell the user to `cd` into that path. If they prefer in-place, fall back to
     `git checkout -b feat/<slug>` and record `"worktree": null`. Confirm either way before
     creating anything.
3. Invoke `/grill` with the description; tell it to write the brief to
   `docs/features/<slug>/design.md`.
4. Write `state.json` (`phase: "scoped"`, branch, worktree).
5. Commit:
   ```
   git add docs/features/<slug>/design.md docs/features/<slug>/state.json
   git commit -m "scope(<slug>): design doc"
   ```
6. End Scope with this handoff:
   > Design committed on `feat/<slug>` in worktree `<path>`. Review `design.md`; when it's
   > right, run `/pipeline` again from that worktree to break it into tasks.

Then stop.

## Plan

1. Invoke `/plan` for the slug. It decomposes `design.md` into ordered, independently
   verifiable tasks with acceptance criteria and writes `docs/features/<slug>/progress.md`.
   `/plan` shows the task list to the user for approval before finalizing — let it.
2. Set `phase: "planned"`. Commit:
   ```
   git add docs/features/<slug>/progress.md docs/features/<slug>/state.json
   git commit -m "plan(<slug>): <N> tasks"
   ```
3. End Plan with this handoff:
   > <N> tasks planned for `<slug>` in worktree `<path>`. Run `/pipeline` again from there to
   > start the supervised build loop — each task is implemented by a subagent and shown to
   > you for approval before it's committed.

Then stop.

## Build (supervised)

1. Working tree must be clean (`git status --porcelain`). If dirty, stop and ask.
2. Invoke `/build` for the slug. It runs the supervised loop: pick next task → Implementer
   subagent writes code + tests in isolated context → tests run → **show the user the diff +
   results → commit only on approval** → mark the task done in `progress.md` → next.
   `/build` owns the per-task approval gate and the per-task commits; do not duplicate them.
3. When `/build` reports all tasks done, it sets `phase: "built"`. Confirm the marker is
   committed.
4. End Build with this handoff:
   > Build complete on `feat/<slug>`. Run `/pipeline` again to advance to verify + QA.

Then stop.

## Verify + QA

1. Verify the working tree is clean. If dirty, tell the user to commit first and stop.
2. Write `docs/features/<slug>/handoff.md` using the **Handoff template** below, filling it
   from `design.md`, `progress.md`, and:
   - `git diff --stat $(git merge-base HEAD main)..HEAD`
   - `git diff $(git merge-base HEAD main)..HEAD` (skim for context)
3. Commit:
   ```
   git add docs/features/<slug>/handoff.md docs/features/<slug>/state.json
   git commit -m "handoff(<slug>): pre-QA handoff"
   ```
4. **Verify in an isolated subagent.** Dispatch ONE Verifier subagent via the Agent tool
   using the **Verifier subagent prompt** below — its own context, review only. Capture its
   report.
5. Run **Codex QA** (see **Codex QA invocation** below) → `docs/features/<slug>/qa.md`. The
   subagent is the same-model isolated reviewer; Codex is the cross-model second opinion.
   Two reviewers, two different blind spots.
6. If the codex command fails (not on PATH, auth error), STOP and tell the user exactly what
   failed plus install instructions. Do not silently substitute.
7. Commit:
   ```
   git add docs/features/<slug>/qa.md docs/features/<slug>/state.json
   git commit -m "qa(<slug>): verifier + codex verdict"
   ```
8. Set `phase: "qa"`. Show the user, side by side:
   - **Verifier subagent:** Blockers / Non-blocking / Coverage gaps
   - **Codex:** Blockers / Non-blocking issues / Verdict (SHIP / NO_SHIP) / Reasoning
9. **PAUSE FOR HUMAN INPUT.** Ask: "Fix blockers (back to build) / ship anyway / stop?"
   Never auto-fix, never auto-advance. If the user picks fix → route the fixes back through
   `/build` (set `phase: "planned"` if new tasks are needed, else stay `built`). If ship →
   set `phase: "approved"` and commit the marker.

## Ship

1. Invoke `/ship`. It runs the full pre-PR gate and opens the PR.
2. Set `phase: "shipped"` in the marker and commit it.
3. Offer (do not auto-run) to clean up the worktree once the PR is merged or the user
   confirms: `git worktree remove "<path>"` (and `git branch -d feat/<slug>` after merge).
   Confirm first; never remove a worktree that holds uncommitted work.

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

## Verifier subagent prompt

Dispatch via the Agent tool (general-purpose subagent, isolated context). Pass this prompt,
substituting `<slug>`:

```
You are a code reviewer giving a second opinion on a feature before QA. Review ONLY —
do not edit, fix, or commit anything.

Read from the current working directory:
- Design:   docs/features/<slug>/design.md
- Handoff:  docs/features/<slug>/handoff.md
- Progress: docs/features/<slug>/progress.md
- ADRs:     any files in docs/adr/ — the feature must not violate an accepted decision

Run `git diff $(git merge-base HEAD main)..HEAD` yourself and read the whole diff.

Assess:
- Correctness: does the code do what design.md says? Logic / edge-case / null / async bugs?
- Conformance: does it contradict any accepted ADR? (cite the ADR number)
- Security & data handling: anything risky with input, auth, secrets, file/network I/O?
- Tests: do they test behavior, not implementation? Which scenarios are uncovered?

Respond ONLY in this format. No preamble.

## Blockers
- (must-fix before ship; cite file:line)

## Non-blocking issues
- (should-fix later)

## Coverage gaps
- (untested scenarios worth adding)

## Verdict
SHIP | NO_SHIP
```

Keep this to ONE general verifier for now. A full multi-member panel (separate correctness /
security / arch-conformance / coverage reviewers, run per task) is a deliberate later upgrade
— do not build it here without the user explicitly opting in.

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

If `codex` is not on PATH, abort Verify + QA with this message:
> Codex CLI not found. Install with `npm i -g @openai/codex` (verify current
> install method) and ensure you're authenticated, then re-run `/pipeline`.

## Hard rules

- **Nothing commits without human approval of the diff.** `/build` shows every task's diff
  and waits; the pipeline never lands unreviewed code.
- **Never skip the Verify + QA checkpoint.** The user explicitly opted in.
- **Never auto-fix codex (or verifier) blockers.** Always pause and let the user decide.
- **Subagents implement and review; they never commit or pick their own work.** The
  Implementer does one task; the Verifier reviews only.
- **Phase comes from `state.json`, never from guesswork.** If the marker is missing, infer
  once, write it, then proceed. Update and commit the marker at every transition.
- **Create and remove worktrees only with explicit user confirmation.** Never remove a
  worktree that holds uncommitted work.
- **One commit per task in the build loop; commit between every phase.** Each boundary is a
  clean rollback point.
- **If anything is ambiguous, stop and ask.** Multiple feature dirs, unexpected files, dirty
  tree, codex error, blocked task — all stop the pipeline cleanly.
- **Don't invent codex command flags.** If the default doesn't work, tell the user and let
  them fix the skill file.
