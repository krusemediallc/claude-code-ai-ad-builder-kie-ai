# Instructions for non-Claude agents (Cursor, Copilot, Manus, etc.)

## First-time setup

Run `./scripts/setup.sh` or manually:
1. Copy `.env.example` → `.env`, add your `KIE_API_KEY` (from https://kie.ai/api-key).
2. Copy `MASTER_CONTEXT.template.md` → `MASTER_CONTEXT.md`.

## Every session

1. Read **`MASTER_CONTEXT.md`** for brand voice, credit costs, and learnings.
2. Use the skill at `skills/kie-ai-api/SKILL.md` (or `.cursor/skills/kie-ai-api/SKILL.md` for Cursor).
3. Populate empty `MASTER_CONTEXT.md` fields when prompted.
4. Append a dated note to `MASTER_CONTEXT.md` Changelog after significant changes.
