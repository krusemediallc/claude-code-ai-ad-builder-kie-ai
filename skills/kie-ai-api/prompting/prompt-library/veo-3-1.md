# Veo 3.1 — prompts for KIE AI

**KIE endpoint:** `POST /api/v1/veo/generate`
**Vendor guide:** [Google Cloud — Ultimate prompting guide for Veo 3.1](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-veo-3-1)

## Models

- `veo3` — higher quality, slower
- `veo3_fast` — faster generation (default)
- `veo3_lite` — lightweight

## Checklist

- [ ] Describe scene, action, and **how the shot evolves** over time (first frame → later beats).
- [ ] Specify **style** (film stock, animation, documentary, etc.) if it matters.
- [ ] If using **imageUrls**, upload images first via KIE file upload and use the `downloadUrl` values. 1 image = start frame, 2 images = transition.
- [ ] **ALWAYS** end the prompt with `"No subtitles, no captions, no text overlays."` — Veo 3.1 sometimes burns subtitles into the video if not explicitly excluded.

## Template

```text
{{OPENING_BEAT}}. {{ACTION_OVER_TIME}}. Setting: {{SETTING}}. Camera: {{CAMERA}}. Style: {{STYLE}}. Lighting: {{LIGHT}}. Optional dialogue: {{DIALOGUE}}.
```

## Example

```text
Wide shot of a city rooftop at golden hour; runner ties shoes, then jogs toward camera as the camera tracks sideways. Documentary handheld feel, warm natural light, subtle film grain. No logos on clothing. No subtitles, no captions, no text overlays.
```

## Required JSON fields (KIE)

`prompt` — see [reference.md](../../reference.md) for optional fields (`model`, `aspect_ratio`, `imageUrls`, `generationType`).

## curl example

```bash
source .env && curl -sS -X POST \
  -H "Authorization: Bearer $KIE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "...",
    "model": "veo3_fast",
    "aspect_ratio": "16:9"
  }' \
  "https://api.kie.ai/api/v1/veo/generate"
```
