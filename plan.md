---
name: plan
description: Decompose a feature's design.md into an ordered list of small, independently-verifiable build tasks with explicit acceptance criteria, and write a durable progress.md tracker. Use after /grill (or pipeline's Scope phase) and before building. The task graph is the deliverable — no code.
argument-hint: "[optional: feature slug]"
---

# Plan — turn a design into a tracked task graph

You convert a feature's `design.md` into an ordered list of small, independently
verifiable tasks, each with checkable acceptance criteria, and write them to a durable
`progress.md`. This is the missing link between the spec and the build loop. You do NOT
write code here — the task graph is the deliverable.

## How to operate

**1. Locate the design.**
- Derive the slug from the branch (strip `feat/`) or the argument, then read
  `docs/features/<slug>/design.md`. If it's missing, tell the user to run `/grill` (or
  pipeline's Scope phase) first, and stop.
- Skim `docs/adr/` — tasks must not contradict an accepted decision.

**2. Decompose into tasks.** What makes a task good:
- **Small** — ideally one focused commit. If it needs more than ~3 files or covers two
  distinct concerns, split it.
- **Ordered by dependency** — foundational/plumbing tasks first; nothing depends on a
  later task. Record each task's `Depends on`.
- **Independently verifiable** — its acceptance criteria can be checked without doing the
  next task.
- **Checkable acceptance criteria**, EARS-style where it fits: "WHEN <trigger>, the system
  SHALL <observable behavior>." Ban vague criteria ("works correctly", "handles errors") —
  say *which* errors and *what* the system does.
- **Names the files/areas** it's expected to touch (best guess; anchors scope).
- **States its tests** — what behavior to assert (not implementation detail), or "none —
  <why>".

**3. Show the plan to the user before writing.** Present the task list (titles + one-line
goals + order) and ask: "Right tasks, right order? Anything to split, merge, drop, or
reorder?" Adjust until they're satisfied. This is a human gate — the plan must reflect what
the *user* thinks the work is, not just what you inferred.

**4. Write `docs/features/<slug>/progress.md`** using the template below.

**5. Update state.** Set `docs/features/<slug>/state.json` `phase` to `planned`. Under
`/pipeline`, the pipeline commits. Standalone, offer to commit:
`git add docs/features/<slug>/progress.md docs/features/<slug>/state.json && git commit -m "plan(<slug>): <N> tasks"`.

**6. Report.** "<N> tasks planned for <slug>. Next: `/build` (or `/pipeline`) starts the
supervised build loop." Stop. Do not start building.

## progress.md template

```markdown
# Progress: <slug>

_Plan generated <YYYY-MM-DD> from design.md · <N> tasks · supervised build_

## Task list
- [ ] T1 — <title>
- [ ] T2 — <title>
- [ ] T3 — <title>

Legend: `[ ]` todo · `[>]` in progress · `[x]` done (short sha) · `[!]` blocked

## Tasks

### T1 — <title>
- **Goal:** <one sentence>
- **Depends on:** none
- **Files (expected):** <paths / areas>
- **Acceptance:**
  - WHEN <trigger>, the system SHALL <observable behavior>.
  - <criterion 2>
- **Tests:** <what to assert, or "none — why">
- **Status:** todo

### T2 — <title>
- **Goal:** ...
- **Depends on:** T1
- **Files (expected):** ...
- **Acceptance:** ...
- **Tests:** ...
- **Status:** todo
```

## Rules
- **No code.** The task graph is the deliverable; `/build` executes it.
- **One commit per task is the target.** If you can't state a task's acceptance in one or
  two checkable lines, it's too big — split it.
- **Don't invent scope.** Tasks come from `design.md`. If the design is silent on something
  a task needs, add it as a `[!]` blocked task with an open question rather than guessing.
- **`progress.md` is the single source of task truth.** `state.json` tracks the *phase*;
  `progress.md` tracks *tasks within the build phase*. Keep them consistent.
