# Kling 3.0 — prompts for KIE AI

**KIE endpoint:** `POST /api/v1/jobs/createTask` with `model: "kling-3.0/video"`.
**Vendor guide:** [Kling — video model user guide](https://kling.ai/quickstart/klingai-video-3-model-user-guide)

## Models

| Model | `model` value | Use case |
|-------|--------------|----------|
| **Kling 3.0 Video** | `kling-3.0/video` | Text-to-video, image-to-video, multi-shot |
| **Kling 3.0 Motion Control** | `kling-3.0/motion-control` | Transfer motion from a reference video onto a character image |

## Features (Kling 3.0 Video)

- **Duration:** 3-15 seconds (flexible per-second control)
- **Multi-shot mode:** Storyboard multiple shots with individual prompts and durations
- **Elements:** Attach up to 3 character/object elements with reference images (2-4 per element)
- **Sound:** Optional sound effects with `sound: true`
- **Resolution:** `std` (720p) or `pro` (1080p)

## Motion Control

Use `kling-3.0/motion-control` to transfer motion from a reference video onto a character from a reference image. Requires both `input_urls` (image) and `video_urls` (motion source).

- `character_orientation`: `video` (character faces video direction) or `image` (keeps image orientation)
- `background_source`: `input_video` or `input_image`
- `mode`: `std` (720p) or `pro` (1080p)
- Image: JPEG/PNG, max 10MB, >340px
- Video: MP4/QuickTime, 3-30s, max 100MB

## Checklist (from Kling guide habits)

- [ ] Subject, environment, and **motion path** described clearly.
- [ ] Separate **style** vs **content** when the guide recommends it.
- [ ] If using `image_urls` for first/last frame, describe how motion should treat them.
- [ ] Consider multi-shot mode for complex narratives (each shot 1-12s).

## Template

```text
{{SUBJECT}}. {{ACTION_MOTION}}. Environment: {{ENV}}. Camera: {{CAM}}. Mood: {{MOOD}}. Avoid: {{NEGATIVE}}.
```

## Example

```text
Coffee pours in slow motion into a ceramic mug on a wooden counter, steam rising. Soft window light, shallow depth of field, calm ASMR pacing. No text overlays.
```

## curl example

```bash
source .env && curl -sS -X POST \
  -H "Authorization: Bearer $KIE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "kling-3.0/video",
    "input": {
      "prompt": "...",
      "duration": "5",
      "aspect_ratio": "16:9",
      "mode": "pro"
    }
  }' \
  "https://api.kie.ai/api/v1/jobs/createTask"
```
