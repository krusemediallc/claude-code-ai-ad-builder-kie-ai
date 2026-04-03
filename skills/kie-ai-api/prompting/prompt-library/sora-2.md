# Sora 2 — prompts for KIE AI

**KIE endpoint:** `POST /api/v1/jobs/createTask` with `model: "sora-2-text-to-video"` or `"sora-2-image-to-video"`.
**Pro variants:** `"sora-2-pro-text-to-video"`, `"sora-2-pro-image-to-video"`.
**Vendor guide (read for craft):** [OpenAI — Sora 2 prompting guide](https://developers.openai.com/cookbook/examples/sora/sora2_prompting_guide)

## Checklist (after reading the vendor guide)

- [ ] Clear subject and setting; camera behavior described (not just "cinematic").
- [ ] Motion: what moves, what stays stable across the clip.
- [ ] Lighting and style named explicitly if important.
- [ ] If using `image_urls` (image-to-video), describe how motion should relate to the reference.
- [ ] For image-to-video, upload the image first and use the URL in `input.image_urls`.

## Template

```text
{{HOOK_OPEN}}. {{SUBJECT}} in {{SETTING}}. Camera: {{CAMERA_MOVE}}. Lighting: {{LIGHTING}}. Style: {{STYLE}}. Audio mood: {{AUDIO_MOOD}}. End on {{ENDING_IMAGE}}.
```

## Example

```text
A skincare founder holds the bottle to camera in a bright bathroom, morning light through blinds. Slow push-in, shallow depth of field. Warm, trustworthy, no medical claims. Soft upbeat ambient. End on product and smile.
```

## Required JSON fields (KIE)

`model`, `input.prompt`, `input.upload_method` ("s3") — see [reference.md](../../reference.md) for full schema.

## curl example

```bash
source .env && curl -sS -X POST \
  -H "Authorization: Bearer $KIE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sora-2-text-to-video",
    "input": {
      "prompt": "...",
      "aspect_ratio": "landscape",
      "n_frames": "10",
      "upload_method": "s3"
    }
  }' \
  "https://api.kie.ai/api/v1/jobs/createTask"
```
