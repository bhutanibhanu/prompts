---
description: Write a HANDOFF.md at the repo root capturing session state — what was being worked on, current git state, files in flight, what's done, what's next, known blockers. Use at the end of a session, before stopping work, or whenever you want a clean resumption point for a future session.
argument-hint: "[optional: one-line summary of the session]"
---

# Checkpoint — write a clean handoff for the next session

You are saving session state so a future session (yourself or someone else) can pick up where this one left off without re-deriving everything from git history and transcripts. The output is a single `HANDOFF.md` at the repo root.

## How to operate

**1. Find the repo root.**
- Run `git rev-parse --show-toplevel`. If not in a git repo, stop and tell the user — handoff doesn't make sense outside a repo. Offer to write it to the current working directory instead if they confirm.

**2. Gather state. Run these in parallel:**
- `git status` (no `-uall`)
- `git diff --stat` (unstaged) and `git diff --stat --staged` (staged)
- `git log --oneline -20`
- `git branch --show-current` and base branch (`git symbolic-ref refs/remotes/origin/HEAD` if available)
- `git stash list`

**3. Draft the handoff.** Pull from:
- The git state above (branch, dirty files, recent commits)
- The current conversation: what task was being worked on, decisions made, dead ends hit, what's still TODO
- Any existing `HANDOFF.md` (preserve historical context — see step 5)

Use this structure:

```markdown
# Handoff

_Last updated: {{YYYY-MM-DD HH:MM}} by {{session summary or user-provided one-liner}}_

## What I was doing
{{1-3 sentences: the goal of the session, not a play-by-play}}

## Status
- **Branch:** `{{branch}}` (base: `{{base}}`)
- **Working tree:** {{clean | N modified, M staged, K untracked}}
- **Recent commits:** {{last 1-3 relevant commit subjects}}

## Files in flight
{{bulleted list of files touched this session, with a one-line note on each — what changed and whether it's done or in-progress}}

## Done
- {{concrete completed items}}

## Next
- {{ordered list of next steps — be specific, name files/functions where possible}}

## Blockers / open questions
- {{anything stuck, waiting on, or undecided. Empty section if none.}}

## Notes for next session
{{free-form: gotchas, things you almost forgot, why you chose X over Y, links to relevant external context}}
```

**4. Show the draft to the user before writing.** Let them edit/add/remove anything. Vibe-coding handoffs are only useful if they reflect what the *user* thinks matters, not just what was logged.

**5. If `HANDOFF.md` already exists:**
- Read it first.
- Move its current content under a `## Previous handoffs` section at the bottom (most recent first), keeping only the last 3 prior handoffs to avoid bloat. Older ones drop off.
- Write the new handoff at the top.

**6. Write the file** at `{repo_root}/HANDOFF.md`.

**7. Flag gitignore.** After writing, check if `HANDOFF.md` is gitignored. If not, tell the user:
> `HANDOFF.md` isn't gitignored. If you want this to be private session state (not shared with teammates via commits), add it to `.gitignore`. If you want it shared as a team handoff doc, commit it.
>
> Don't auto-edit `.gitignore` — let the user decide.

**8. Report.** One sentence: "Checkpointed to `HANDOFF.md` — N items done, M next." Done.

## What not to do
- Don't include secrets, tokens, or credentials, even if they appeared in the session.
- Don't summarize the entire git history — only what's relevant to *this* session's continuation.
- Don't write a long narrative. Bullets and short sentences. Future-you will skim, not read.
- Don't auto-commit `HANDOFF.md`. The user decides.
