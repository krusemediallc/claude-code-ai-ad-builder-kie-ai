#!/usr/bin/env bash
# Copies the canonical skill from skills/kie-ai-api to Claude Code and Cursor paths.
# Called automatically by scripts/setup.sh. Run manually after editing any file in skills/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/skills/kie-ai-api"
if [[ ! -f "$SRC/SKILL.md" ]]; then
  echo "Expected $SRC/SKILL.md — aborting." >&2
  exit 1
fi
for dest in "$ROOT/.claude/skills/kie-ai-api" "$ROOT/.cursor/skills/kie-ai-api"; do
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$SRC" "$dest"
done
echo "Synced kie-ai-api skill to .claude/skills and .cursor/skills"
