# Veo 3.1 — prompts for KIE.ai

**KIE route:** `POST /api/v1/veo/generate`.
**Vendor guide:** [Google Cloud — Ultimate prompting guide for Veo 3.1](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-veo-3-1)

## Checklist

- [ ] Describe scene, action, and **how the shot evolves** over time (first frame → later beats).
- [ ] Specify **style** (film stock, animation, documentary, etc.) if it matters.
- [ ] If anchoring the generation to reference images, pick the right `generationType` (see below) and pass hosted URLs via `imageUrls`.
- [ ] **ALWAYS** end the prompt with `"No subtitles, no captions, no text overlays."` — Veo 3.1 sometimes burns subtitles into the video if not explicitly excluded.

## Template

```text
{{OPENING_BEAT}}. {{ACTION_OVER_TIME}}. Setting: {{SETTING}}. Camera: {{CAMERA}}. Style: {{STYLE}}. Lighting: {{LIGHT}}. Optional dialogue: {{DIALOGUE}}.
```

## Example

```text
Wide shot of a city rooftop at golden hour; runner ties shoes, then jogs toward camera as the camera tracks sideways. Documentary handheld feel, warm natural light, subtle film grain. No logos on clothing. No subtitles, no captions, no text overlays.
```

## generationType — the KIE way to anchor on images

KIE's Veo route anchors an image-driven generation with a single `generationType` switch plus an `imageUrls` array of **hosted URLs**. KIE fetches the reference over HTTP — host the file somewhere publicly reachable and pass the URL. Base64 and file uploads are not supported.

| `generationType` | `imageUrls` | Effect | Notes |
|------------------|-------------|--------|-------|
| `TEXT_2_VIDEO` | omit | Text-only generation | Default when no image context is needed. |
| `REFERENCE_2_VIDEO` | 1 URL | Video unfolds around the reference image | Only works with the `veo3_fast` model. |
| `FIRST_AND_LAST_FRAMES_2_VIDEO` | 2 URLs `[start, end]` | Video interpolates from first URL to second URL | Use for scripted opening/closing beats. |

## Required JSON fields (KIE Veo)

```json
{
  "model": "veo3_fast",
  "prompt": "...",
  "generationType": "FIRST_AND_LAST_FRAMES_2_VIDEO",
  "imageUrls": ["https://...start.jpg", "https://...end.jpg"],
  "aspect_ratio": "9:16",
  "resolution": "720p"
}
```

- `model` — Veo variant (e.g. `veo3_fast`, `veo3`).
- `prompt` — required.
- `generationType` — see table above.
- `imageUrls` — hosted URL array; required when `generationType` is image-based.
- `aspect_ratio` (snake_case) — e.g. `9:16`, `16:9`, `1:1`.
- `resolution` (snake_case) — `720p`, `1080p`, or `4k`.

Poll with `GET /api/v1/veo/record-info?taskId={id}`. Watch `successFlag` (0 generating, 1 success, 2/3 failed). Final video URLs arrive as a JSON-encoded string in `data.info.resultUrls`.
