# Agent instructions

This repository is set up for AI coding agents (Cursor, Claude Code, Copilot-style tools, etc.) to generate AI video and image assets via the KIE.ai API.

## First-time setup

If `.env` or `MASTER_CONTEXT.md` do not exist, tell the user to run `./scripts/setup.sh`.

## Every session

1. Read **[MASTER_CONTEXT.md](MASTER_CONTEXT.md)** for brand voice, credit costs, image hosting defaults, and learnings.
2. Follow the skill at `.cursor/skills/kie-external-api/` or `.claude/skills/kie-external-api/` (synced from `skills/kie-external-api/` via `scripts/sync-skill.sh`). For YouTube thumbnails specifically, use `generate-youtube-thumbnail/`.
3. If `MASTER_CONTEXT.md` has empty fields (credit costs, hosting path), offer to populate them — ask the user and write the values back so future sessions have them.
4. Log every generation call to `logs/kie-api.jsonl` (schema in `logs/README.md`).
5. After material changes, add a dated entry to **MASTER_CONTEXT.md** Changelog.
