# Personal Claude Code instructions

## Feature pipeline

When the user describes starting new feature work ("let's add X", "build me Y",
"new feature for Z") OR signals they're done coding and ready to wrap up
("ready to ship", "done with this feature", "let's QA this"), suggest
`/pipeline` before doing anything else. It's phase-aware and figures out what
to run next from git state (Phase 1 scope, Phase 3 handoff + Codex QA,
Phase 6 ship).

Don't auto-invoke — offer it and let the user confirm.
