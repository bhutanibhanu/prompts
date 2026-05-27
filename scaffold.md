---
description: Scaffold a brand-new project from a PROJECT_BRIEF.md (produced by /grill). Creates the repo skeleton — README, .gitignore, LICENSE, CLAUDE.md, AGENTS.md, ADR folder, CI config, test framework, linter, and a hello-world entry point. Use immediately after /grill on a new project.
argument-hint: "[path to PROJECT_BRIEF.md if not in current dir]"
---

# Scaffold — turn a brief into a repo

You are setting up an empty directory into a working project skeleton based on decisions already captured in `PROJECT_BRIEF.md`. Do not invent decisions that weren't made — if the brief is silent on something, ask.

## How to operate

**1. Locate and read the brief.**
- Default: look for `PROJECT_BRIEF.md` in the current directory.
- If not found, ask the user for the path.
- If still none, suggest they run `/grill` first and stop.

**2. Confirm the working directory is empty / safe.**
- If the directory has existing files (other than `PROJECT_BRIEF.md`), list them and ask whether to proceed or pick a different directory.

**3. Extract decisions from the brief.** Parse and confirm out loud:
- Project name
- Tech stack (language, framework, package manager)
- Test framework
- Linter / formatter
- Deployment target
- License (default MIT if not specified — confirm)
- Repo host (GitHub by default — confirm; ask for org/user)

If any of these are missing or ambiguous, ask before generating.

**4. Generate the skeleton.** Create in order:

```
.
├── README.md                  ← name, one-line pitch, install + run, lifted from brief
├── LICENSE                    ← MIT or whatever
├── .gitignore                 ← language-appropriate
├── .editorconfig              ← consistent indents
├── CLAUDE.md                  ← project rules for Claude Code
├── AGENTS.md                  ← project rules for Codex / other agents (mirror)
├── docs/
│   ├── PROJECT_BRIEF.md       ← move the brief here
│   └── adr/
│       └── 0000-record-architecture-decisions.md   ← seed ADR explaining the practice
├── .github/
│   └── workflows/
│       └── ci.yml             ← lint + test on push/PR
├── <language entry point>     ← hello-world that runs end-to-end
└── <package manifest>         ← package.json / pyproject.toml / Cargo.toml etc.
```

**CLAUDE.md and AGENTS.md content** — should include:
- One-paragraph project summary (from brief)
- Tech stack
- How to install / run / test (exact commands)
- Repo layout overview (top-level dirs explained)
- Conventions: branching, commit messages, PR style
- "Before opening a PR, run: …" checklist
- Link to `docs/adr/` for architecture decisions
- Any anti-goals from the brief

**5. Run the initial verification.** Actually execute:
- Install deps (`npm install` / `pip install -e .` / `cargo build` / etc.)
- Run the hello-world to confirm it works
- Run the linter on the generated code
- Run the test framework (even if there's only a smoke test)

If anything fails, fix it before reporting done.

**6. Initialize git and (optionally) create the GitHub repo.**
- `git init`, `git add -A`, single initial commit
- Ask the user if they want to create a GitHub repo now. If yes:
  - Use the GitHub MCP (if available) — `mcp__github__create_repository` style call.
  - If MCP isn't connected, fall back to instructing the user to run `gh repo create` themselves, then `git remote add origin … && git push -u origin main`.
- Do not create the GitHub repo without explicit confirmation.

**7. Report what was created.** A short summary:
- Files created (paths, one line each)
- What was installed
- What ran successfully
- Suggested next step: pick the first feature from `docs/PROJECT_BRIEF.md` and start with `/grill <feature>`

## Tools to use

- Filesystem MCP for cross-project template lookup (if scaffolding a kind of project you've done before in `~/dev/`).
- Context7 for current docs on the chosen framework (so the package manifest pins recent versions, not 2-year-old ones).
- Bash for the actual install/test runs.
- GitHub MCP for repo creation (with explicit user OK).

## Rules

- **Never overwrite existing files** without asking. If the directory has any non-brief file, stop and ask.
- **Pin versions to current latest minor** — use Context7 to check, don't hallucinate.
- **One commit, clear message**: `chore: initial scaffold from PROJECT_BRIEF.md`.
- **If you can't make the hello-world run, do not declare done.** Report what blocked you.
- **Don't add features.** Just the skeleton. The first feature comes in the next session via `/grill <feature>` + implementation.

## What you are NOT doing

- Not implementing the first feature.
- Not setting up monitoring/deployment beyond the basic CI config.
- Not writing more than ADR-0000 (the meta-ADR about ADRs). Real ADRs come via `/adr` on demand.
