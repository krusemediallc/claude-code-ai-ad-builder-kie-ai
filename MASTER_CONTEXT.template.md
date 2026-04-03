# Master context (KIE AI + agents)

**Purpose:** One place for humans and AI agents to capture **decisions**, **brand voice**, **API quirks**, and **what we learned** while using this repo with KIE AI.

## How agents should use this file

- **At the start of substantive work:** Read this file for project-specific context.
- **After meaningful changes:** Append a new **dated entry** under [Changelog](#changelog).
- **If fields are empty:** Offer to populate them (credit costs from pricing page, balance from API).

## Project snapshot

- **KIE API base:** `https://api.kie.ai` (see `.env.example`).
- **KIE upload base:** `https://kieai.redpandaai.co`.
- **Skill:** `.claude/skills/kie-ai-api/` and `.cursor/skills/kie-ai-api/` (sync from `skills/kie-ai-api/` via `scripts/sync-skill.sh`).

## My workspace

- **Current credit balance:** _(check via `GET /api/v1/chat/credit`)_

## Credit costs

_Fill in your plan's credit costs below. The agent references this table before every generation. If left blank, the agent will ask you once and can fill them in. Check https://kie.ai/pricing for current rates._

| Model | Credits per generation | Approx USD | Notes |
|-------|----------------------|------------|-------|
| Veo 3.1 (quality, `veo3`) | _(fill in)_ | | |
| Veo 3.1 (fast, `veo3_fast`) | _(fill in)_ | | |
| Veo 3.1 (lite, `veo3_lite`) | _(fill in)_ | | |
| Runway (720p 5s) | _(fill in)_ | | |
| Runway (720p 10s) | _(fill in)_ | | |
| Runway (1080p 5s) | _(fill in)_ | | |
| Sora 2 | _(fill in)_ | | |
| Sora 2 Pro | _(fill in)_ | | |
| Kling 3.0 (std) | _(fill in)_ | | |
| Kling 3.0 (pro) | _(fill in)_ | | |
| Seedance 2.0 720p no-video (`bytedance/seedance-2`) | 41 cr/s | $0.205/s | 8s default = ~328 credits |
| Seedance 2.0 720p with-video | 25 cr/s | $0.125/s | 8s = ~200 credits |
| Seedance 2.0 480p no-video | 19 cr/s | $0.095/s | 8s = ~152 credits |
| Seedance 2.0 480p with-video | 11.5 cr/s | $0.0575/s | 8s = ~92 credits |
| Nano Banana 2 (`nano-banana-2`) | _(fill in)_ | | |
| Nano Banana Pro (`google/nano-banana`) | _(fill in)_ | | |

## Brand (optional)

_Edit or replace with your real brand blocks (see `skills/kie-ai-api/prompting/brand-voice-starter.md`)._

- **Tone:**
- **Audience:**
- **Words to use / avoid:**

## Reference images

Drop reference images into the `references/` folder at the repo root:
- `references/influencers/` — face/body photos to recreate as AI people
- `references/products/` — product photos for showcase workflows
- `references/aesthetics/` — mood boards, lighting references, style inspiration

The agent checks this folder when composing prompts and automatically uploads images via KIE file upload for use as references.

## API learnings (universal)

These are confirmed behaviors of the KIE AI API. They apply to all accounts.

### Auth

- Bearer token: `Authorization: Bearer $KIE_API_KEY`.
- Get key from https://kie.ai/api-key.

### Endpoint architecture

- **Dedicated routes:** Veo 3.1 (`/api/v1/veo/...`), Runway (`/api/v1/runway/...`).
- **Generic jobs route:** `POST /api/v1/jobs/createTask` for Sora 2, Kling, Nano Banana, and most market models.
- Polling differs by endpoint type — see reference.md.

### Nano Banana image generation

- NB2: `model: "nano-banana-2"`, supports `input.image_input` (up to 14 ref images), `input.aspect_ratio`.
- NB Pro: `model: "google/nano-banana"`, uses `input.image_size` (not `aspect_ratio`), no reference image support.
- NB Pro uses `jpeg` format string; NB2 uses `jpg`.

### Veo 3.1

- `imageUrls` array: 1 image = start frame behavior, 2 images = first-to-last transition.
- No `duration` field — auto-determines (~8s typical).
- Models: `veo3` (quality), `veo3_fast` (default), `veo3_lite`.
- **ALWAYS include** `"No subtitles, no captions, no text overlays."` in prompts.
- **Human motion cues mandatory** — without them, subjects look frozen.

### Sora 2

- `input.image_urls` for image-to-video — style/mood reference behavior, not exact start frame.
- Best for: text-only video or when you don't need exact frame-one fidelity.
- `n_frames`: `10` (~5s) or `15` (~8s).
- `upload_method`: always `"s3"`.

### Kling 3.0

- Duration: 3-15 seconds (flexible).
- Multi-shot mode: storyboard multiple shots with individual prompts.
- Elements: attach up to 3 character/object references.
- Sound effects: `sound: true`.
- Modes: `std` (720p) or `pro` (1080p).

### Runway

- Silent video only — no speech generation.
- Duration: 5 or 10 seconds (10s limited to 720p).
- Quality: 720p or 1080p (1080p limited to 5s).

### Seedance 2.0

- `model: "bytedance/seedance-2"` via generic jobs endpoint.
- **Multimodal:** supports text + images (up to 7) + videos (up to 3) + audio (up to 3) in one call.
- **First/last frame:** `first_frame_url` and `last_frame_url` for precise start/end transitions.
- **Native audio:** `generate_audio: true` (default) — built-in speech, lip-sync, sound effects. Set `false` for silent + cheaper.
- Duration: 4, 8, 12 seconds. Resolution: 480p, 720p.
- `web_search` field is required (set `true` or `false`).
- Credits are **per second** and vary by resolution and whether video input is used.
- Generation time: ~3-5 minutes typical (tested: ~220s for text-only 8s 720p).
- **Person images require Asset Library:** (1) `POST /api/v1/playground/createAsset` → get asset ID, (2) verify with `GET /api/v1/playground/getAsset?assetId=`, (3) use `asset://<asset_id>` format in `first_frame_url` or `reference_image_urls`. Regular URLs and bare asset IDs fail. The `asset://` prefix is required.
- Text-to-video works without Asset Library step.

### File upload

- Upload base: `https://kieai.redpandaai.co`.
- Three methods: URL upload, base64 upload, stream upload.
- Files auto-delete after **3 days**. Re-upload if needed.
- Use returned `downloadUrl` as image reference in generation calls.

### Polling

- Dedicated routes (Veo, Runway): model-specific polling endpoints.
- Generic jobs: `GET /api/v1/jobs/recordInfo?taskId=`.
- States: `waiting` → `queuing` → `generating` → `success` | `fail`.
- `resultJson` is a JSON string — parse it for output URLs.

### Rate limits

- 20 requests per 10 seconds per account.
- 100+ concurrent running tasks.
- Exceeded → HTTP 429.

### Data retention

- Generated media: 14 days.
- Uploaded files: 3 days.
- Download URLs from `/common/download-url`: 20 minutes.

### UGC prompting

- **Imperfection block (camera):** Every UGC prompt must include camera imperfections.
- **Skin realism block (mandatory):** Include 3-4 subtle skin cues inline with character description.
- **Reference image order:** character hero first, then product, then style refs.

### Image QA

- Agents must visually review still images after generation.
- If defective, regenerate with refined prompt — up to 2 retries (3 total).

## Changelog

### YYYY-MM-DD -- Template entry

- **Decision:**
- **Change:**
- **Why:**
