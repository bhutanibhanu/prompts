---
description: Triage a production incident from Sentry — pull the issue details, correlate with recent deploys via GitHub, read the relevant code, hypothesize a root cause, and suggest a fix. Use when something breaks in prod, or proactively to investigate elevated error rates.
argument-hint: "[optional: Sentry issue ID like 'PROJECT-1234' or short description]"
---

# Triage — from Sentry alert to plausible fix

You are investigating one production issue, end to end. The output is a short triage write-up + a concrete next action (fix, mitigation, or escalation). Do not jump to a fix without evidence.

## How to operate

**1. Identify the issue.**
- If the user passed an ID: use it.
- Else: ask "which issue?" — could be an ID, a Sentry URL, a description, or "show me the top 3 from the last 24 hours."
- Use the Sentry MCP to resolve to a concrete issue object.

**2. Pull issue context.** Via Sentry MCP:
- Title, level (error/warning/fatal), event count, user count, first seen, last seen
- Latest event's stack trace, breadcrumbs, request context, user context, environment, release version
- Issue status (unresolved, ignored, etc.) and assignment

**3. Correlate with deploys.** Via GitHub MCP:
- Get commits between the last known-good release and the release tagged on the failing events
- Look for changes touching files in the stack trace
- Note any PRs merged in that window with relevant titles (auth, perf, the affected feature)

**4. Read the relevant code.**
- For each frame in the stack trace within your own codebase (skip vendor/node_modules), read the source.
- Look for:
  - Off-by-one, null-handling, missing await
  - Recent changes in `git blame` of that line
  - Assumptions that don't hold given the breadcrumbs / request context

**5. Hypothesize the root cause.**
Use Sequential Thinking MCP if the path isn't obvious. Form a ranked list:
- **Most likely:** … because …
- **Possible:** … because …
- **Unlikely but worth ruling out:** … because …

Cite specific evidence — stack frames, breadcrumb timestamps, commits, code lines.

**6. Recommend an action.** One of:
- **Fix here, now:** if the root cause is clear and the diff is small. Describe the fix in code (don't apply yet — let the user OK it).
- **Open an issue:** if it needs more investigation than this session affords.
- **Roll back:** if a recent deploy almost certainly caused it and rollback is cheaper than fix-forward.
- **Mitigate first, fix later:** e.g. feature flag off, kill switch, increase a timeout — buy time, then fix properly.
- **Not actionable / noise:** if it's a client-side error you can't fix, a known issue, or a transient infrastructure blip. Suggest ignoring/grouping in Sentry.

**7. Write the triage doc.** Save to `docs/incidents/YYYY-MM-DD-<short-slug>.md` (or `docs/triage/` if that folder already exists). Template:

```markdown
# Incident: <title>

- **Sentry:** <issue ID / URL>
- **Severity:** error / warning / fatal
- **First seen:** ISO datetime  |  **Last seen:** ISO datetime
- **Users affected:** N  |  **Events:** N
- **Status:** investigating / mitigating / fixed / monitoring

## Symptoms
What the user / monitoring sees.

## Stack trace (key frames)
```
…relevant 3–5 frames…
```

## Breadcrumbs of interest
- ts: …  what happened
- ts: …  what happened next

## Suspect deploys
- PR #N — <title> — <one-line of why this is suspect>

## Hypothesis
Most likely: … Evidence: …
Possible: … Evidence: …

## Recommended action
<one of: fix here / roll back / mitigate / open issue / ignore>
<specifics>

## Follow-ups
- [ ] item
- [ ] item
```

**8. If fixing now:**
- Hand off to a normal coding flow: make the change, write a regression test, run `/ship`.
- The fix's PR description should reference this incident doc and the Sentry issue ID.

## Tools to use

- **Sentry MCP** — issue details, events, breadcrumbs.
- **GitHub MCP** — recent commits/PRs, file blame, deployment history.
- **Sequential Thinking** — for non-obvious root cause analysis.
- **Filesystem / Read** — to inspect related code in this or other repos.
- **Bash** — for `git log`, `git blame` of specific lines.

## Rules

- **No fix without evidence.** Don't suggest a code change unless you can point to the line and explain why it's wrong given the trace.
- **Distinguish proximate from root cause.** "We threw a null pointer" is proximate. "We assumed the API always returns `user`, but the new endpoint sometimes doesn't" is root.
- **Be honest about uncertainty.** If you're guessing, label it. "Most likely" beats fake confidence.
- **Sentry status hygiene:** after fix, suggest resolving the Sentry issue *only after the fix is deployed and the error rate has actually dropped*. Don't preemptively resolve.

## What you are NOT doing

- Not paging anyone — you're not on-call rotation.
- Not deploying the fix yourself — that's CI/CD's job after the PR merges.
- Not declaring the incident resolved until prod metrics confirm.
