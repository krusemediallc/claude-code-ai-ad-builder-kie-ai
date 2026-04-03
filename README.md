# KIE AI Video & Image — Agent Skill Pack

Create AI marketing videos and images using your [KIE AI](https://kie.ai) account, powered by AI agents in **Claude Code** or **Cursor**. Supports Veo 3.1, Sora 2, Kling 3.0, Runway, Nano Banana, and more.

## Get started (5 minutes)

### 1. Clone this repo

```bash
git clone <repo-url>
cd kie-ai-agent-skills
```

### 2. Run setup

```bash
./scripts/setup.sh
```

This will:
- Ask for your **KIE API key** (find it at [kie.ai/api-key](https://kie.ai/api-key))
- Save it securely in `.env` (never committed to git)
- Verify your connection to KIE AI
- Create your personal `MASTER_CONTEXT.md` workspace file

### 3. Open in your AI editor

**Claude Code:** Open the folder. The agent loads the KIE AI skill automatically.

**Cursor:** Open the folder. The skill is at `.cursor/skills/kie-ai-api/`.

### 4. Start creating

The agent handles API calls, polling, prompt engineering, and file organization. Here are the main workflows:

#### Create an AI influencer (character sheet)

> "Create a new AI influencer — a 22-year-old college student with freckles"

Generates a full-body hero image for your approval, then 9 additional angles using the hero as reference. All 10 saved to `references/influencers/`.

#### Generate UGC product selfie stills

> "Generate a UGC selfie of Sofia holding the Cola can in her bedroom"

Combines character + product photo + style references into an authentic-looking iPhone selfie.

#### Animate a still into video

> "Turn that image into a video — have her talk about the product"

Uses Veo 3.1 to animate your approved still with natural motion and dialogue.

#### Quick UGC video (no starting frame)

> "Generate a UGC video ad for this product" + drop a product photo

Uses Sora 2 or Veo 3.1 to generate a video directly from text and product reference.

#### Other things to try

- "Recreate this influencer's look from a reference photo"
- "Make a Nano Banana product hero image"
- "Generate 5 different ad variations for this product"
- "Make a 10-second Kling 3.0 product b-roll"
- "Create a Runway animation from this image"

## What's in the box

| Path | What it does |
|------|-------------|
| `skills/kie-ai-api/` | The skill: API reference, prompting guide, per-model prompt library |
| `MASTER_CONTEXT.template.md` | Template for workspace context (credit costs, brand voice, learnings) |
| `MASTER_CONTEXT.md` | Your personalized copy (created by setup, not committed) |
| `.env` | Your API key (created by setup, never committed) |
| `scripts/setup.sh` | One-time setup |
| `scripts/sync-skill.sh` | Copies skill edits to `.claude/` and `.cursor/` |
| `scripts/check-kie-env.sh` | Tests API connectivity |
| `references/` | Drop reference images here (influencers, products, aesthetics) |

## Your API key

Your key authenticates with the KIE AI API. During setup you paste it once and the agent uses it from `.env` automatically.

Find your key: **[kie.ai/api-key](https://kie.ai/api-key)**

## Project memory

`MASTER_CONTEXT.md` is your workspace's living memory. The agent reads it every session and writes learnings back:

- **Credit costs** — filled in once, then available every session
- **Brand voice** — optional tone, audience, and word preferences
- **API learnings** — universal KIE quirks that help the agent work better
- **Changelog** — dated notes from each session

## Supported models

| Model | Type | Best for | Via |
|-------|------|----------|-----|
| **Veo 3.1** | Video | Animating a starting frame into ~8s video with dialogue | Dedicated route |
| **Sora 2 / Pro** | Video | Text-to-video and image-to-video | Generic jobs |
| **Kling 3.0** | Video | 3-15s video with multi-shot, elements, and sound | Generic jobs |
| **Runway** | Video | Silent 5-10s video, image animation | Dedicated route |
| **Seedance 2.0** | Video | Multimodal (text+image+video+audio), native lip-sync, first/last frame | Generic jobs |
| **Nano Banana 2** | Image | UGC stills, character sheets, product shots (up to 14 refs) | Generic jobs |
| **Nano Banana Pro** | Image | High-quality stills (no ref image support) | Generic jobs |
| **Flux Kontext** | Image | Image generation and editing | Dedicated route |

Full model list: [kie.ai/market](https://kie.ai/market)

## Reference images

Drop images into `references/` and the agent uses them automatically:

- **`references/influencers/`** — AI character sheets and face references
- **`references/products/`** — Product photos for showcase workflows
- **`references/aesthetics/`** — Style references by vibe (`ugc-selfie/`, `cinematic/`, etc.)

## Editing the skill

The canonical skill source lives in `skills/kie-ai-api/`. After editing:

```bash
./scripts/sync-skill.sh
```

## Security

- `.env` is gitignored — never committed
- `MASTER_CONTEXT.md` is gitignored — contains workspace data
- Never paste API keys in public chats

## Vendor prompting guides

| Model | Guide |
|-------|--------|
| Veo 3.1 | [Google Cloud — Veo 3.1](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-veo-3-1) |
| Sora 2 | [OpenAI — Sora 2](https://developers.openai.com/cookbook/examples/sora/sora2_prompting_guide) |
| Kling 3.0 | [Kling — user guide](https://kling.ai/quickstart/klingai-video-3-model-user-guide) |
| Nano Banana | [Google Cloud — Nano Banana](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-nano-banana) |

## API docs

[KIE AI Documentation](https://docs.kie.ai)

## Other AI assistants (Manus, Copilot, etc.)

See [AGENTS.md](AGENTS.md).
