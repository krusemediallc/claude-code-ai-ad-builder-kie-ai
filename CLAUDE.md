# Claude Code — project instructions

## First-time setup

If `.env` does not exist, tell the user to run `./scripts/setup.sh` or walk them through:
1. Copy `.env.example` to `.env`.
2. Paste their KIE API key into `.env` (line: `KIE_API_KEY=`). Get a key from https://kie.ai/api-key.
3. Run `./scripts/check-kie-env.sh` to verify.

If `MASTER_CONTEXT.md` does not exist, copy `MASTER_CONTEXT.template.md` to `MASTER_CONTEXT.md`.

## Every session

1. Read **[MASTER_CONTEXT.md](MASTER_CONTEXT.md)** for brand voice, credit costs, and accumulated learnings.
2. Use the KIE AI skill **`kie-ai-api`** (`.claude/skills/kie-ai-api/SKILL.md`) for API calls, prompts, and polling.
3. If `MASTER_CONTEXT.md` has empty fields (credit costs), offer to populate them — ask the user and **write the values back into MASTER_CONTEXT.md** so future sessions have them.

## After significant changes

Append a short dated note to **MASTER_CONTEXT.md** under Changelog (Decision / What changed / Why).

## Skill edits

Edit the canonical source at `skills/kie-ai-api/`. Run `./scripts/sync-skill.sh` to copy changes to `.claude/skills/` and `.cursor/skills/`.
