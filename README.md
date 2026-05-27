# prompts

Reusable LLM prompts that work across multiple coding agents (Claude Code, Codex CLI, etc.).

## How it works

Each prompt is one markdown file in this folder. They're tool-agnostic — frontmatter keys that one tool doesn't recognize are ignored by the others.

The same file is symlinked into each tool's expected location so updates propagate automatically.

## Prompts

| File | Slash command | What it does |
|---|---|---|
| `grill.md` | `/grill` | Interrogates a project (new or in-progress) to nail down goals, requirements, architecture, SDLC plan, and risks before code is written. |

## Where they're wired up

| Tool | Path | Type |
|---|---|---|
| Claude Code | `~/.claude/skills/<name>/SKILL.md` | symlink → this folder |
| Codex CLI   | `~/.codex/prompts/<name>.md`       | symlink → this folder |

## Adding a new prompt

1. Drop `whatever.md` in this folder. Frontmatter should include at least `description`.
2. Symlink into the tools you want it in:
   ```bash
   # Claude Code
   mkdir -p ~/.claude/skills/whatever
   ln -s ~/dev/prompts/whatever.md ~/.claude/skills/whatever/SKILL.md

   # Codex CLI
   ln -s ~/dev/prompts/whatever.md ~/.codex/prompts/whatever.md
   ```
3. Both tools pick up new prompts without restart.

## Editing

Edit the source file in this folder. Both tools read through the symlink so changes are live.
