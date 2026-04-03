#!/usr/bin/env bash
# First-run setup for the KIE AI skill pack.
# Creates .env, MASTER_CONTEXT.md, syncs skills, and verifies API connectivity.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== KIE AI Skill Pack Setup ==="
echo ""

# ── Step 1: .env ──────────────────────────────────────────────────────────────
if [[ ! -f "$ROOT/.env" ]]; then
  cp "$ROOT/.env.example" "$ROOT/.env"
  echo "Created .env from template."
  echo ""
  echo "Go to https://kie.ai/api-key and copy your API key."
  echo ""
  echo "Paste it below (or press Enter to skip and edit .env manually):"
  read -r api_key
  if [[ -n "$api_key" ]]; then
    sed "s|KIE_API_KEY=.*|KIE_API_KEY=$api_key|" "$ROOT/.env" > "$ROOT/.env.tmp" && mv "$ROOT/.env.tmp" "$ROOT/.env"
    echo "API key saved to .env"
  else
    echo "Skipped — edit .env manually before using the skill."
  fi
else
  echo ".env already exists — skipping."
fi

echo ""

# ── Step 2: MASTER_CONTEXT.md ────────────────────────────────────────────────
if [[ ! -f "$ROOT/MASTER_CONTEXT.md" ]]; then
  cp "$ROOT/MASTER_CONTEXT.template.md" "$ROOT/MASTER_CONTEXT.md"
  echo "Created MASTER_CONTEXT.md from template."
  echo "The agent will help you fill in credit costs on first use."
else
  echo "MASTER_CONTEXT.md already exists — skipping."
fi

echo ""

# ── Step 3: Sync skills to .claude/ and .cursor/ ─────────────────────────────
"$ROOT/scripts/sync-skill.sh"

echo ""

# ── Step 4: Verify API connectivity ──────────────────────────────────────────
if grep -q "your_api_key_here" "$ROOT/.env" 2>/dev/null; then
  echo "API key not yet set in .env — skipping connectivity check."
  echo "Run ./scripts/check-kie-env.sh after adding your key."
else
  "$ROOT/scripts/check-kie-env.sh"
fi

echo ""
echo "Setup complete. Open this folder in Claude Code or Cursor to start."
