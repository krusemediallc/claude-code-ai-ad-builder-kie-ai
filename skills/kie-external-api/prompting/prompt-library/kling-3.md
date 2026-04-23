# Kling 3.0 — prompts for KIE.ai

**Vendor guide:** [Kling — video model user guide](https://kling.ai/quickstart/klingai-video-3-model-user-guide)

## KIE API note

Kling runs through the generic jobs route on KIE: `POST /api/v1/jobs/createTask` with a Kling model string (e.g. `kling-3`). Reference images, if used, go in `input.image_input` as **hosted URLs** — no base64, no file uploads.

## Checklist (from Kling guide habits)

- [ ] Subject, environment, and **motion path** described clearly.
- [ ] Separate **style** vs **content** when the guide recommends it.
- [ ] If using a reference or starting frame, say how the motion should treat it.

## Template

```text
{{SUBJECT}}. {{ACTION_MOTION}}. Environment: {{ENV}}. Camera: {{CAM}}. Mood: {{MOOD}}. Avoid: {{NEGATIVE}}.
```

## Example

```text
Coffee pours in slow motion into a ceramic mug on a wooden counter, steam rising. Soft window light, shallow depth of field, calm ASMR pacing. No text overlays.
```

## Typical KIE body

```json
{
  "model": "kling-3",
  "input": {
    "prompt": "...",
    "image_input": ["https://cdn.example.com/start-frame.jpg"],
    "aspect_ratio": "9:16"
  }
}
```

See [reference.md](../../reference.md) for the full field list and the currently supported Kling model strings. Poll with `GET /api/v1/jobs/recordInfo?taskId={id}` — `state: success` means the job is done and `data.resultJson` (JSON-encoded string) holds the final URLs.
