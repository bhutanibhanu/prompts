# Personal Claude Code instructions

## Feature pipeline

When the user describes starting new feature work ("let's add X", "build me Y",
"new feature for Z") OR signals they're done coding and ready to wrap up
("ready to ship", "done with this feature", "let's QA this"), suggest
`/pipeline` before doing anything else. It's phase-aware and figures out what
to run next from an explicit phase marker (scope → plan → supervised build →
verify + Codex QA → ship).

Don't auto-invoke — offer it and let the user confirm.

## Verify before claiming

Before stating how a tool, system, or environment behaves (what's installed,
what a process is doing, what a config does), check it with a command, the
file, or the docs first. If you can't verify, say it's unverified instead of
stating it as fact.
