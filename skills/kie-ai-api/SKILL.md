---
name: kie-ai-api
description: >-
  Creates and retrieves AI video and image assets via the KIE AI API (Veo 3.1, Sora 2, Kling 3.0, Runway, Nano Banana, Flux Kontext). Loads prompts from the bundled prompting guide and model library, respects Bearer auth from KIE_API_KEY, and polls tasks until ready. Use when the user mentions KIE, kie.ai, Sora2, Veo, Kling, Nano Banana, Runway, Flux, or generating marketing creative through KIE.
---

# KIE AI API

## Configuration

- **Base URL:** `https://api.kie.ai` (or `KIE_BASE_URL`).
- **Upload URL:** `https://kieai.redpandaai.co` (or `KIE_UPLOAD_URL`).
- **Auth:** Bearer token — `Authorization: Bearer $KIE_API_KEY`. Example curl: `curl -H "Authorization: Bearer $KIE_API_KEY" "https://api.kie.ai/api/v1/chat/credit"`.
- **Never** print API keys, commit `.env`, or paste keys into `MASTER_CONTEXT.md`.

### If the key is missing or the API returns 401

1. **Editor-first (default):** Ensure `.env` exists (copy from `.env.example` in the repo root). Ask the user to paste `KIE_API_KEY` **only inside** `.env` and save. Do not ask them to paste the key in chat unless they insist.
2. **Chat-assisted:** If they paste the key in chat, write `.env` for them, confirm "saved to `.env`" **without repeating the key**, and remind them that chat history may retain secrets—rotate the key in KIE if the chat could be shared.

Before the first call, confirm `.gitignore` excludes `.env`.

## Read order

1. Repo root **`MASTER_CONTEXT.md`** when present (brand voice, decisions, quirks).
2. This skill's **[reference.md](reference.md)** for routes, bodies, polling.
3. **[prompting/guide.md](prompting/guide.md)** then the right **`prompting/prompt-library/`** file for the model (see table below).

## Decision tree: which flow?

| User goal | Model / endpoint | Prompt library |
|-----------|-----------------|----------------|
| **Veo 3.1** video (text or image→video) | `POST /api/v1/veo/generate` | [veo-3-1.md](prompting/prompt-library/veo-3-1.md) |
| **Veo 3.1** extend | `POST /api/v1/veo/extend` | [veo-3-1.md](prompting/prompt-library/veo-3-1.md) |
| **Runway** video | `POST /api/v1/runway/generate` | [runway.md](prompting/prompt-library/runway.md) |
| **Sora 2** video from text | `POST /api/v1/jobs/createTask` with `model: "sora-2-text-to-video"` | [sora-2.md](prompting/prompt-library/sora-2.md) |
| **Sora 2** video from image | `POST /api/v1/jobs/createTask` with `model: "sora-2-image-to-video"` | [sora-2.md](prompting/prompt-library/sora-2.md) |
| **Kling 3.0** video | `POST /api/v1/jobs/createTask` with `model: "kling-3.0/video"` | [kling-3.md](prompting/prompt-library/kling-3.md) |
| **Kling 3.0 motion control** — transfer motion from video onto character | `POST /api/v1/jobs/createTask` with `model: "kling-3.0/motion-control"` | [kling-3.md](prompting/prompt-library/kling-3.md) |
| **Seedance 2.0** video (multimodal: text + images + video + audio) | `POST /api/v1/jobs/createTask` with `model: "bytedance/seedance-2"` | [seedance-2.md](prompting/prompt-library/seedance-2.md) |
| **Wan 2.7** still image (text-to-image or image-to-image) | `POST /api/v1/jobs/createTask` with `model: "wan/2-7-image"` or `"wan/2-7-image-pro"` | [wan-2-7.md](prompting/prompt-library/wan-2-7.md) |
| **Nano Banana 2** still image | `POST /api/v1/jobs/createTask` with `model: "nano-banana-2"` | [nano-banana.md](prompting/prompt-library/nano-banana.md) |
| **Nano Banana Pro** still image | `POST /api/v1/jobs/createTask` with `model: "google/nano-banana"` | [nano-banana.md](prompting/prompt-library/nano-banana.md) |
| **Recreate an influencer** from a reference photo | **Two-step:** (1) generate still via Nano Banana with `image_input` references, get approval; (2) upload approved still → Veo 3.1 `imageUrls` for video. | [influencer-recreation.md](prompting/prompt-library/influencer-recreation.md) |
| **Product showcase** — AI person holds/uses a product | **Two-step:** (1) generate still via Nano Banana with product as `image_input` reference; (2) approve still; (3) still → Veo 3.1 / Sora 2 / Kling 3.0 for video. | [product-showcase.md](prompting/prompt-library/product-showcase.md) |
| **UGC / selfie-style** (authentic reels) | Any video model | [ugc-selfie-style.md](prompting/prompt-library/ugc-selfie-style.md) |
| **Create a new AI influencer** from text (character sheet) | **Two-pass:** (1) generate hero front portrait via Nano Banana, get approval; (2) generate 9 remaining angles with hero as `image_input` reference. Save all 10 to `references/influencers/`. | [character-sheet.md](prompting/prompt-library/character-sheet.md) |
| **UGC product selfie** — AI influencer holding a product in a selfie-style image | Combine character hero + product photo + style references as `image_input`. Prompt must include imperfection block. | [ugc-product-selfie.md](prompting/prompt-library/ugc-product-selfie.md) |

Prefer the **shortest** path: if the user only needs Veo 3.1 or Sora 2, do not overcomplicate the workflow.

## Creative layer

- **MANDATORY:** Before composing any prompt for the API, **read the relevant `prompting/prompt-library/*.md` file** for the chosen model/workflow. Do NOT skip this step — every prompt must align with the vendor guide's formula and best practices.
- Build **one** clear prompt paragraph; avoid keyword soup.
- Merge slot values from the user and from **`MASTER_CONTEXT.md`** when it conflicts with defaults.

## Credit cost estimation (MANDATORY — show before generating)

Before firing **any** generation calls, check the user's credit balance and present the estimated cost.

### Check balance first

```bash
curl -sS -H "Authorization: Bearer $KIE_API_KEY" "https://api.kie.ai/api/v1/chat/credit"
```

Returns `{"code":200,"data":100}` where `data` is the integer credit balance.

### Credit cost table

Check `MASTER_CONTEXT.md` → **Credit costs** table. If the table is empty, ask the user for their per-model credit pricing and **write the values into `MASTER_CONTEXT.md`** so future sessions have them. You can also check `https://kie.ai/pricing` for current rates.

### How to calculate

```
total_credits = sum(credits_per_model × variations_requested) for each model
```

### Example output to user

```
Credit cost breakdown:
  Veo 3.1 (quality) × 2 = X credits
  Sora 2             × 2 = X credits
  Nano Banana 2      × 3 = X credits
  ─────────────────────────────────
  Total: X credits
  Current balance: Y credits

Proceed? (yes/no)
```

Always wait for confirmation before firing. **Exception — QA-fix retries (still images only):** automatic regeneration to fix visible defects does **not** require asking again.

## Generation count: multiple variations per prompt

Before firing any generation call, **ask the user how many variations** they want. Default is 1 if they don't specify.

When count > 1, send **N separate API calls** with identical payload. Fire them in parallel where possible, then poll all task IDs concurrently.

Present results as a numbered list so the user can compare and pick favorites.

## Nano Banana image: model choice

| User-facing name | API `model` value | When to use |
|------------------|-------------------|-------------|
| **Nano Banana 2** (default) | `nano-banana-2` | Default for all image generation |
| **Nano Banana Pro** | `google/nano-banana` | When user explicitly asks for Pro |

Before the first Nano Banana image call, ask: *"Use default Nano Banana 2, or Nano Banana Pro?"* If no preference, use `nano-banana-2`.

**Key difference:** NB2 uses `input.aspect_ratio` and `input.image_input` (up to 14 refs). Pro uses `input.image_size` and has no reference image support.

## Script and dialogue

For any video featuring a person speaking, **ask the user for the script**.

- **Veo 3.1** and **Sora 2**: embed dialogue in the `prompt` field using `She speaks: "..."` pattern.
- **Kling 3.0**: can enable `sound: true` for sound effects, but dialogue control is in the prompt.
- **Runway**: no speech — Runway is silent video only.
- **Nano Banana images**: no speech — still images. Speech is handled in the subsequent video step.

## Script length → video duration (auto-select)

Average speaking pace: **~2.5 words per second**. Round **up** to give breathing room.

### Sora 2 — `n_frames`: `10` (~5s) or `15` (~8s)

| Script length | n_frames |
|---------------|----------|
| 1–12 words | 10 |
| 13–20 words | 15 |
| **21+ words** | **Too long** — offer to split or switch to Kling 3.0 (up to 15s) |

### Veo 3.1 — no duration field

Auto-determines length (~8s typical). If script exceeds ~20 words, warn that Veo may truncate dialogue.

### Kling 3.0 — `duration`: 3-15 seconds

| Script length | Duration |
|---------------|----------|
| 1–7 words | 3s |
| 8–12 words | 5s |
| 13–25 words | 10s |
| 26–37 words | 15s |
| **38+ words** | **Too long** — offer to split |

### Seedance 2.0 — `duration`: 4, 8, or 12 seconds

Has native audio with lip-sync (`generate_audio: true` by default).

| Script length | Duration |
|---------------|----------|
| 1–8 words | 4s |
| 9–18 words | 8s |
| 19–28 words | 12s |
| **29+ words** | **Too long** — offer to split |

### Runway — `duration`: 5 or 10 seconds

Runway is silent video. No speech duration mapping needed.

## Splitting long scripts into multiple videos

If the script exceeds the max duration:

1. **Tell the user** and show the word/duration math.
2. **Offer:** Split into segments at natural sentence boundaries, or switch to a model with longer duration.
3. If splitting, generate each segment separately (N variations per segment if requested).
4. **Offer to stitch** using `ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4`.

## Veo 3.1: image-to-video modes

Veo 3.1 accepts `imageUrls` (array of 1-2 publicly accessible image URLs):

| Images | Behavior |
|--------|----------|
| **1 image** | Video unfolds around that image (like a "start frame") |
| **2 images** | Creates a transition from first image to last image |
| **0 images** | Text-to-video only |

Set `generationType` accordingly: `TEXT_2_VIDEO`, `FIRST_AND_LAST_FRAMES_2_VIDEO`, or `REFERENCE_2_VIDEO`.

**Default rule:** When the user provides a single reference photo of a person, **always use 1 image in `imageUrls`** to get the start-frame behavior.

## Image handling: upload references

Before using any reference image in a generation call:

1. **Upload the image** via KIE file upload (`POST https://kieai.redpandaai.co/api/file-url-upload` or `/api/file-base64-upload`).
2. Use the returned `downloadUrl` as the image URL in the generation call.
3. For local files, use base64 upload. For URLs, use URL upload.

KIE uploaded files expire after **3 days** — re-upload if needed.

## Generated image QA (mandatory)

Applies to **still images** from Nano Banana. After each task reaches `state: success`:

**Look for:** extra/missing hands or fingers; wrong limb count; distorted faces; melted objects; artifacts.

**If something looks wrong:** Regenerate with a **revised prompt** that explicitly corrects the issue. Do **not** resend identical payload.

**Retry cap:** Up to **2** regeneration attempts after the first (3 total). After that, show the best attempt and ask the user.

## Execution checklist (agent)

1. **Check credits:** `GET /api/v1/chat/credit` — verify sufficient balance.
2. **Ask for script/dialogue:** If video with speaking, ask for exact words. Count words for auto-duration. Skip for image-only requests.
3. **Nano Banana model:** Confirm NB2 (default) vs Pro for image calls.
4. **Ask for generation count:** Default 1.
5. **Show credit cost and get confirmation.**
6. **Check `references/` folder:** Look for relevant images in `references/influencers/`, `references/products/`, `references/aesthetics/`. Upload references via KIE file upload to get URLs. For Veo 3.1, determine whether to use 1 or 2 `imageUrls`.
7. **Compose JSON** per [reference.md](reference.md). Include correct `model` field.
8. **POST** the correct endpoint **N times** (once per variation). Fire in parallel where possible.
9. **Poll** the correct polling endpoint until `success` or `fail`. Poll all tasks concurrently.
10. **Generated image QA:** For still images, inspect and regenerate if defective (up to 2 retries).
11. **Present results:** Return video/image URLs. If multiple variations, present as numbered list. For Nano Banana stills used as start frames, **wait for user approval** before video generation.
12. **Stitch if split:** If script was split, offer `ffmpeg` stitching.

## Errors (user-facing)

- **401:** Invalid API key — fix in `.env`.
- **402:** Insufficient credits — tell user to top up at https://kie.ai/pricing.
- **404:** Task not found — wrong task ID.
- **422:** Validation error — check required fields and enums.
- **429:** Rate limited — wait and retry (20 req / 10s limit).
- **500/501:** Server/generation error — retry later.

## Supporting files

- [reference.md](reference.md) — endpoints, auth, polling, model mapping.
- [prompting/guide.md](prompting/guide.md) — marketing brief → API.
- [prompting/prompt-library/influencer-recreation.md](prompting/prompt-library/influencer-recreation.md) — recreate influencer from reference photo.
- [prompting/prompt-library/ugc-selfie-style.md](prompting/prompt-library/ugc-selfie-style.md) — cross-model UGC guide.
- [prompting/prompt-library/product-showcase.md](prompting/prompt-library/product-showcase.md) — product-in-hand video workflow.
- [prompting/prompt-library/nano-banana.md](prompting/prompt-library/nano-banana.md) — Nano Banana image prompting.
- [prompting/prompt-library/character-sheet.md](prompting/prompt-library/character-sheet.md) — 10-image character sheet.
- [prompting/prompt-library/ugc-product-selfie.md](prompting/prompt-library/ugc-product-selfie.md) — UGC selfie-style still image.
- [prompting/prompt-library/seedance-2.md](prompting/prompt-library/seedance-2.md) — Seedance 2.0 multimodal video prompting.
- [prompting/brand-voice-starter.md](prompting/brand-voice-starter.md) — template for `MASTER_CONTEXT.md`.
