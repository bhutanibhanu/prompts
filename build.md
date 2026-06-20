---
name: build
description: Supervised per-task build loop. For each unfinished task in progress.md, an Implementer subagent writes the code and tests in isolated context, tests run, you see the diff and results, and it commits ONLY after you approve. Use to execute a plan from /plan. Nothing lands without a human OK.
argument-hint: "[optional: task id to start from, e.g. T3]"
---

# Build — supervised auto-build loop

You execute the task graph in `progress.md` one task at a time. For each task: an
Implementer subagent writes the code in isolated context, tests run, you show the user the
diff + results, and you commit ONLY after the user approves. Nothing is committed without a
human OK. **You are the coordinator, not the implementer** — you dispatch, verify, gate,
and commit; the subagent writes the code.

## Preconditions
- Working tree clean (`git status --porcelain` empty). If dirty, stop and ask the user to
  commit or stash first.
- `docs/features/<slug>/progress.md` exists with at least one `[ ]` task. If not, tell the
  user to run `/plan` first, and stop.
- You're on `feat/<slug>` (ideally in its worktree).

## The loop

Repeat until no `[ ]` / `[>]` tasks remain, or the user stops:

**1. Pick the next task.** The first `[ ]` task whose `Depends on` tasks are all `[x]` (or
the task id passed as an argument). Mark it `[>]` in `progress.md`.

**2. Dispatch an Implementer subagent** (Agent tool, isolated context — its own worktree if
supported). Give it ONLY this task:

```
Implement exactly ONE task. Do NOT commit. Do NOT touch other tasks.

Read for context:
- Design:   docs/features/<slug>/design.md
- Progress: docs/features/<slug>/progress.md  (read your task <Tn> in full)
- ADRs:     docs/adr/  (do not violate an accepted decision)

Task <Tn>: <title>
Goal: <goal>
Acceptance criteria:
<criteria>
Expected files: <files>

Do:
- Implement the smallest change that satisfies every acceptance criterion.
- Write/adjust tests that assert the behavior in the criteria (not implementation detail).
- Run the affected tests and report the exact command + result.
- Match the surrounding code's style and conventions.

Report: files changed (and why), test command + result, which acceptance criteria are now
met. If a criterion is unclear or you're blocked, STOP and report the blocker — do not
guess scope.
```

**3. Verify locally.** When the subagent returns, run the task's tests yourself — don't
trust the report blindly. If red, send the failure back to a subagent to fix (or fix
directly), then re-verify. Never proceed on red.

**4. Show the user and PAUSE.** Present:
- `git diff` (plus `git status` for new files)
- Which acceptance criteria are met
- The test command + result

Ask: **"Approve & commit / request changes / skip this task / stop?"**

**5. Act on the decision.**
- **Approve & commit:** `git add -A && git commit -m "feat(<slug>): <Tn> <title>"`. Mark the
  task `[x]` with the short sha in `progress.md`; commit that marker update too. Go to 1.
- **Request changes:** capture the feedback, dispatch a subagent (or fix directly) with it,
  re-verify, re-show. Do not commit until approved.
- **Skip:** leave the task `[ ]` with a note `(skipped <date>)`; move on. Don't mark done.
- **Stop:** leave the current task `[>]`, summarize remaining tasks, exit cleanly so
  `/build` (or `/pipeline`) can resume later.

**6. When all tasks are `[x]`:** set `docs/features/<slug>/state.json` `phase` to `built`,
commit the marker, and report: "Build complete — <N> tasks on `feat/<slug>`. Next:
`/pipeline` advances to verify + QA." Stop.

## Hard rules
- **Never commit without explicit user approval of the diff.** That's the entire point of
  supervised mode — no unreviewed code lands, ever.
- **One task per commit.** Keeps history bisectable and reviews small.
- **The subagent implements; you coordinate and verify.** Don't let it commit, pick its own
  tasks, or wander outside its task.
- **Never proceed on red tests.** Fix or surface — don't bury a failure.
- **Always resumable.** State lives in `progress.md` + `state.json`, never only in your
  head; a fresh session can pick up mid-loop.
- **If a task is ambiguous or blocked, stop and ask.** Mark it `[!]` with the open question.
  Don't guess scope to keep the loop moving.
