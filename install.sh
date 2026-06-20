#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prompts that work in both Claude Code and Codex CLI.
CROSS_TOOL=(adr checkpoint grill resume scaffold ship triage)

# Prompts that only make sense in Claude Code (use its Skill tool / orchestrate
# other slash commands / dispatch subagents).
CLAUDE_ONLY=(pipeline plan build)

link() {
  local src="$1"
  local dst="$2"

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      echo "  ok    $dst"
      return
    fi
    echo "  ERROR $dst is a symlink to $current (expected $src)."
    exit 1
  fi

  if [[ -e "$dst" ]]; then
    echo "  ERROR $dst exists and is not a symlink. Move aside and re-run."
    exit 1
  fi

  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "  link  $dst"
}

echo "Wiring prompts from $REPO_DIR"

echo
echo "Claude Code skills (~/.claude/skills/<name>/SKILL.md):"
for name in "${CROSS_TOOL[@]}" "${CLAUDE_ONLY[@]}"; do
  mkdir -p "$HOME/.claude/skills/$name"
  link "$REPO_DIR/$name.md" "$HOME/.claude/skills/$name/SKILL.md"
done

echo
echo "Codex CLI prompts (~/.codex/prompts/<name>.md):"
for name in "${CROSS_TOOL[@]}"; do
  link "$REPO_DIR/$name.md" "$HOME/.codex/prompts/$name.md"
done

echo
echo "Claude Code global instructions (~/.claude/CLAUDE.md):"
link "$REPO_DIR/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

echo
echo "Done."
