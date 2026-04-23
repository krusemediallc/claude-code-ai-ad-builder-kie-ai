# KIE.ai Video + Image — Agent Skill Pack

Create AI marketing videos and images using your [KIE.ai](https://kie.ai) account, powered by AI agents in **Claude Code** or **Cursor**. Supports Veo 3.1, Sora 2, Kling 3.0, Nano Banana 2 (and Pro), Seedance 2, and other models in the [KIE marketplace](https://kie.ai/market).

## Get started (5 minutes)

### 1. Clone this repo

```bash
git clone <repo-url>
cd "KIE AI  + Claude Code"
```

### 2. Run setup

```bash
./scripts/setup.sh
```

This will:
- Ask for your **KIE API key** (find it at [kie.ai/api-key](https://kie.ai/api-key))
- Save it securely in `.env` (never committed to git)
- Verify your connection to KIE
- Create your personal `MASTER_CONTEXT.md` workspace file
- Sync skills to `.claude/skills/` and `.cursor/skills/`

### 3. Open in your AI editor

**Claude Code:** Open the folder. The agent loads both skills automatically.

**Cursor:** Open the folder. The skills are at `.cursor/skills/kie-external-api/` and `.cursor/skills/generate-youtube-thumbnail/`.

### 4. Start creating

The agent handles API calls, polling, prompt engineering, and file organization. Main workflows:

#### Create an AI influencer (character sheet)

> "Create a new AI influencer — a 22-year-old college student with freckles"

The agent generates a full-body hero image for your approval via Nano Banana 2, then creates 9 additional angles (3/4 views, profile, closeup, etc.) using the hero as a reference URL. All 10 images are saved to `references/influencers/` for future use.

#### Generate UGC product selfie stills

> "Generate a UGC selfie of Sofia holding the cola can in her bedroom"

Combines your character + product photo + style references from `references/aesthetics/ugc-selfie/` into an authentic-looking iPhone selfie frame grab via Nano Banana 2. Includes skin realism and camera imperfections to fight AI's polished default.

#### Animate a still into video

> "Turn that image into a video — have her talk about the product"

Uses Veo 3.1 with `generationType: REFERENCE_2_VIDEO` to animate your approved UGC still. Natural human motion (eye contact breaks, head tilts, body shifts) and dialogue embedded in the prompt.

#### Quick UGC video (no starting frame)

> "Generate a UGC video ad for this product" + drop a product photo URL

Uses Sora 2 text-to-video (or image-to-video with the product photo URL) to generate a video directly.

#### YouTube thumbnail batch

> "Generate 10 thumbnail variants for this video about prompt engineering"

Uses the `generate-youtube-thumbnail` skill — 5 CTR-tested formulas, likeness lockdown via reference URLs, parallel batch firing against Nano Banana 2. See `skills/generate-youtube-thumbnail/`.

#### Other things to try

- "Recreate this influencer's look from a reference photo"
- "Clone this reference ad" (see `skills/kie-external-api/prompting/clone-ad/`)
- "Analyze this reference video and give me a prompt that recreates it" (see `skills/kie-external-api/prompting/analyze-video/`)

## What's in the box

| Path | What it does |
|------|-------------|
| `skills/kie-external-api/` | The core skill: API reference, prompting guide, per-model prompt library, analyze-video + clone-ad workflows |
| `skills/generate-youtube-thumbnail/` | Specialized YouTube thumbnail skill with 5 CTR formulas and parallel batch script |
| `MASTER_CONTEXT.template.md` | Template for your workspace context (credit costs, brand voice, image hosting, learnings) |
| `MASTER_CONTEXT.md` | Your personalized copy (created by setup, not committed to git) |
| `.env` | Your API key (created by setup, never committed) |
| `scripts/setup.sh` | One-time setup |
| `scripts/sync-skill.sh` | Copies skill edits to `.claude/` and `.cursor/` directories |
| `scripts/check-kie-env.sh` | Tests API connectivity |
| `logs/kie-api.jsonl` | Append-only log of every generation call — powers credit estimates. See `logs/README.md` |
| `references/` | Drop reference images here (influencers, products, aesthetics) — gitignored |
| `outputs/` | Per-session download folders (`outputs/{YYYY-MM-DD}-{slug}/`) — gitignored |

## Your API key

Your key authenticates with the KIE API. During setup you paste it once and the agent uses it from `.env` automatically. You never need to paste it into chat.

Find your key: **[KIE Dashboard → API Key](https://kie.ai/api-key)**

## Reference images must be hosted

KIE accepts reference images as **publicly reachable URLs** (`imageUrls` for Veo, `input.image_input` for marketplace models). There is **no presigned-upload flow**. Plan your hosting strategy up front and record it in `MASTER_CONTEXT.md` under *Image hosting*:

- Your own R2 / S3 / Cloudinary bucket
- A temp host like `0x0.st` or imgur
- Anything that returns a public URL the KIE backend can fetch

The agent will **stop and ask** how to host a file if you pass a local path and no hosting is configured.

## Project memory

`MASTER_CONTEXT.md` is your workspace's living memory. The agent reads it at the start of every session and writes learnings back. It stores:

- **Image hosting** — how you convert `references/` files to public URLs
- **Credit costs** — you fill in once (or the agent asks), then every session has them
- **Confirmed model strings** — the exact `model` values the KIE marketplace exposes to your account
- **Brand voice** — optional tone, audience, and word preferences
- **API learnings** — universal KIE quirks that help the agent work better
- **Changelog** — dated notes from each session

## Supported models

| Model | Type | `model` string | Best for |
|-------|------|----------------|----------|
| **Veo 3.1** | Video | `veo3_fast` / `veo3` / `veo3_lite` | 8s dialogue videos, reference-to-video, first+last frame. Best for UGC stills → video. |
| **Sora 2** | Video | `sora-2-text-to-video` / `sora-2-pro-text-to-video` / `sora-2-image-to-video` | Longer videos (up to 20s), text-to-video, image-to-video. |
| **Kling 3.0** | Video | per marketplace | B-roll, cinematic clips |
| **Nano Banana 2** (default) | Image | `nano-banana-2` | UGC stills, character sheets, product shots, influencer recreation |
| **Nano Banana Pro** | Image | `nano-banana-pro` | Premium image quality (Gemini 3 Pro) |
| **Nano Banana Edit** | Image | `nano-banana-edit` | Inpaint / edit existing image |
| **Seedance 2** | Video | per marketplace | (verify on [kie.ai/market](https://kie.ai/market)) |

Always verify exact `model` strings on the marketplace page for your account — KIE adds and renames models as vendors update.

## Reference images

Drop images into the `references/` folder and the agent will use them automatically (once you've set up hosting):

- **`references/influencers/`** — Photos of people to recreate as AI-generated content
- **`references/products/`** — Product photos for showcase videos and hero images
- **`references/aesthetics/`** — Style references organized by vibe (`ugc-selfie/`, `cinematic/`, etc.)

Images stay local — the folder contents are gitignored.

## Editing the skills

The canonical skill sources live in `skills/`. After editing any file there, run:

```bash
./scripts/sync-skill.sh
```

This copies your changes to `.claude/skills/` and `.cursor/skills/` (which are gitignored — they're generated copies).

## Security

- `.env` is gitignored — never committed
- `MASTER_CONTEXT.md` is gitignored — contains your cost tables and hosting paths
- `logs/kie-api.jsonl` IS committed (historical cost data is valuable), but never logs keys, headers, or full prompt text — see `logs/README.md`
- Never paste API keys in GitHub issues or public chats

## Vendor prompting guides

| Model | Guide |
|-------|--------|
| Veo 3.1 | [Google Cloud — Veo 3.1](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-veo-3-1) |
| Sora 2 | [OpenAI — Sora 2 prompting guide](https://developers.openai.com/cookbook/examples/sora/sora2_prompting_guide) |
| Kling 3.0 | [Kling — user guide](https://kling.ai/quickstart/klingai-video-3-model-user-guide) |
| Nano Banana | [Google Cloud — Nano Banana](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-nano-banana) |

## API docs

- **KIE docs:** [docs.kie.ai](https://docs.kie.ai)
- **Model marketplace:** [kie.ai/market](https://kie.ai/market)
- **Pricing:** [kie.ai/pricing](https://kie.ai/pricing)
- **Task logs UI:** [kie.ai/logs](https://kie.ai/logs)

## Other AI assistants (Manus, Copilot, etc.)

Point your assistant at [AGENTS.md](AGENTS.md) and `MASTER_CONTEXT.md` + the skill paths. See [AGENTS.md](AGENTS.md) for details.
