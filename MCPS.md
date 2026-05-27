# MCP cheat sheet

What's installed, when to reach for each.

## 1. GitHub (`github`)

**What it does:** PR creation/review, issue management, repo browsing, CI status, branch comparison, releases. All authenticated via your PAT, so it works on your private repos too.

**When to use:**
- About to open a PR → "create a PR from this branch with a summary of these commits"
- Reviewing someone else's PR → "show me the diff for PR #42, then the review comments"
- Triaging issues → "list open issues in repo X tagged 'bug'"
- Checking CI before merging → "is the latest commit on this branch green?"
- Finding context for a task → "show me issues mentioning 'auth refactor' across these 3 repos"

**Don't bother for:** local-only git ops (`git log`, `git diff` of working tree) — your shell still wins.

---

## 2. Playwright (`playwright`)

**What it does:** Spins up a real Chromium browser, lets the model click, type, screenshot, scroll, and inspect the DOM. Perfect for verifying web changes end-to-end.

**When to use:**
- After a UI change → "open the dev server, click through the signup flow, screenshot the result"
- E2E test scaffolding → "draft a Playwright test that covers the login path"
- Reproducing a bug → "load this URL, fill the form like the bug report says, capture what breaks"
- Comparing before/after on a refactor → "screenshot the page on `main` and on this branch, diff them"
- Browser automation tasks → scraping a single page, filling a form, taking visual diffs

**Don't bother for:** Sites behind aggressive bot protection (Cloudflare Turnstile, etc.) — the browser is real but it's still automated and gets blocked.

---

## 3. Context7 (`context7`)

**What it does:** Pulls *current* documentation for any library at query time. Solves the "Claude wrote code against a 2-year-old API" problem.

**When to use:**
- Writing code with a fast-moving library (Next.js, React, Tailwind, Prisma, etc.) → "use context7 for the latest Next.js App Router caching API"
- Debugging an error message that smells like an API change
- Library migration → "what changed in Tailwind v4 from v3?"
- Anytime the model seems unsure and might hallucinate a method name

**Trigger phrase:** add "use context7" or "check current docs" to your prompt — that's what nudges the model to call it. Or it'll auto-invoke when the question is doc-shaped.

**Don't bother for:** Your own code, internal/proprietary APIs, very obscure libraries (it might not have them indexed).

---

## 4. Sentry (`sentry`)

**What it does:** Authenticated access to your Sentry org — issues, events, error traces, performance data, releases.

**When to use:**
- After a deploy → "any new errors in the last hour for project X?"
- Triaging a specific error → "show me the latest occurrence of issue #SENTRY-123 with stack trace and breadcrumbs"
- Reproducing a bug → "this Sentry issue happens to 5% of users — what's the common pattern in the breadcrumbs?"
- Closing the dev loop → "I just pushed a fix for issue #X, mark it resolved"

**Don't bother for:** Projects that aren't on Sentry, local-only error chasing.

---

## 5. Semgrep (`semgrep`)

**What it does:** Static analysis on your code — finds security issues, anti-patterns, custom rule violations.

**When to use:**
- Before pushing → "scan this changed code for security issues"
- Writing security-sensitive code → "check this auth flow against OWASP top-10 rules"
- Code review of a PR → "what would semgrep flag in this diff?"
- Pairs naturally with the built-in `/security-review` skill — security-review asks the questions, semgrep brings receipts.

**Don't bother for:** Generic code style/lint stuff — your project's ESLint/ruff/etc. already does that better.

---

## 6. Sequential Thinking (`sequential-thinking`)

**What it does:** Gives the model a structured surface to *think* across multiple steps — show its work, branch when needed, revise earlier reasoning. Helpful when the answer requires careful reasoning rather than knowledge lookup.

**When to use:**
- Architecture decisions → "should we use a queue or a cron for this — think it through"
- Complex debugging where the cause is non-obvious
- Algorithmic problems
- Anywhere you'd want to see the model's reasoning chain laid out
- The `/grill` skill benefits from this when working through tradeoffs

**Don't bother for:** Simple questions, code generation tasks where the answer is mostly retrieval-shaped.

---

## 7. Filesystem (`filesystem`)

**What it does:** Read/write/list files under `~/dev` — a scoped, secure surface for cross-project file ops.

**When to use:**
- Pulling context from another project → "look at how we did auth in ~/dev/old-project, apply the same pattern here"
- Comparing files across projects → "diff the package.json files in these 3 repos"
- Moving snippets between projects safely

**Don't bother for:** Files in your current project — Claude Code's built-in Read/Edit/Write are faster and more familiar.

**Scope:** `~/dev` only. Files outside that are invisible to this MCP (intentional safety).

---

## Combining MCPs — common patterns

**Building a new feature on a web app:**
1. `/grill` → scope it
2. context7 → pull current docs for the libraries you'll touch
3. write the code
4. semgrep → security/quality scan
5. playwright → click through and verify
6. github → open PR

**Triaging a prod incident:**
1. sentry → find the issue, get the stack trace
2. github → check what shipped recently that could have caused it
3. (read code) → fix
4. sentry → confirm rate dropped after deploy
5. github → close the issue

**Architecture decision:**
1. sequential-thinking → reason through options
2. context7 → check the docs for any library being considered
3. `/grill` → capture the decision as an ADR

---

## Where the configs live

- **Claude Code:** `~/.claude.json` (top-level `mcpServers`)
- **Codex CLI:** `~/.codex/config.toml` (sections like `[mcp_servers.NAME]`)
- **Token rotation:** GitHub PAT and Sentry token are both stored in both configs. Rotate by:
  - editing the configs directly, OR
  - `claude mcp remove <name>` + re-add (Claude side)

## Adding a new MCP later

The general flow:

```bash
# Claude Code
claude mcp add --scope user NAME -- npx -y @some/package
# or HTTP:
claude mcp add --scope user --transport http NAME https://some.url --header "Authorization: Bearer ..."
# or with env:
claude mcp add-json --scope user NAME '{"command": "npx", "args": ["..."], "env": {"KEY": "value"}}'

# Codex
cat >> ~/.codex/config.toml <<'EOF'

[mcp_servers.NAME]
command = "npx"
args = ["-y", "@some/package"]
startup_timeout_sec = 60
EOF
```

For HTTP-only MCPs that Codex can't speak directly, bridge with `mcp-remote`:
```toml
[mcp_servers.NAME]
command = "npx"
args = ["-y", "mcp-remote", "https://some.url", "--header", "Authorization: Bearer TOKEN"]
```
