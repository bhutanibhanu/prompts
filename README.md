# prompts

Reusable LLM prompts that work across multiple coding agents (Claude Code, Codex CLI, etc.).

## How it works

Each prompt is one markdown file in this folder. They're tool-agnostic — frontmatter keys that one tool doesn't recognize are ignored by the others.

The same file is symlinked into each tool's expected location so updates propagate automatically.

## Prompts

The set forms a rough end-to-end SDLC pipeline:

| File | Slash command | Phase | What it does |
|---|---|---|---|
| `grill.md` | `/grill` | Plan | Interrogates a project (new or in-progress) to nail down goals, requirements, architecture, SDLC plan, risks. |
| `scaffold.md` | `/scaffold` | Bootstrap | Reads `PROJECT_BRIEF.md` and creates the repo skeleton (README, CI, tests, lint, ADR folder, CLAUDE/AGENTS.md). |
| `adr.md` | `/adr` | Decide | Writes one Architecture Decision Record at a time. Numbered, dated, append-only. |
| `ship.md` | `/ship` | Quality gate | Runs the full pre-PR checklist (lint, tests, semgrep, /verify, /security-review), drafts and opens the PR if everything passes. |
| `triage.md` | `/triage` | Post-deploy | Sentry issue → recent deploys → code → root-cause hypothesis → suggested action. |

Plus a reference:

| File | What |
|---|---|
| `MCPS.md` | Cheat sheet for the installed MCPs (GitHub, Playwright, Context7, Sentry, Semgrep, Sequential Thinking, Filesystem) — when to reach for each. |

## Typical workflow

```
new project idea
   │
   ▼
/grill                       → PROJECT_BRIEF.md
   │
   ▼
/scaffold                    → repo skeleton, CI, tests, CLAUDE.md, ADR-0000
   │
   ▼
(for each major decision)
/adr "Use Postgres…"         → docs/adr/0001-use-postgres.md
   │
   ▼
(for each feature)
/grill <feature>             → docs/<feature>-design.md
   │
   write code, tests
   │
   ▼
/ship                        → lint + test + semgrep + /verify → PR opened
   │
   (CI passes, merge, deploy)
   │
   ▼
/triage <SentryID>           → only when something breaks in prod
```

## Where they're wired up

| Tool | Path | Type |
|---|---|---|
| Claude Code | `~/.claude/skills/<name>/SKILL.md` | symlink → this folder |
| Codex CLI   | `~/.codex/prompts/<name>.md`       | symlink → this folder |

## Adding a new prompt

1. Drop `whatever.md` in this folder with at least a `description` in frontmatter.
2. Symlink into the tools you want it in:
   ```bash
   mkdir -p ~/.claude/skills/whatever
   ln -s ~/dev/prompts/whatever.md ~/.claude/skills/whatever/SKILL.md
   ln -s ~/dev/prompts/whatever.md ~/.codex/prompts/whatever.md
   ```
3. Both tools pick up new prompts without restart.

## Editing

Edit the source file in this folder. Both tools read through the symlink so changes are live.
