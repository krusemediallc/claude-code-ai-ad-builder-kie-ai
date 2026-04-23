# Sora 2 — prompts for KIE.ai

**KIE route:** `POST /api/v1/jobs/createTask` with a Sora 2 `model` string.
**Vendor guide (read for craft):** [OpenAI — Sora 2 prompting guide](https://developers.openai.com/cookbook/examples/sora/sora2_prompting_guide)

## Model strings

| Use case | `model` |
|----------|---------|
| Text → video (default) | `sora-2-text-to-video` |
| Text → video, Pro tier | `sora-2-pro-text-to-video` |
| Image → video (starting frame) | `sora-2-image-to-video` |

KIE does **not** expose a dedicated Sora 2 "remix" endpoint. When you want to continue from an existing frame, use `sora-2-image-to-video` and pass the source image as a hosted URL in `input.image_input` — treat it as the starting frame.

## Checklist (after reading the vendor guide)

- [ ] Clear subject and setting; camera behavior described (not just "cinematic").
- [ ] Motion: what moves, what stays stable across the clip.
- [ ] Lighting and style named explicitly if important.
- [ ] If anchoring on an image, describe how the motion should relate to that starting frame.

## Template

```text
{{HOOK_OPEN}}. {{SUBJECT}} in {{SETTING}}. Camera: {{CAMERA_MOVE}}. Lighting: {{LIGHTING}}. Style: {{STYLE}}. Audio mood: {{AUDIO_MOOD}}. End on {{ENDING_IMAGE}}.
```

## Example

```text
A skincare founder holds the bottle to camera in a bright bathroom, morning light through blinds. Slow push-in, shallow depth of field. Warm, trustworthy, no medical claims. Soft upbeat ambient. End on product and smile.
```

## Required JSON fields (KIE jobs)

```json
{
  "model": "sora-2-text-to-video",
  "input": {
    "prompt": "...",
    "aspect_ratio": "9:16",
    "resolution": "720p"
  }
}
```

For `sora-2-image-to-video`, add a hosted URL:

```json
{
  "model": "sora-2-image-to-video",
  "input": {
    "prompt": "...",
    "image_input": ["https://cdn.example.com/start-frame.jpg"],
    "aspect_ratio": "9:16"
  }
}
```

- `image_input` takes an array of hosted URLs. KIE fetches them over HTTP — base64 and file uploads are not supported.
- `aspect_ratio` / `resolution` go inside `input` (snake_case).
- Duration is controlled by model variant and prompt pacing — see [reference.md](../../reference.md) for current limits.

Poll with `GET /api/v1/jobs/recordInfo?taskId={id}`. Watch `state` (`waiting | queuing | generating | success | fail`). Result URLs arrive as a JSON-encoded string in `data.resultJson`.
