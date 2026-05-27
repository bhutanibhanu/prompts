---
description: Pre-PR checklist + PR opener. Runs the full quality gate (tests, lint, type-check, security scan, manual verify) on the current branch, bails on first failure, and drafts/opens the PR only if everything is green. Use right before you would otherwise type 'git push' or open a PR by hand.
argument-hint: "[optional: PR title hint]"
---

# Ship — gate everything, then open the PR

You are running a quality gate on the current branch and, only if it passes, drafting and opening a PR. The goal is "I should never have to remember the checklist — `/ship` does it." If anything fails, stop and report; do **not** open the PR with failures.

## How to operate

**1. Sanity check the branch.**
- Confirm you're not on `main` / `master` / `trunk` — if you are, stop and ask.
- Confirm there are uncommitted changes or commits ahead of the base branch — if not, there's nothing to ship; stop.
- Identify the base branch (usually `main`; check `git symbolic-ref refs/remotes/origin/HEAD` or ask).

**2. Detect project conventions.**
Read in order (stop when something useful is found):
- `CLAUDE.md` or `AGENTS.md` for a "Before opening a PR" checklist
- `package.json` scripts (`test`, `lint`, `typecheck`, `build`)
- `pyproject.toml` / `tox.ini` / `pre-commit-config.yaml`
- `Makefile` (`test`, `lint`, `check`, `ci`)
- `.github/workflows/ci.yml` to see what CI actually runs

If you can't determine how to test/lint, ask.

**3. Run the gate. Stop on first failure.** In this order:

| Step | What | Why |
|---|---|---|
| a | `git status` + `git diff base...HEAD` summary | Sanity check what's about to ship |
| b | Linter / formatter | Catches the obvious before CI does |
| c | Type checker (if applicable) | Same |
| d | Unit + integration tests | The big one |
| e | `semgrep` via the Semgrep MCP, scoped to changed files | Security/quality static analysis |
| f | `/security-review` if the change touches auth, crypto, file I/O, or external input | Adversarial pass |
| g | `/verify` for any UI change — drive Playwright MCP to actually click the new flow | Tests verify code; this verifies behavior |
| h | Build (if applicable) | Catch packaging issues now |

If a step fails:
- Show the failure clearly
- Suggest a fix or offer to fix it
- **Do not proceed to PR creation.** Report and stop.

**4. Draft the PR.** Once everything is green:
- Title: imperative ≤70 chars, like a good commit message. Use the argument-hint if provided.
- Body, using this template:
  ```
  ## Summary
  - 1–3 bullets on what changed and *why*

  ## Changes
  - file-or-area: short description (one per major area)

  ## Test plan
  - [ ] item 1 (concrete, what to click/run to verify)
  - [ ] item 2
  - [ ] item 3
  ```
- If the brief or an ADR is relevant, link to it.
- If a Sentry issue is being fixed, reference its ID.

**5. Open the PR via GitHub MCP.**
- Push the branch if it's not on origin yet.
- Create the PR with the drafted title and body.
- Return the PR URL.

**6. Optional follow-ups (offer, don't do automatically):**
- "Want me to request a review from anyone?"
- "Want me to link this PR to an issue / Linear ticket / Sentry alert?"

## Tools to use

- Bash for tests/lint/typecheck/build.
- Semgrep MCP for the static analysis pass.
- Playwright MCP via `/verify` for UI changes.
- GitHub MCP for branch push (if needed) and PR creation.
- `/review` and `/security-review` skills for the deeper passes.

## Rules

- **First failure stops the gate.** Don't run later steps to "get a complete picture" — fix the broken one first.
- **Never `--no-verify`** on the push. Never bypass hooks. If a pre-commit hook fails, fix the root cause.
- **Never force-push** unless the user explicitly says so.
- **Read the PR body back** to the user before opening. Let them tweak it.
- **Don't open PRs to `main` directly on shared repos** unless that's the project's actual workflow per CLAUDE.md.

## What you are NOT doing

- Not merging the PR. That happens after review.
- Not deploying. CI/CD does that.
- Not creating new tests just to pass — if tests are missing for a code path, say so and let the user decide whether to add them now or defer.
