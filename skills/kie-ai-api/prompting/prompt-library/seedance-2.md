# Seedance 2.0 — prompts for KIE AI

**KIE endpoint:** `POST /api/v1/jobs/createTask` with `model: "bytedance/seedance-2"`.

## Features

- **Multimodal inputs:** Combine text + images (up to 7) + videos (up to 3) + audio (up to 3) in a single call
- **First/last frame control:** `first_frame_url` and `last_frame_url` for precise start/end transitions
- **Native audio with lip-sync:** `generate_audio: true` (default) — generates speech, sound effects, and beat-matched audio
- **Duration:** 4, 8, or 12 seconds
- **Resolution:** 480p (fast, cheap) or 720p (default, balanced)
- **Aspect ratios:** 1:1, 4:3, 3:4, 16:9, 9:16, 21:9, adaptive
- **Web search:** `web_search: true` to pull context from the web
- **Character consistency** across multi-shot storytelling via reference images

## When to use Seedance 2.0 vs other models

| Scenario | Best model | Why |
|----------|-----------|-----|
| Need audio/lip-sync natively | **Seedance 2.0** | Built-in audio generation, others need separate audio step |
| Matching motion from reference video | **Seedance 2.0** or **Kling 3.0 Motion Control** | Both support video references |
| Precise start AND end frame | **Seedance 2.0** | Only model with both `first_frame_url` + `last_frame_url` |
| Multiple image + video + audio refs | **Seedance 2.0** | Most multimodal input flexibility (7+3+3) |
| Animating a single start frame | **Veo 3.1** | More reliable frame-one fidelity |
| Longest single generation | **Kling 3.0** (up to 15s) | Seedance 2.0 maxes at 12s |
| Budget-conscious | **Seedance 2.0 480p** | Cheapest video per second |

## Credit costs (per second of output)

| Resolution | With video input | Without video input | 8s cost (no video) |
|-----------|-----------------|-------------------|-------------------|
| 720p | 25 cr/s ($0.125/s) | 41 cr/s ($0.205/s) | ~328 credits |
| 480p | 11.5 cr/s ($0.0575/s) | 19 cr/s ($0.095/s) | ~152 credits |

**Note:** Audio generation (`generate_audio: true`) increases cost. Set `generate_audio: false` for silent video to reduce credits.

## Asset Library requirement (person images)

If using a **real-person image** as `first_frame_url` or in `reference_image_urls`, you must first upload it to the **ByteDance Asset Library**:

1. Ensure the image is at a public URL (upload to KIE file upload first if it's a local file).
2. `POST /api/v1/playground/createAsset` with `{"url": "<public_url>", "assetType": "Image"}` → returns asset ID (e.g. `"asset-20260404003336-5r825"`).
3. `GET /api/v1/playground/getAsset?assetId=<asset_id>` → verify `status: "Active"`.
4. Use `asset://<asset_id>` as the value (e.g. `"asset://asset-20260404003336-5r825"`).

**Key:** The format is `asset://` + the asset ID. NOT the full ByteDance URL, NOT the bare ID without prefix.

Regular image URLs will fail with: *"Real-person images are supported, but you must upload them to the Asset Library first."*

**Non-person images** (products, backgrounds, etc.) may work without this step, but when in doubt, use the Asset Library.

## Checklist

- [ ] Prompt is 3-2,500 characters. Be descriptive — Seedance handles complex multimodal prompts well.
- [ ] If using a person image as start frame, upload via **Asset Library** first (see above), then set `first_frame_url`.
- [ ] If using reference images/videos/audio, upload all via KIE file upload (or Asset Library for person images) first.
- [ ] Set `generate_audio: true` if you want speech/sound, `false` for silent.
- [ ] Set `web_search: true` if the prompt references real-world context.
- [ ] Choose resolution based on budget: 480p for drafts/iterations, 720p for finals.
- [ ] For UGC-style content, include imperfection cues in the prompt (see [ugc-selfie-style.md](ugc-selfie-style.md)).

## Template

```text
{{SCENE_DESCRIPTION}}. {{SUBJECT}} in {{SETTING}}.
{{ACTION_AND_MOTION}}. Camera: {{CAMERA}}.
Lighting: {{LIGHTING}}. Style: {{STYLE}}.
{{DIALOGUE_OR_AUDIO_DESCRIPTION}}.
Avoid: {{NEGATIVE}}.
```

## Example — UGC selfie with audio

```text
A selfie video of a young woman in her apartment, holding the phone at
arms length. She speaks directly to camera with enthusiasm: "This app
literally changed my morning routine." She holds up a small green bottle,
tilts it toward camera, then looks back and nods. iPhone front camera,
slightly shaky handheld, warm ambient room light, slightly overexposed
highlights. Casual, authentic, unedited vlog aesthetic.
```

## Example — product showcase with start frame

```text
The scene continues from the starting frame. The woman picks up the
product from the table and turns it to show the label. She runs her
finger along the packaging, then looks back at camera with a satisfied
expression. Soft natural window light, shallow depth of field.
Product clearly visible and in focus throughout.
```

## Example — motion transfer with video reference

Use `reference_video_urls` to provide a motion source and `reference_image_urls` for the character:

```text
The person from the reference images performs the exact movements shown
in the reference video. Same timing, same gestures, same energy.
Indoor studio setting, clean background, even lighting.
```

## Multimodal input guide

| Input type | Field | Max | When to use |
|-----------|-------|-----|-------------|
| **Start frame** | `first_frame_url` | 1 | Precise starting image — video animates from this |
| **End frame** | `last_frame_url` | 1 | Precise ending image — video transitions to this |
| **Reference images** | `reference_image_urls` | 7 | Character/style/product refs for consistency |
| **Reference videos** | `reference_video_urls` | 3 | Motion style, camera movement, pacing refs |
| **Reference audio** | `reference_audio_urls` | 3 | Voice tone, music beat, sound design refs |

**Combining inputs:** You can use first_frame + reference_images + reference_audio all in one call for maximum control. Example: start from a character image, match a reference audio track's beat, and use style reference images.

## curl example

```bash
source .env && KIE_KEY=$(grep '^KIE_API_KEY=' .env | sed 's/^KIE_API_KEY=//') && curl -sS -X POST \
  -H "Authorization: Bearer $KIE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "bytedance/seedance-2",
    "web_search": false,
    "input": {
      "prompt": "A young woman speaks to camera in a casual selfie video...",
      "duration": 8,
      "resolution": "720p",
      "aspect_ratio": "9:16",
      "generate_audio": true
    }
  }' \
  "https://api.kie.ai/api/v1/jobs/createTask"
```
