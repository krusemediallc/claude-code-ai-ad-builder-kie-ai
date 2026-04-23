## Project snapshot — KIE.ai

- **API base:** `https://api.kie.ai` (see `.env.example`).
- **Auth:** Bearer token (`KIE_API_KEY`).
- **Skills:**
  - `.claude/skills/kie-external-api/` and `.cursor/skills/kie-external-api/` (sync from `skills/kie-external-api/` via `scripts/sync-skill.sh`).
  - `.claude/skills/generate-youtube-thumbnail/` (and Cursor equivalent) for YouTube thumbnails.
- **Dashboard:** [kie.ai/logs](https://kie.ai/logs) · [kie.ai/api-key](https://kie.ai/api-key) · [kie.ai/pricing](https://kie.ai/pricing) · [kie.ai/market](https://kie.ai/market)

## Image hosting (required)

KIE does **not** provide a presigned-upload flow. Reference images must be at **publicly reachable URLs**. Record your hosting strategy here:

- **Host:** _(e.g. Cloudflare R2 public bucket, S3, Cloudinary, 0x0.st, imgur)_
- **Upload flow:** _(brief — how you get from a local file in `references/` to a hosted URL)_
- **URL lifetime:** _(permanent? 24h? note any expiry)_

Agents should **stop and ask** for a hosted URL before firing any generation that needs references if this section is empty.

## Credit costs

_Fill in your account's credit costs below. The agent references this table before every generation. If left blank, the agent will ask you once and can fill them in. Check [kie.ai/pricing](https://kie.ai/pricing) and [kie.ai/logs](https://kie.ai/logs) for current values._

| Model | `model` string | Credits per generation | Notes |
|-------|---------------|------------------------|-------|
| Veo 3 | `veo3` | _(fill in)_ | Highest quality |
| Veo 3 Fast (default) | `veo3_fast` | _(fill in)_ | Required for `REFERENCE_2_VIDEO` mode |
| Veo 3 Lite | `veo3_lite` | _(fill in)_ | Most economical |
| Sora 2 text-to-video | `sora-2-text-to-video` | _(fill in)_ | |
| Sora 2 Pro text-to-video | `sora-2-pro-text-to-video` | _(fill in)_ | |
| Sora 2 image-to-video | `sora-2-image-to-video` | _(fill in)_ | |
| Nano Banana 2 (default image) | `nano-banana-2` | _(fill in)_ | ~30–60s generation |
| Nano Banana Pro | `nano-banana-pro` | _(fill in)_ | Gemini 3 Pro image |
| Nano Banana (legacy) | `nano-banana` | _(fill in)_ | |
| Nano Banana Edit | `nano-banana-edit` | _(fill in)_ | |
| Kling 3.0 | _(verify on marketplace)_ | _(fill in)_ | |
| Seedance 2 | _(verify on marketplace)_ | _(fill in)_ | |

## Confirmed model strings

Record exact KIE `model` strings that you've verified work in your account. Marketplace pages sometimes rename or version-gate models:

- _(dated entry per model once verified)_

## API learnings — KIE.ai

Confirmed behaviors of the KIE.ai API. Add new learnings here as you discover them.

### Auth

- Bearer token on every request: `Authorization: Bearer $KIE_API_KEY`.
- Simplest auth check: `GET /api/v1/chat/credit` (returns credit balance).

### Endpoint families

- **Veo (first-party path):** `POST /api/v1/veo/generate` → `GET /api/v1/veo/record-info?taskId=...`. Signals via `successFlag` (0 generating, 1 success, 2/3 failed). Videos in `data.info.resultUrls` (JSON-encoded string).
- **Jobs (unified marketplace):** `POST /api/v1/jobs/createTask` with `{model, input: {...}}` → `GET /api/v1/jobs/recordInfo?taskId=...` (some models use `/api/v1/playground/recordInfo` — verify per model page). Signals via `state` (`waiting`/`queuing`/`generating`/`success`/`fail`). Results in `data.resultJson` (JSON-encoded string).

### Reference images

- **URL-based only.** Pass into `imageUrls` (Veo, up to 2) or `input.image_input` (jobs, up to 14).
- No presigned-upload flow. Plan your hosting strategy up front.
- Minimum longest-side **1024 px** is a good default; auto-upscale with Lanczos to 1080 px if smaller, then re-host.

### Veo 3.1

- `generationType` picks the input mode: `TEXT_2_VIDEO` · `REFERENCE_2_VIDEO` (1 URL, only with `veo3_fast`) · `FIRST_AND_LAST_FRAMES_2_VIDEO` (2 URLs).
- Default aspect ratio is `16:9`. Use `9:16` for vertical content.
- Default resolution `720p` — `1080p` and `4k` available, larger files.
- `enableTranslation: true` auto-translates prompts to English (default on).

### Sora 2

- Text-to-video, image-to-video, and Pro variants are separate `model` strings on `POST /api/v1/jobs/createTask`.
- Typical `duration` enum: `[4, 8, 12, 16, 20]` seconds. Verify on the model's marketplace page.
- Embed dialogue in the `prompt` field as `Dialogue: "..."`.

### Nano Banana

- Default: `nano-banana-2`. Pro: `nano-banana-pro` (actually Gemini 3 Pro image — not just a rename like some aggregators).
- `input.image_input` accepts up to 14 URLs.
- `input.aspect_ratio` has many options incl. `auto` (default); `input.resolution` is `1K`/`2K`/`4K`; `input.output_format` is `jpg`/`png`.
- Max prompt length: **20,000 chars**. Prompts can be long.

### Polling

- Default poll interval: **30 seconds**.
- Timing: Nano Banana images ~30–60s · Sora 2 videos ~2–5 min · Veo 3.1 videos ~2–5 min.
- For production, prefer `callBackUrl` webhook over polling.
- Veo `data.info.resultUrls` and jobs `data.resultJson` are **JSON-encoded strings** — parse before reading.

### Rate limits

- **20 new requests per 10 seconds** per account.
- **100+ concurrent running tasks** supported.
- HTTP 429 on violation — back off with jitter.

### Temp URLs

- Output videos/images are hosted on KIE temp URLs that may expire.
- Refresh an expired link with `POST /api/v1/common/download-url`.
- Best practice: download results to `outputs/{YYYY-MM-DD}-{slug}/` locally for durability.
