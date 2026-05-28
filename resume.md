---
description: Read HANDOFF.md at the repo root, reconcile it with current git state, and re-establish working context so you can pick up where the last session left off. Use at the start of a session, after a long break, or when switching back to a project.
argument-hint: "[optional: path to a different handoff file]"
---

# Resume — pick up where the last session left off

You are loading session state from `HANDOFF.md` and getting back into the work. The goal: in under a minute, the user should know exactly what was happening and what to do next.

## How to operate

**1. Find the handoff file.**
- If the user passed an argument, use that path.
- Otherwise: `git rev-parse --show-toplevel` and look for `HANDOFF.md` at the root.
- If neither exists, tell the user there's no handoff to resume from and suggest running `/checkpoint` at the end of sessions going forward. Stop.

**2. Read `HANDOFF.md`.** The current handoff is at the top; older ones (if any) are under `## Previous handoffs` — usually you only need the current one, but skim the previous if the current is sparse.

**3. Reconcile with current git state.** Run in parallel:
- `git status`
- `git log --oneline -10`
- `git branch --show-current`
- `git stash list`

Compare against the handoff:
- **Branch match?** If the handoff says `feature/foo` and you're on `main`, flag it — the user may want to switch back.
- **New commits since handoff?** If commits exist that the handoff doesn't mention, surface them — work may have continued elsewhere (another machine, a teammate).
- **Working tree state match?** If handoff said "3 modified files" and now it's clean, something happened — commit, stash, or reset. Note it.
- **Files in flight still exist?** If the handoff lists files that no longer exist, flag it.

**4. Report status to the user.** Use this shape, no fluff:

```
Resuming from HANDOFF.md ({{date}}).

Last session: {{1-line summary from handoff}}

Status:
- Branch: {{branch}} {{match | MISMATCH — handoff said X}}
- Working tree: {{state}} {{match | drifted — see below}}
- {{any reconciliation notes — new commits, missing files, etc.}}

Next up (from handoff):
1. {{first next-step item}}
2. {{second, if any}}
3. ...

Blockers: {{list from handoff, or "none"}}
```

**5. Ask one question:** "Want me to start on {{first next-step item}}, or do you want to adjust the plan first?"

Wait for the user's answer. Don't auto-start work — the handoff is a starting point, not a contract. The user may have new priorities.

**6. As work progresses,** keep `HANDOFF.md` mentally in scope. When you complete items from "Next" or hit new blockers, you don't need to update the file mid-session — that's `/checkpoint`'s job at the end. But mention it if a blocker resolves or a major decision flips, so the user knows the handoff is going stale.

## What not to do
- Don't start coding before the user confirms the plan.
- Don't re-derive context from `git log` if the handoff already covers it — trust the handoff (but flag drift).
- Don't silently ignore drift between handoff and current state. Surface it.
- Don't delete or auto-archive the handoff. `/checkpoint` manages its lifecycle.
