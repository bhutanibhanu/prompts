---
description: Write an Architecture Decision Record (ADR) — a short, dated, numbered doc that captures one technical decision, its context, the alternatives considered, and the consequences. Use whenever you're making a non-trivial tech choice that future you (or a teammate) will need to understand.
argument-hint: "[optional: one-line decision title, e.g. 'use Postgres for primary store']"
---

# ADR — capture one decision

You are writing exactly one ADR. The format is short, structured, and append-only. Future-you should be able to read it in 60 seconds and understand both the call and why.

## How to operate

**1. Locate the ADR folder.**
- Default: `docs/adr/`
- If it doesn't exist, ask whether to create it. If yes, also create `docs/adr/0000-record-architecture-decisions.md` (the meta-ADR explaining the practice) using the template at the bottom.

**2. Determine the ADR number.**
- List existing ADRs in `docs/adr/`. The new one is `max(existing) + 1`, zero-padded to 4 digits.

**3. Get the decision content.** Ask the user, in this order, one batch:
- **Title** (imperative, ≤80 chars; e.g. "Use Postgres for primary store" not "We chose Postgres")
- **Context** — what problem prompted this decision; what constraints apply
- **Decision** — the actual choice in one sentence
- **Alternatives considered** — at least one, ideally 2–3, each with a one-line "rejected because …"
- **Consequences** — what becomes easier, what becomes harder, what new risks appear

If the user is sketchy on alternatives or consequences, push back:
- "What else did you consider, even briefly?"
- "What does this decision lock us out of?"
- Use Sequential Thinking MCP if it helps surface tradeoffs.

**4. Write the file.** Path: `docs/adr/NNNN-kebab-slug.md` where slug is derived from the title.

Use this template:

```markdown
# ADR-NNNN: Title

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** (names or roles)
- **Related:** ADR-XXXX, PROJECT_BRIEF.md#section (if applicable)

## Context

(2–4 paragraphs: what problem are we solving, what constraints apply, what existed before this decision)

## Decision

(1–3 sentences stating the call clearly)

## Alternatives considered

- **Option A** — rejected because …
- **Option B** — rejected because …
- (Add as many as were seriously considered. "We didn't consider anything else" is a yellow flag — push back.)

## Consequences

**Positive:**
- …

**Negative / costs:**
- …

**Neutral / things to watch:**
- …

## References

- Links to docs, tickets, conversations that informed the decision.
```

**5. Report.**
- Path of the file created
- One-line summary of the decision
- Suggest committing it now if on a branch: `git add docs/adr/NNNN-*.md && git commit -m "docs: ADR-NNNN <title>"`

## Statuses

ADRs are append-only. To change a decision, write a new ADR that *supersedes* the old one:
- New ADR: Status `Accepted`, with `Supersedes: ADR-NNNN` in the frontmatter.
- Old ADR: edit status to `Superseded by ADR-MMMM`, add date.

Other valid statuses: `Proposed` (under discussion), `Deprecated` (no longer applies but not replaced).

## Tools to use

- Filesystem / Read to inspect existing ADRs.
- Sequential Thinking MCP if the decision is genuinely hard and you need to walk tradeoffs.
- Context7 if the decision involves a library and you want to anchor it to current docs.

## Rules

- **One decision per ADR.** If the user tries to cram three decisions in, ask which one this ADR is about; the others get their own.
- **Past tense for the decision section.** "We chose X" not "We will choose X" — ADRs are records, not plans.
- **Don't editorialize.** State the alternatives factually; "Option B was bad" is not a reason. Say *why*.
- **If you can't articulate at least one trade-off / consequence, the decision isn't ready for an ADR yet.** Discuss more first.

## Meta-ADR template (ADR-0000)

When initializing the `docs/adr/` folder, seed it with:

```markdown
# ADR-0000: Record architecture decisions

- **Status:** Accepted
- **Date:** YYYY-MM-DD

## Context
We need to record the significant decisions made on this project so that future contributors (including future-us) understand why things are the way they are.

## Decision
We use Architecture Decision Records as described by Michael Nygard's pattern. Each significant decision gets a short, numbered, dated file in `docs/adr/`. ADRs are append-only; superseded decisions are marked but not deleted.

## Consequences
- Decisions are auditable and explainable to newcomers.
- We commit to the upkeep — every significant call gets an ADR.
- Light overhead per decision, but pays back the first time someone asks "why did we…?"
```

## What you are NOT doing

- Not making the decision *for* the user. The ADR captures a decision already made.
- Not writing ADRs for trivial choices (variable naming, file organization). Reserve ADRs for things that affect architecture, scale, security, or what's possible later.
