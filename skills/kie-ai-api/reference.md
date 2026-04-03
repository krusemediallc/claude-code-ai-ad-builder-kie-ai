# KIE AI API — reference

Official docs: [https://docs.kie.ai](https://docs.kie.ai)
Full model list: [llms.txt](https://docs.kie.ai/llms.txt)

## Base URLs

| Service | URL |
|---------|-----|
| **Main API** | `https://api.kie.ai` |
| **File upload** | `https://kieai.redpandaai.co` |

Override with env `KIE_BASE_URL` / `KIE_UPLOAD_URL` if needed.

## Authentication

All requests use **Bearer token** auth.

- **Header:** `Authorization: Bearer $KIE_API_KEY`
- **Content-Type:** `application/json`
- **Env:** `KIE_API_KEY` — never commit it; load from `.env`.
- **401:** key missing or invalid — run the setup flow in `SKILL.md`.

### curl example

```bash
source .env && curl -sS \
  -H "Authorization: Bearer $KIE_API_KEY" \
  -H "Content-Type: application/json" \
  "https://api.kie.ai/api/v1/chat/credit"
```

## Endpoint architecture

KIE uses **two endpoint patterns** depending on the model:

| Pattern | Endpoint | Models |
|---------|----------|--------|
| **Dedicated route** | Model-specific path (e.g. `/api/v1/veo/generate`) | Veo 3.1, Runway |
| **Generic jobs** | `POST /api/v1/jobs/createTask` | Sora 2, Kling 3.0, Nano Banana 2, and most market models |

Polling also differs by pattern — see [Polling and delivery](#polling-and-delivery) below.

## Model → route mapping (primary models)

| Model | Generate endpoint | Polling endpoint | Request schema |
|-------|------------------|-----------------|----------------|
| **Veo 3.1** | `POST /api/v1/veo/generate` | `GET /api/v1/veo/record-info?taskId=` | See [Veo 3.1 DTO](#veo-31-dto) |
| **Veo 3.1 extend** | `POST /api/v1/veo/extend` | `GET /api/v1/veo/record-info?taskId=` | See [Veo extend](#veo-31-extend) |
| **Veo 3.1 1080p** | `GET /api/v1/veo/get-1080p-video?taskId=` | Same endpoint (returns when ready) | taskId from generate |
| **Veo 3.1 4K** | `POST /api/v1/veo/get-4k-video` | `GET /api/v1/veo/record-info?taskId=` | taskId from generate |
| **Runway** | `POST /api/v1/runway/generate` | `GET /api/v1/runway/record-detail?taskId=` | See [Runway DTO](#runway-dto) |
| **Runway extend** | `POST /api/v1/runway/extend` | `GET /api/v1/runway/record-detail?taskId=` | taskId + prompt |
| **Sora 2 (text→video)** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "sora-2-text-to-video"` |
| **Sora 2 (image→video)** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "sora-2-image-to-video"` |
| **Sora 2 Pro (text)** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "sora-2-pro-text-to-video"` |
| **Sora 2 Pro (image)** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "sora-2-pro-image-to-video"` |
| **Kling 3.0** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "kling-3.0/video"` |
| **Kling 3.0 motion ctrl** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "kling-3.0/motion-control"` |
| **Nano Banana 2** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "nano-banana-2"` |
| **Nano Banana Pro** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "google/nano-banana"` |
| **Seedance 2.0** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "bytedance/seedance-2"` |
| **Wan 2.7 Image** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "wan/2-7-image"` |
| **Wan 2.7 Image Pro** | `POST /api/v1/jobs/createTask` | `GET /api/v1/jobs/recordInfo?taskId=` | `model: "wan/2-7-image-pro"` |
| **Flux Kontext** | `POST /api/v1/flux/kontext/generate` | `GET /api/v1/flux/kontext/record-info?taskId=` | See Flux Kontext docs |

## Polling and delivery

### Dedicated-route models (Veo 3.1)

`GET /api/v1/veo/record-info?taskId={taskId}`

**Response:**
```json
{
  "code": 200,
  "data": {
    "taskId": "...",
    "successFlag": 0,
    "resultUrls": "[\"https://...\"]",
    "response": { "resultUrls": [...], "resolution": "720p" }
  }
}
```

**`successFlag` values:**
- `0` = Processing
- `1` = Success
- `2` = Failed
- `3` = Generation failed (upstream)

### Dedicated-route models (Runway)

`GET /api/v1/runway/record-detail?taskId={taskId}`

**Response states:** `wait` → `queueing` → `generating` → `success` | `fail`

**Success response includes:** `videoInfo.videoUrl`, `videoInfo.imageUrl`

### Generic jobs models (Sora 2, Kling, Nano Banana, etc.)

`GET /api/v1/jobs/recordInfo?taskId={taskId}`

**Response:**
```json
{
  "code": 200,
  "data": {
    "taskId": "...",
    "model": "nano-banana-2",
    "state": "success",
    "resultJson": "{\"images\":[{\"url\":\"...\"}]}",
    "progress": 100
  }
}
```

**`state` values:** `waiting` → `queuing` → `generating` → `success` | `fail`

**`resultJson`:** JSON string containing output URLs. Parse it. Structure varies by model:
- Images: `{"images": [{"url": "..."}]}`
- Videos: `{"videos": [{"url": "..."}]}` (varies by model)

**`progress`:** 0-100 (currently only Sora 2 models report progress).

## Key request bodies

### Veo 3.1 DTO

**Endpoint:** `POST /api/v1/veo/generate`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `prompt` | string | Yes | Video description |
| `model` | string | No | `veo3` (quality), `veo3_fast` (default), `veo3_lite` |
| `generationType` | string | No | `TEXT_2_VIDEO`, `FIRST_AND_LAST_FRAMES_2_VIDEO`, `REFERENCE_2_VIDEO` |
| `imageUrls` | string[] | Conditional | 1-2 image URLs for image-to-video |
| `aspect_ratio` | string | No | `16:9` (default), `9:16`, `Auto` |
| `seeds` | integer | No | 10000-99999 for reproducibility |
| `callBackUrl` | string | No | Webhook URL |
| `enableTranslation` | boolean | No | Auto-translate to English (default: true) |
| `watermark` | string | No | Optional watermark text |

**Image-to-video modes:**
- 1 image URL → video unfolds around it (like startFrame)
- 2 image URLs → creates a transition between them (first→last frame)

**No `duration` field** — Veo 3.1 auto-determines length (~8s typical).

### Veo 3.1 extend

**Endpoint:** `POST /api/v1/veo/extend`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `taskId` | string | Yes | Original Veo task ID |
| `prompt` | string | Yes | Extension description |
| `model` | string | No | `fast` (default), `quality`, `lite` |
| `seeds` | integer | No | 10000-99999 |
| `callBackUrl` | string | No | Webhook URL |

### Runway DTO

**Endpoint:** `POST /api/v1/runway/generate`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `prompt` | string | Yes | Video description (max 1800 chars) |
| `duration` | number | Yes | `5` or `10` seconds |
| `quality` | string | Yes | `720p` or `1080p` (1080p only for 5s) |
| `aspectRatio` | string | Conditional | Required for text-only: `16:9`, `9:16`, `1:1`, `4:3`, `3:4` |
| `imageUrl` | string | No | Reference image URL for animation |
| `waterMark` | string | No | Watermark text (empty = none) |
| `callBackUrl` | string | No | Webhook URL |

### Sora 2 text-to-video DTO

**Endpoint:** `POST /api/v1/jobs/createTask`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `sora-2-text-to-video` or `sora-2-pro-text-to-video` |
| `input.prompt` | string | Yes | Max 10,000 chars |
| `input.aspect_ratio` | string | No | `portrait` or `landscape` (default: landscape) |
| `input.n_frames` | string | No | `10` or `15` (default: 10) |
| `input.size` | string | No | **Pro only:** `standard` or `high` (default: high). Not valid on non-Pro models. |
| `input.remove_watermark` | boolean | No | Remove watermarks |
| `input.upload_method` | string | Yes | `s3` or `oss` (default: s3) |
| `input.character_id_list` | string[] | No | Up to 5 character IDs |
| `callBackUrl` | string | No | Webhook URL |
| `progressCallBackUrl` | string | No | Progress webhook |

### Sora 2 image-to-video DTO

Same as text-to-video plus:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `sora-2-image-to-video` or `sora-2-pro-image-to-video` |
| `input.image_urls` | string[] | Yes | Single publicly accessible image URL |

### Kling 3.0 DTO

**Endpoint:** `POST /api/v1/jobs/createTask`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `kling-3.0/video` |
| `input.prompt` | string | Yes* | For single-shot (max 500 chars per shot) |
| `input.duration` | string | Yes | `3` to `15` seconds |
| `input.aspect_ratio` | string | No | `16:9` (default), `9:16`, `1:1` |
| `input.mode` | string | No | `std` or `pro` (default: pro) |
| `input.sound` | boolean | No | Enable sound effects (default: false) |
| `input.image_urls` | string[] | No | First/last frame images |
| `input.multi_shots` | boolean | No | Multi-shot mode (default: false) |
| `input.multi_prompt` | object[] | No* | Array of `{prompt, duration}` for multi-shot |
| `input.kling_elements` | object[] | No | Up to 3 elements with `name`, `description`, `element_input_urls` |
| `callBackUrl` | string | No | Webhook URL |

*Use `prompt` for single-shot OR `multi_prompt` for multi-shot mode.

**Resolution (mode):**
- `std`: 1280×720 / 720×1280 / 720×720
- `pro`: 1920×1080 / 1080×1920 / 1080×1080

### Nano Banana 2 DTO

**Endpoint:** `POST /api/v1/jobs/createTask`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `nano-banana-2` |
| `input.prompt` | string | Yes | Max 20,000 chars |
| `input.image_input` | string[] | No | Up to 14 reference image URLs (JPEG/PNG/WebP, max 30MB each) |
| `input.aspect_ratio` | string | No | `1:1`, `9:16`, `16:9`, `3:4`, `4:3`, `2:3`, `3:2`, `4:5`, `5:4`, `auto` (default: auto) |
| `input.resolution` | string | No | `1K`, `2K`, `4K` (default: 1K) |
| `input.output_format` | string | No | `png`, `jpg` (default: jpg) |
| `callBackUrl` | string | No | Webhook URL |

### Nano Banana Pro DTO

Same endpoint, different model:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `google/nano-banana` |
| `input.prompt` | string | Yes | Max 5,000 chars |
| `input.image_size` | string | No | Same aspect ratios as NB2 (default: 1:1) |
| `input.output_format` | string | No | `png`, `jpeg` (default: png) |
| `callBackUrl` | string | No | Webhook URL |

**Note:** Nano Banana Pro uses `image_size` while NB2 uses `aspect_ratio`. Pro uses `jpeg` while NB2 uses `jpg`.

### Kling 3.0 Motion Control DTO

**Endpoint:** `POST /api/v1/jobs/createTask`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `kling-3.0/motion-control` |
| `input.input_urls` | string[] | Yes | Single image URL (JPEG/PNG, max 10MB, >340px, aspect 2:5–5:2) |
| `input.video_urls` | string[] | Yes | Single video URL (MP4/QuickTime, 3-30s, max 100MB) |
| `input.prompt` | string | No | Text guidance (max 2,500 chars) |
| `input.mode` | string | No | `std` (720p) or `pro` (1080p, default: 720p) |
| `input.character_orientation` | string | No | `video` or `image` (default: video) |
| `input.background_source` | string | No | `input_video` or `input_image` (default: input_video) |
| `callBackUrl` | string | No | Webhook URL |

Transfers motion from a reference video onto a character from a reference image. `character_orientation` controls whether the character faces the direction from the video or the image. `background_source` controls which input provides the background.

### Seedance 2.0 DTO

**Endpoint:** `POST /api/v1/jobs/createTask`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `bytedance/seedance-2` |
| `web_search` | boolean | Yes | Enable web search for prompt context |
| `input.prompt` | string | Yes | 3-2,500 chars |
| `input.first_frame_url` | string | No | Starting frame image URL or asset ID |
| `input.last_frame_url` | string | No | Ending frame image URL or asset ID |
| `input.reference_image_urls` | string[] | No | Up to 7 multimodal image refs (JPEG/PNG/WebP, max 10MB each) |
| `input.reference_video_urls` | string[] | No | Up to 3 video refs (MP4/QuickTime/Matroska, max 10MB each, 15s total) |
| `input.reference_audio_urls` | string[] | No | Up to 3 audio refs (MPEG/WAV/AAC/OGG, max 10MB each, 15s total) |
| `input.duration` | integer | No | `4`, `8` (default), or `12` seconds |
| `input.resolution` | string | No | `480p` or `720p` (default) |
| `input.aspect_ratio` | string | No | `1:1`, `4:3`, `3:4`, `16:9` (default), `9:16`, `21:9`, `adaptive` |
| `input.generate_audio` | boolean | No | Include audio/lip-sync (default: true). Higher cost when enabled. |
| `input.return_last_frame` | boolean | No | Return final frame as image (default: false) |
| `callBackUrl` | string | No | Webhook URL |

**Multimodal inputs:** Seedance 2.0 uniquely supports combining text + images + videos + audio in a single call. Use `reference_image_urls` for style/character refs, `reference_video_urls` for motion/style transfer, and `reference_audio_urls` for beat-matching or voice reference.

**First/last frame:** Use `first_frame_url` and `last_frame_url` together for precise start→end transitions, or just `first_frame_url` alone for start-frame behavior (like Veo 3.1's single `imageUrls`).

**Asset Library requirement for person images:** If using a real-person image as `first_frame_url` or in `reference_image_urls`, you must first upload it to the ByteDance Asset Library. Regular image URLs will fail with "Real-person images are supported, but you must upload them to the Asset Library first."

**Confirmed workflow (tested 2026-04-03):**

1. `POST /api/v1/playground/createAsset` with `{"url": "<public_image_url>", "assetType": "Image"}` → returns asset ID (e.g. `"asset-20260404003336-5r825"`)
2. `GET /api/v1/playground/getAsset?assetId=<asset_id>` → verify `status: "Active"` (usually instant)
3. Use `asset://<asset_id>` as the value for `first_frame_url` or entries in `reference_image_urls`

**Key format:** `asset://asset-20260404003336-5r825` — NOT the full ByteDance URL, NOT the bare asset ID.

### ByteDance Asset Library

**Create asset:** `POST /api/v1/playground/createAsset`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `url` | string (URI) | Yes | Publicly accessible file URL (no base64) |
| `assetType` | string | Yes | `Image`, `Video`, or `Audio` |

**Response:** `{"code": 200, "data": "asset-..."}` — the `data` field IS the asset ID.

**Query asset:** `GET /api/v1/playground/getAsset?assetId=<asset_id>`

**Response:** `{"data": {"status": "Active", "url": "https://ark-media-asset...", "errorMsg": null}}`

Status values: `Active` (ready to use), others indicate processing or failure.

**Asset constraints:**
- Images: JPEG/PNG/WebP/BMP/TIFF/GIF/HEIC, 300-6000px, aspect ratio 0.4-2.5, <30MB
- Videos: MP4/MOV, 480p-720p, 2-15s, 24-60fps, <50MB
- Audio: WAV/MP3, 2-15s, <15MB

**Credit costs (per second of output):**

| Resolution | With video input | Without video input |
|-----------|-----------------|-------------------|
| 720p | 25 credits/s ($0.125/s) | 41 credits/s ($0.205/s) |
| 480p | 11.5 credits/s ($0.0575/s) | 19 credits/s ($0.095/s) |

**Generation time:** ~5 min (fast) to ~10 min (standard).

### Wan 2.7 Image DTO

**Endpoint:** `POST /api/v1/jobs/createTask`

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `wan/2-7-image` or `wan/2-7-image-pro` |
| `input.prompt` | string | Yes | Max 5,000 chars. Supports Chinese and English. |
| `input.input_urls` | string[] | No | Up to 9 reference image URLs |
| `input.aspect_ratio` | string | No | `1:1`, `16:9`, `4:3`, `21:9`, `3:4`, `9:16`, `8:1`, `1:8` |
| `input.n` | integer | No | Number of images: 1-4 (or 1-12 if `enable_sequential: true`). Default: 4 |
| `input.resolution` | string | No | `1K`, `2K`, `4K` (default: 2K). 4K only on Pro. |
| `input.enable_sequential` | boolean | No | Group image mode (default: false) |
| `input.thinking_mode` | boolean | No | Enhanced reasoning for complex prompts (default: false) |
| `input.color_palette` | object[] | No | 3-10 color objects `{hex, ratio}` for custom color themes |
| `input.watermark` | boolean | No | Add watermark (default: false) |
| `input.seed` | integer | No | 0-2147483647 (default: 0) |
| `callBackUrl` | string | No | Webhook URL |

**Pro differences:** `wan/2-7-image-pro` supports `4K` resolution and generally produces higher quality output.

## File upload

KIE uses a separate upload service at `https://kieai.redpandaai.co`.

### Upload from URL

`POST https://kieai.redpandaai.co/api/file-url-upload`

```json
{
  "fileUrl": "https://example.com/image.jpg",
  "uploadPath": "references",
  "fileName": "my-image.jpg"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "fileName": "my-image.jpg",
    "filePath": "references/my-image.jpg",
    "downloadUrl": "https://kieai.redpandaai.co/download/...",
    "fileSize": 245760,
    "mimeType": "image/jpeg"
  }
}
```

### Upload base64

`POST https://kieai.redpandaai.co/api/file-base64-upload`

```json
{
  "base64Data": "data:image/jpeg;base64,...",
  "uploadPath": "references",
  "fileName": "my-image.jpg"
}
```

### Upload binary stream

`POST https://kieai.redpandaai.co/api/file-stream-upload` (multipart/form-data)

**Constraints:**
- Files auto-delete after **3 days**
- Base64: max ~10MB recommended
- URL upload: max 100MB, 30s download timeout
- No upload charges

### Using uploaded files as references

After uploading, use the `downloadUrl` from the response as the image URL in generation calls (e.g. `imageUrls` for Veo 3.1, `input.image_input` for Nano Banana 2, `input.image_urls` for Sora 2 image-to-video).

## Common utility endpoints

### Check credits

`GET /api/v1/chat/credit`

```json
{ "code": 200, "msg": "success", "data": 100 }
```

`data` is the integer credit balance.

### Get download URL

`POST /api/v1/common/download-url`

```json
{ "url": "https://tempfile.1f6c..." }
```

Returns a temporary download URL (valid 20 min) for KIE-generated files.

## Duration summary (quick reference)

| Model | Duration control | Options | Has speech? |
|-------|-----------------|---------|-------------|
| Veo 3.1 | None (auto) | ~8s typical | Yes (in prompt) |
| Runway | `duration` (required) | 5, 10 seconds | No |
| Sora 2 | `n_frames` | 10 or 15 | Yes (in prompt) |
| Kling 3.0 | `duration` (required) | 3-15 seconds | Optional (`sound: true`) |
| Seedance 2.0 | `duration` (required) | 4, 8, 12 seconds | Yes (`generate_audio: true`) |
| Nano Banana (image) | N/A | N/A | No |

## Rate limits

- **20 new generation requests per 10 seconds** per account
- **100+ concurrent running tasks** supported
- Exceeded → HTTP 429 (rejected, not queued)

## Data retention

- Generated media files: **14 days**
- Uploaded files: **3 days**
- Log records (text/metadata): **2 months**
- Download URLs from `/common/download-url`: **20 minutes**

## Errors

| Code | Typical meaning |
|------|-----------------|
| 401 | Invalid API key |
| 402 | Insufficient credits |
| 404 | Task not found |
| 422 | Validation error |
| 429 | Rate limit exceeded |
| 500 | Server error — retry later |
| 501 | Generation failed (upstream) |
| 505 | Feature disabled |
