# KIE.ai external API — reference

Official docs: **[docs.kie.ai](https://docs.kie.ai/)** · Model marketplace: **[kie.ai/market](https://kie.ai/market)** · Pricing: **[kie.ai/pricing](https://kie.ai/pricing)** · Task logs UI: **[kie.ai/logs](https://kie.ai/logs)**

## Base URL

`https://api.kie.ai`

Override with env `KIE_BASE_URL` if needed.

## Authentication

Bearer token on every request:

```
Authorization: Bearer $KIE_API_KEY
Content-Type: application/json
```

- **Env:** `KIE_API_KEY` — loaded from `.env`, never committed.
- **401 / 403:** key missing, wrong, or account lacks permission — run the setup flow in `SKILL.md` (editor-first `.env`).

### curl example

```bash
source .env && curl -sS \
  -H "Authorization: Bearer $KIE_API_KEY" \
  "https://api.kie.ai/api/v1/chat/credit"
```

The `/api/v1/chat/credit` endpoint returns your account credit balance and is the simplest auth-check.

## Two endpoint families

KIE splits generation endpoints into two families:

1. **Model-specific endpoints** — legacy/first-party models have their own path.
   - Veo 3 / 3.1: `POST /api/v1/veo/generate` + `GET /api/v1/veo/record-info?taskId=...`
2. **Unified jobs endpoint** — most marketplace models use a single entry point with a `model` field.
   - `POST /api/v1/jobs/createTask` + `GET /api/v1/jobs/recordInfo?taskId=...` (verify exact record-info path on the specific model's page; some use `/api/v1/playground/recordInfo`).

When in doubt, open the model's page under **[docs.kie.ai/market](https://docs.kie.ai/market/)** — each marketplace model lists its exact POST path and record-info path.

## Model → endpoint mapping (primary models)

| User-facing model | KIE `model` string | POST endpoint | Record-info endpoint |
|-------------------|-------------------|---------------|----------------------|
| **Veo 3** | `veo3` | `POST /api/v1/veo/generate` | `GET /api/v1/veo/record-info?taskId=...` |
| **Veo 3 Fast** | `veo3_fast` (default) | `POST /api/v1/veo/generate` | `GET /api/v1/veo/record-info?taskId=...` |
| **Veo 3 Lite** | `veo3_lite` | `POST /api/v1/veo/generate` | `GET /api/v1/veo/record-info?taskId=...` |
| **Veo 3.1** (same API; version comes from model string) | see [docs.kie.ai/veo3-api](https://docs.kie.ai/veo3-api/quickstart) | `POST /api/v1/veo/generate` | `GET /api/v1/veo/record-info?taskId=...` |
| **Sora 2 text-to-video** | `sora-2-text-to-video` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Sora 2 Pro text-to-video** | `sora-2-pro-text-to-video` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Sora 2 image-to-video** | `sora-2-image-to-video` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Nano Banana 2** (default image) | `nano-banana-2` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Nano Banana Pro** | `nano-banana-pro` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Nano Banana** (legacy) | `nano-banana` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Nano Banana Edit** | `nano-banana-edit` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Kling 3.0** | per marketplace (e.g. `kling-3`, `kling-3-pro`) | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Seedance 2** | `bytedance/seedance-2` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Seedance 2 Fast** | `bytedance/seedance-2-fast` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |
| **Seedance 1.5 Pro** | `bytedance/seedance-1.5-pro` | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=...` |

**Always verify the exact `model` string and record-info path on the marketplace page before firing.** KIE adds and renames models as vendors update; record confirmed strings in `MASTER_CONTEXT.md`.

## Polling and delivery

### Veo (`/api/v1/veo/record-info`)

Observed shape (confirmed 2026-04-20 with a real `veo3_fast` `TEXT_2_VIDEO` call):

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "taskId": "4c9a31a5bb61db65d10f1210d78cc08a",
    "paramJson": "{\"aspectRatio\":\"16:9\",\"enableFallback\":false,...}",
    "response": {
      "taskId": "4c9a31a5bb61db65d10f1210d78cc08a",
      "resolution": "720p",
      "originUrls": null,
      "resultUrls": ["https://tempfile.aiquickdraw.com/v/…_…mp4"],
      "fullResultUrls": null,
      "hasAudioList": [true],
      "seeds": [61668]
    },
    "successFlag": 1,
    "fallbackFlag": false,
    "completeTime": 1776728275000,
    "createTime": 1776728214000,
    "errorCode": null,
    "errorMessage": null
  }
}
```

- **`data.successFlag`**: `0` generating · `1` success · `2` failed · `3` generation failed (task was created but output failed).
- **Result URLs live at `data.response.resultUrls`** (real array, NOT a JSON-encoded string).
- `data.paramJson` is a JSON-encoded string echoing your request params.
- `completeTime - createTime` gives you wall-clock generation time in milliseconds.
- Poll every **~30s**. Text-to-video `veo3_fast` observed at **~61s**; more complex modes can take 2–5 minutes.
- Veo outputs live on `tempfile.aiquickdraw.com` and may expire (~24h). Download locally to `outputs/{date}-{slug}/` for durability. Use `POST /api/v1/common/download-url` with the temp URL to get a fresh download link if expired.

### Jobs (`/api/v1/jobs/recordInfo`)

Generic async-job record. This is the path confirmed across Seedance, Nano Banana, and Sora 2 models (2026-04-20) — don't use `/api/v1/playground/recordInfo` unless a specific model's docs page says so.

Observed shape (confirmed 2026-04-20 with `bytedance/seedance-2`):

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "taskId": "da2f3b4d3826a124edf678dfec75645d",
    "model": "bytedance/seedance-2",
    "state": "success",
    "param": "{\"input\":\"{…doubly-escaped JSON…}\",\"model\":\"bytedance/seedance-2\"}",
    "resultJson": "{\"resultUrls\":[\"https://tempfile.aiquickdraw.com/seedance/…mp4\"]}",
    "failCode": null,
    "failMsg": null,
    "costTime": 208,
    "completeTime": 1776728422476,
    "createTime": 1776728214352
  }
}
```

- **`data.state`**: `waiting` · `queuing` · `generating` · `success` · `fail`.
- `data.resultJson` is a **JSON-encoded string**; `JSON.parse` it to get `.resultUrls`.
- `data.param` is also a JSON-encoded string (with doubly-escaped `input` for some models) — not usually needed, but useful for reconstructing the original request.
- `data.costTime` is generation wall-clock in **seconds** (Seedance 5s-@720p observed ~208s ≈ 3.5 min).
- `data.failCode` + `data.failMsg` populate on failure.
- Poll every ~30s. Nano Banana images ~30–60s · Seedance 2 video ~3–4 min · Sora 2 video ~2–5 min.

### Webhook alternative

Any generation request can include `callBackUrl`. KIE POSTs the completed task payload to that URL when done — skip polling entirely for long jobs if you have an endpoint up.

## Key request bodies

### Veo 3 / 3.1 — `POST /api/v1/veo/generate`

```json
{
  "prompt": "A dog playing in a park",
  "imageUrls": ["https://your-host/ref1.jpg"],
  "model": "veo3_fast",
  "generationType": "REFERENCE_2_VIDEO",
  "aspect_ratio": "16:9",
  "resolution": "1080p",
  "enableTranslation": true,
  "enableFallback": false,
  "watermark": "",
  "callBackUrl": "https://your-domain.com/webhook"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `prompt` | string | ✓ | Describe action, scene, style. Embed dialogue as `Dialogue: "..."`. |
| `model` | string | — | `veo3`, `veo3_fast` (default), `veo3_lite` |
| `imageUrls` | string[] | — | 1 URL for `REFERENCE_2_VIDEO`; 2 URLs (start, end) for `FIRST_AND_LAST_FRAMES_2_VIDEO` |
| `generationType` | string | — | `TEXT_2_VIDEO` · `REFERENCE_2_VIDEO` · `FIRST_AND_LAST_FRAMES_2_VIDEO`. `REFERENCE_2_VIDEO` only works with `veo3_fast`. |
| `aspect_ratio` | string | — | `16:9` (default), `9:16`, `Auto` |
| `resolution` | string | — | `720p` (default), `1080p`, `4k` |
| `enableTranslation` | bool | — | Auto-translate prompt to English (default `true`). |
| `enableFallback` | bool | — | Allow lower-cost fallback on failure. |
| `watermark` | string | — | Optional watermark text. |
| `callBackUrl` | string | — | Webhook for completion. |

Response:

```json
{ "code": 200, "msg": "success", "data": { "taskId": "veo_task_…" } }
```

Veo 3.1 uses the same endpoint; the version resolves from the `model` string. Verify current model names at **[docs.kie.ai/veo3-api/generate-veo-3-video](https://docs.kie.ai/veo3-api/generate-veo-3-video)**.

### Nano Banana 2 image — `POST /api/v1/jobs/createTask`

```json
{
  "model": "nano-banana-2",
  "callBackUrl": "https://your-domain.com/webhook",
  "input": {
    "prompt": "Minimal product hero: matte black earbuds on concrete…",
    "image_input": [],
    "aspect_ratio": "1:1",
    "resolution": "1K",
    "output_format": "jpg"
  }
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | ✓ | `nano-banana-2`, `nano-banana-pro`, `nano-banana`, `nano-banana-edit` |
| `input.prompt` | string | ✓ | Image description (max 20,000 chars). |
| `input.image_input` | string[] | — | Up to **14 URLs** (JPEG/PNG/WebP, max 30 MB each). |
| `input.aspect_ratio` | string | — | `1:1`, `1:4`, `1:8`, `2:3`, `3:2`, `3:4`, `4:1`, `4:3`, `4:5`, `5:4`, `8:1`, `9:16`, `16:9`, `21:9`, `auto` (default). |
| `input.resolution` | string | — | `1K` (default), `2K`, `4K`. |
| `input.output_format` | string | — | `jpg` (default), `png`. |
| `callBackUrl` | string | — | Webhook. |

Response: same `{code: 200, data: {taskId}}` pattern.

Details: **[docs.kie.ai/market/google/nanobanana2](https://docs.kie.ai/market/google/nanobanana2)**.

### Sora 2 text-to-video — `POST /api/v1/jobs/createTask`

```json
{
  "model": "sora-2-text-to-video",
  "callBackUrl": "https://your-domain.com/webhook",
  "input": {
    "prompt": "A UGC-style selfie vlog of a 22-year-old college student…",
    "aspect_ratio": "9:16",
    "duration": 8,
    "resolution": "720p"
  }
}
```

Verify exact fields and enums on **[docs.kie.ai/market/sora2](https://docs.kie.ai/market/sora2/sora-2-pro-text-to-video)** — marketplace schemas evolve.

Typical Sora duration enum: `[4, 8, 12, 16, 20]` seconds. See SKILL.md "Script length → video duration" for auto-selection.

### Sora 2 image-to-video — `POST /api/v1/jobs/createTask`

```json
{
  "model": "sora-2-image-to-video",
  "input": {
    "prompt": "She looks at the camera and says: \"Best gummies I've tried.\"",
    "image_urls": ["https://your-host/starting-frame.jpg"],
    "aspect_ratio": "9:16",
    "duration": 8
  }
}
```

### Kling / Seedance / other marketplace models

Pattern: `POST /api/v1/jobs/createTask` with `{model: "<kling-or-seedance-model>", input: {...}}`. Fields vary per model — pull from the model's marketplace page on [docs.kie.ai/market](https://docs.kie.ai/market) the first time you use it and record confirmed shapes in `MASTER_CONTEXT.md`.

## Reference images: URL-based only

KIE does **not** provide a presigned file-upload endpoint. Reference images must be passed as **publicly reachable URLs**.

**Workflow for local files:**

1. Upload locally-stored images to a public host (R2 / S3 / Cloudinary / temp host).
2. Pass the hosted URL into `imageUrls` (Veo) or `input.image_input` (jobs).
3. Record the hosting strategy in `MASTER_CONTEXT.md` so the agent defaults consistently.

See `SKILL.md` → **Reference images: hosted URLs, not file uploads** for policy.

## Image minimum size — auto-upscale

Some models reject small inputs with validation errors. To avoid this:

1. Before sending any image URL, check its dimensions.
2. If the longest side **< 1024 px**, upscale with Lanczos resampling so the longest side **= 1080 px** (preserve aspect ratio).
3. Convert to RGB JPEG (quality 90–95) — strips alpha some models don't handle.
4. Re-host the resized file and pass the new URL.

This should happen transparently — never ask the user about it.

## Common API utilities

- **Account credits:** `GET /api/v1/chat/credit` — returns `{code, msg, data: <credit_balance>}`. Doubles as auth-check.
- **Download link refresh:** `POST /api/v1/common/download-url` with `{"url": "<tempfile-url>"}` — returns a fresh download link when a temp URL has expired.

See: **[docs.kie.ai/common-api/quickstart](https://docs.kie.ai/common-api/quickstart)**.

## Rate limits & concurrency

- **20 new requests per 10 seconds** (per account).
- **100+ concurrent running tasks** supported.
- Exceeding these returns **HTTP 429**. Back off with jitter and retry.

## Errors

| Code | Typical meaning |
|------|-----------------|
| 400 | Malformed request — check JSON shape |
| 401 / 403 | Auth / permission |
| 404 | Wrong endpoint path |
| 422 | Validation, moderation block, OR missing `taskId` on record-info (message tells you which) |
| 429 | Rate-limited — back off |
| 500 | Server error — retry later |

## Product showcase workflow (how to combine pieces)

1. User provides **product image(s)** hosted at public URLs.
2. Agent composes a **Nano Banana prompt** describing the AI person interacting with the product.
3. `POST /api/v1/jobs/createTask` with `model: "nano-banana-2"` and `input.image_input` containing the product URL(s) — get a **still image** of the person with the product.
4. User **approves** the still.
5. Approved still URL → `POST /api/v1/veo/generate` with `generationType: "REFERENCE_2_VIDEO"` and the still URL in `imageUrls`. Alternative: Sora 2 image-to-video.

See [prompting/prompt-library/product-showcase.md](prompting/prompt-library/product-showcase.md).

## Dashboard and logs

- **[kie.ai/logs](https://kie.ai/logs)** — server-side task history, status, model, credit consumption.
- **[kie.ai/api-key](https://kie.ai/api-key)** — key management, usage caps, IP whitelist.
- Locally, append every call to `logs/kie-api.jsonl` (see [logs/README.md](../../logs/README.md)) for cost estimation and reproducibility.
