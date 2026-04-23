---
name: kie-external-api
description: >-
  Creates and retrieves AI video and image assets via the KIE.ai API (Veo 3.1, Sora 2, Nano Banana 2, Kling, Seedance, and other models in the KIE marketplace). Loads prompts from the bundled prompting guide and model library, respects Bearer auth from KIE_API_KEY, and polls tasks until ready. Use when the user mentions KIE, kie.ai, api.kie.ai, Veo, Sora2, Kling, Nano Banana, Seedance, or generating marketing creative through KIE.
---

# KIE.ai external API

## Configuration

- **Base URL:** `https://api.kie.ai` (or `KIE_BASE_URL`).
- **Auth:** Bearer token. Set `KIE_API_KEY` in `.env`. Every request sends `Authorization: Bearer $KIE_API_KEY`.
- **Never** print API keys, commit `.env`, or paste keys into `MASTER_CONTEXT.md`.

### If the key is missing or the API returns 401/403

1. **Editor-first (default):** Ensure `.env` exists (copy from `.env.example` in the repo root). Ask the user to paste `KIE_API_KEY` **only inside** `.env` and save. Do not ask them to paste the key in chat unless they insist.
2. **Chat-assisted:** If they paste the key in chat, write `.env` for them, confirm "saved to `.env`" **without repeating the key**, and remind them that chat history may retain secrets — rotate the key in KIE if the chat could be shared.

Before the first call, confirm `.gitignore` excludes `.env`.

Find and manage keys: **[KIE Dashboard → API Key](https://kie.ai/api-key)**. Task logs: **[kie.ai/logs](https://kie.ai/logs)**.

## Read order

1. Repo root **`MASTER_CONTEXT.md`** when present (brand voice, decisions, quirks).
2. This skill's **[reference.md](reference.md)** for routes, bodies, polling.
3. **[prompting/guide.md](prompting/guide.md)** then the right **`prompting/prompt-library/`** file for the model (see table below).

## Decision tree: which flow?

| User goal | Endpoint | Prompt library |
|-----------|----------|----------------|
| **Veo 3.1** video (text-to-video OR with reference/start/end frames) | `POST /api/v1/veo/generate` | [prompt-library/veo-3-1.md](prompting/prompt-library/veo-3-1.md) |
| **Sora 2** video (text-to-video, longer durations, OR with image input) | `POST /api/v1/jobs/createTask` with Sora model string (e.g. `sora-2-text-to-video`, `sora-2-pro-text-to-video`, `sora-2-image-to-video`) | [prompt-library/sora-2.md](prompting/prompt-library/sora-2.md) |
| **Nano Banana 2 still image** (standalone OR as start frame for video) | `POST /api/v1/jobs/createTask` with `model: "nano-banana-2"` | [prompt-library/nano-banana.md](prompting/prompt-library/nano-banana.md) |
| **Nano Banana Pro** image | `POST /api/v1/jobs/createTask` with `model: "nano-banana-pro"` | [nano-banana.md](prompting/prompt-library/nano-banana.md) |
| **Kling 3.0** video (b-roll / scene / cinematic clips) | `POST /api/v1/jobs/createTask` with Kling model string (see [reference.md](reference.md) or [kie.ai/market](https://kie.ai/market)) | [prompt-library/kling-3.md](prompting/prompt-library/kling-3.md) |
| **Recreate an influencer** from a reference photo | **Two-step:** (1) Nano Banana 2 to generate a **still image** from the reference, get user approval; (2) pass approved still URL into Veo 3.1 `imageUrls` as the opening frame. **Never skip the approval step.** | [prompt-library/influencer-recreation.md](prompting/prompt-library/influencer-recreation.md) |
| **Product showcase** — AI person holds/uses a product and talks about it | **Two-step:** (1) Nano Banana 2 with product reference URL → starting frame of the AI person with the product; (2) user approves; (3) starting-frame URL → Veo 3.1 / Sora 2 for video. | [prompt-library/product-showcase.md](prompting/prompt-library/product-showcase.md) |
| **UGC / selfie-style** (authentic reels) | Any video route (Veo 3.1 or Sora 2) | [prompt-library/ugc-selfie-style.md](prompting/prompt-library/ugc-selfie-style.md) — cross-model UGC guide with iPhone-shot aesthetic, negative prompts, per-model formulas |
| **Create a new AI influencer** from a text description (character sheet) | **Two-pass:** (1) generate hero front portrait via Nano Banana 2, get user approval; (2) generate 9 remaining angles with hero URL in `image_input`. Save all 10 to `references/influencers/`. | [prompt-library/character-sheet.md](prompting/prompt-library/character-sheet.md) |
| **UGC product selfie** — AI influencer holding a product in a selfie-style image | Combine character hero URL + product photo URL + style reference URLs in `image_input`. Prompt must include imperfection block for authenticity. | [prompt-library/ugc-product-selfie.md](prompting/prompt-library/ugc-product-selfie.md) |

Prefer the **shortest** path: if the user only needs Veo 3.1 or Sora 2 text-to-video, skip any image pre-step.

## Reference images: hosted URLs, not file uploads

KIE.ai accepts reference images as **publicly reachable URLs**, passed into `imageUrls` (Veo) or `input.image_input` (jobs/createTask models). There is **no presigned-upload flow** like some other aggregators.

If the user has local reference images (from `references/` or elsewhere), you need a hosted URL before you can send them. Options, in preference order:

1. **User already has hosted URLs** (R2 / S3 / Cloudinary / CDN) — use them directly.
2. **Upload to a temp host** — document the user's chosen approach in `MASTER_CONTEXT.md` under "Image hosting" (their own bucket, `0x0.st`, a Cloudflare R2 public bucket, etc.).
3. **Data URLs** — KIE may accept base64 `data:` URLs for some models, but this is not documented as a first-class path; test per model before relying on it.

If the user has only local files and no hosting, **stop and ask** how they'd like to host them before firing any generation that needs references. Do not assume.

## Creative layer

- **MANDATORY:** Before composing any prompt for the API, **read the relevant `prompting/prompt-library/*.md` file** for the chosen model/workflow. Every prompt must align with the vendor guide's formula and best practices.
- Build **one** clear prompt paragraph; avoid keyword soup.
- For Veo / Sora / Kling / Nano Banana, align with the **official vendor guides** linked in each `prompting/prompt-library/*.md` file (do not paste full vendor docs into chat — summarize checks).
- Merge slot values from the user and from **`MASTER_CONTEXT.md`** when it conflicts with defaults.

## Session setup: dated output folder

KIE.ai does not have a dashboard folder/project concept. Organize outputs **locally** at the start of each generation session:

1. Get today's date as `YYYY-MM-DD`.
2. Create `outputs/{YYYY-MM-DD}-{brief-slug}/` for downloads (e.g. `outputs/2026-04-20-ugc-batch/`).
3. Log every call to `logs/kie-api.jsonl` (see [logs/README.md](../../logs/README.md)) so you can trace cost and history.
4. Surface the KIE dashboard link **[kie.ai/logs](https://kie.ai/logs)** if the user wants the server-side view.

## Credit cost estimation (MANDATORY — show before generating)

Before firing **any** generation calls, calculate and present the total credit cost to the user. **Do not generate until the user confirms.**

### Credit cost table

Check `MASTER_CONTEXT.md` → **Credit costs** table. If the table is empty, ask the user for their per-model credit pricing and **write the values into `MASTER_CONTEXT.md`** so future sessions have them. For the most accurate estimates, grep **`logs/kie-api.jsonl`** for prior runs with the same `model` and similar config.

KIE's pricing page: **[kie.ai/pricing](https://kie.ai/pricing)**. Per-task credit usage appears in the task record response and in **[kie.ai/logs](https://kie.ai/logs)**.

### How to calculate

```
total_credits = sum(credits_per_model × variations_requested) for each model
```

### Example output to user

```
Credit cost breakdown:
  Veo 3.1 (veo3_fast)  × 2 variations = 2 × ??
  Sora 2 Pro           × 2 variations = 2 × ??
  Nano Banana 2        × 4 variations = 4 × ??
  ─────────────────────────────
  Total: ~ credits

Proceed? (yes/no)
```

Always wait for confirmation before firing. If credit costs are unknown, ask the user to provide them (or check [kie.ai/pricing](https://kie.ai/pricing) together) before the first generation.

**Exception — QA-fix retries (still images only):** After the user has confirmed the initial batch, **automatic regeneration to fix visible defects** (see [Generated image QA](#generated-image-qa-mandatory) below) does **not** require asking again for credit confirmation. Note each extra task when summarizing the session.

## Generation count: multiple variations per prompt

Before firing any generation call, **ask the user how many variations** they want for this prompt. Default is 1 if they don't specify.

When the count is greater than 1, send **N separate API calls** with the identical payload. KIE's async model means each call returns its own `taskId` — fire them in parallel where possible (rate limit: 20 requests per 10 seconds, up to 100 concurrent tasks), then poll all `taskId`s concurrently.

Present results as a numbered list so the user can compare and pick favorites.

## Polling pattern (KIE is always async)

Every generation returns `HTTP 200` with `{ "code": 200, "data": { "taskId": "..." } }` — **this only means the task was created, not completed**.

Two ways to get results:

- **Polling (default):** `GET /api/v1/veo/record-info?taskId={id}` for Veo. For `jobs/createTask` models use the matching record-info endpoint (see [reference.md](reference.md) for the current path per model). Check every ~30 seconds. Veo videos typically take 2–5 minutes; Nano Banana images ~30–60 seconds.
- **Webhook (production):** pass `callBackUrl` in the request. KIE POSTs the final payload to your URL when done. Use this instead of polling for long-running jobs if you have an endpoint up.

Status signals vary per endpoint:
- **Veo:** `successFlag` — `0` generating, `1` success, `2`/`3` failed. Video URL(s) live in `data.info.resultUrls`.
- **Jobs:** `state` — `waiting` / `queuing` / `generating` / `success` / `fail`. Result URLs in `data.resultJson` (parsed JSON).

See [reference.md](reference.md) for the exact shape per model.

## Nano Banana image: model choice

KIE exposes multiple Nano Banana models:

- **`nano-banana-2`** (default) — current standard image model.
- **`nano-banana-pro`** — premium variant (Gemini 3 Pro image).
- **`nano-banana`** — original / legacy variant.
- **`nano-banana-edit`** — edit/inpaint an existing image.

Before the first Nano Banana image call in a workflow, ask: *"Use default Nano Banana 2, or Nano Banana Pro?"* If they have no preference, use `nano-banana-2`. Log whichever model was used in `logs/kie-api.jsonl` so credit estimates stay accurate per model.

## Script and dialogue

For any video that features a person speaking, **ask the user for the script** (the exact words the AI person should say). This is separate from the visual prompt.

- **Veo 3.1** and **Sora 2**: embed the dialogue in the `prompt` using a `Dialogue: "..."` or `She speaks: "..."` pattern.
- **Kling b-roll / scene**: typically silent — if the user wants speech, redirect to Veo 3.1 or Sora 2.
- **Nano Banana images**: no speech (still images).

## Script length → video duration (auto-select)

Average speaking pace: **~2.5 words per second** (~150 WPM). Round **up** to the next available duration.

### Sora 2 — duration typically `[4, 8, 12, 16, 20]` seconds (verify on the KIE marketplace model page)

| Script length | Duration |
|---------------|----------|
| 1–8 words | 4s |
| 9–18 words | 8s |
| 19–28 words | 12s |
| 29–38 words | 16s |
| 39–48 words | 20s |
| **49+ words** | **Too long** — offer to split |

### Veo 3.1 — no explicit duration field

Veo 3.1 auto-determines length (~8s typical). If the script exceeds ~20 words, warn the user that Veo may truncate dialogue and offer to split or switch to Sora 2.

### Kling 3.0 — duration enum varies per KIE model variant (typically `[5, 10]`)

Check the KIE marketplace page for the specific Kling model you're using. B-roll is typically wordless.

## Splitting long scripts into multiple videos

If the script exceeds the maximum duration for the chosen model:

1. **Tell the user** the script is too long and show the word/duration math.
2. **Offer two options:**
   - **Split into segments** — break at natural sentence boundaries into chunks that fit. Each becomes a separate generation call.
   - **Switch models** — if on Kling (10s max), suggest Sora 2 (up to 20s).
3. If split, generate each segment as a separate video (respecting the variation count).
4. **Offer to stitch** with `ffmpeg`:
   - Download all segments locally.
   - `ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4` (re-encode if codecs differ).
   - Present stitched + individual files.

## Veo 3.1: image input modes (`generationType`)

Veo 3.1 has three mutually exclusive `generationType` values; pick one based on user intent:

| Mode | `generationType` | `imageUrls` | When to use |
|------|------------------|-------------|-------------|
| **Text-to-video** | `TEXT_2_VIDEO` | omit | Pure prompt, no image anchor |
| **First + last frame** | `FIRST_AND_LAST_FRAMES_2_VIDEO` | 2 URLs (start, end) | User provides a starting frame and an ending frame; Veo transitions between them |
| **Reference-to-video** | `REFERENCE_2_VIDEO` | 1 URL | User provides a single reference image of a person or scene — video unfolds around/from it. **Note: `REFERENCE_2_VIDEO` only supports `veo3_fast`.** |

**Default rule:** When the user provides a single reference photo of a person, use `REFERENCE_2_VIDEO` with `veo3_fast` unless they explicitly want another model.

## Image handling: auto-upscale small inputs

Before passing any reference image URL to the API:

1. **Check dimensions.** If the longest side is below **1024 px**, upscale using Lanczos resampling so the longest side reaches **1080 px** (preserve aspect ratio).
2. **Convert to RGB JPEG** (quality 90–95) to strip alpha and keep size reasonable.
3. Re-host the resized file and pass the new URL.

Many models reject small inputs with validation errors. Auto-upscaling prevents this silently so the user never hits it.

## Generated image QA (mandatory)

Applies to **still images** from Nano Banana and other KIE image models. After each image task reaches `state: success`, **visually inspect the output** (download or open the image URL / use the agent's image-reading capability).

**Look for:** extra or missing hands or fingers; wrong limb count; distorted, duplicated, or merged facial features; melted or fused objects; impossible anatomy; stray limbs; obvious texture or boundary artifacts; unreadable or garbled text if text was requested.

**If something looks wrong:** Do **not** hand off the bad frame as the final deliverable without trying again. **Regenerate** with a **revised prompt** that explicitly corrects the issue (e.g. "exactly two hands, five fingers each, anatomically correct arms"). Do **not** resend the identical payload and expect a different outcome.

**Retry cap:** Up to **2 regeneration attempts per originally requested image** (3 attempts total including the first). If defects remain after the cap, stop auto-retries, tell the user what still looks wrong, show the best attempt or URLs for all attempts, and ask how they want to proceed.

**Credits:** Each attempt is a separate task and is billed. Summarize total credits used for that image after the QA loop ends.

**Video (optional quick check):** Before spending heavily on downstream video, you may spot-check thumbnails or extracted frames for the same kinds of defects.

Details and checklist: [prompting/prompt-library/nano-banana.md](prompting/prompt-library/nano-banana.md).

## Execution checklist (agent)

1. **Session folder:** Create/reuse `outputs/{YYYY-MM-DD}-{slug}/` for downloads.
2. **Model + endpoint:** Resolve which KIE model + endpoint to hit from the decision tree. Consult [reference.md](reference.md) for the exact request body schema.
3. **Ask for script/dialogue:** If the output is a video with a person speaking, ask the user for the exact words. Auto-select duration (see "Script length → video duration"). If too long, offer to split. (Skip for Nano Banana image-only.)
4. **Nano Banana image model:** For image calls, confirm Nano Banana 2 (default) vs Pro. Skip if not an image call.
5. **Ask for generation count:** Ask how many variations. Default to 1.
6. **Show credit cost and get confirmation:** Calculate total credits using `MASTER_CONTEXT.md` / `logs/kie-api.jsonl`. Present the breakdown. **Do NOT proceed until they confirm.**
7. **Check `references/` folder:** For any workflow needing reference images, inspect `references/influencers/`, `references/products/`, `references/aesthetics/`. If a relevant file exists, offer to use it. Confirm a hosted URL is available (see "Reference images" section above). Auto-upscale any image if needed.
8. **Compose JSON** per [reference.md](reference.md). Set `model`, `prompt`, `imageUrls` / `input.image_input`, `aspect_ratio`, `resolution`, `duration` where required. Optionally include `callBackUrl`.
9. **POST** the correct endpoint **N times** (once per variation) with the same payload, in parallel where safe. Log each request + `taskId` to `logs/kie-api.jsonl`.
10. **Poll:** hit the matching record-info endpoint every ~30s until `success` / `fail`. Poll all `taskId`s concurrently. Update the log with response, status, and credits charged.
11. **Generated image QA:** For each still image, follow [Generated image QA](#generated-image-qa-mandatory) — inspect, regenerate up to 2 retries if defective.
12. **Download results** to the session folder. For Veo, parse `data.info.resultUrls` (may be a JSON-encoded string). For jobs, parse `data.resultJson`.
13. **Present results:** Show URLs (and/or local paths) for QA-passed stills and final videos. If multiple variations, present as a numbered list. Explain failures with the KIE error code and message.
14. **Stitch if split:** If the script was split, offer to stitch with `ffmpeg` and provide both the stitched file and individual segments.

## Errors (user-facing)

- **401/403:** Fix API key / account permissions. Run the setup flow above.
- **404:** Wrong endpoint path — re-check model mapping in [reference.md](reference.md).
- **422 / 400:** Validation, moderation, or a missing/invalid `taskId` on record-info — tighten prompt, remove disallowed content, check required enums (aspect ratio, duration, model string), or re-check the taskId against the log.
- **429:** Rate-limited (>20 req/10s). Back off and retry with jitter.
- **500:** Retry later; if repeated, stop and report.

## Supporting files

- [reference.md](reference.md) — endpoints, auth detail, polling shapes, model mapping.
- [prompting/guide.md](prompting/guide.md) — marketing brief → API.
- [prompting/prompt-library/veo-3-1.md](prompting/prompt-library/veo-3-1.md) — Veo 3.1 prompting.
- [prompting/prompt-library/sora-2.md](prompting/prompt-library/sora-2.md) — Sora 2 prompting.
- [prompting/prompt-library/nano-banana.md](prompting/prompt-library/nano-banana.md) — Nano Banana image prompting + QA.
- [prompting/prompt-library/kling-3.md](prompting/prompt-library/kling-3.md) — Kling prompting.
- [prompting/prompt-library/character-sheet.md](prompting/prompt-library/character-sheet.md) — 10-image AI influencer character sheet workflow.
- [prompting/prompt-library/ugc-product-selfie.md](prompting/prompt-library/ugc-product-selfie.md) — UGC selfie-style still: character + product + style refs.
- [prompting/prompt-library/ugc-selfie-style.md](prompting/prompt-library/ugc-selfie-style.md) — cross-model UGC formulas.
- [prompting/prompt-library/product-showcase.md](prompting/prompt-library/product-showcase.md) — product-in-hand video workflow.
- [prompting/prompt-library/influencer-recreation.md](prompting/prompt-library/influencer-recreation.md) — recreate an influencer from a reference photo.
- [prompting/brand-voice-starter.md](prompting/brand-voice-starter.md) — template to copy into `MASTER_CONTEXT.md`.
