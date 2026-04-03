# Runway — prompts for KIE AI

**KIE endpoint:** `POST /api/v1/runway/generate`
**Extend:** `POST /api/v1/runway/extend`

## Features

- **Duration:** 5 or 10 seconds (10s limited to 720p)
- **Quality:** 720p or 1080p (1080p limited to 5s)
- **Aspect ratios:** 16:9, 9:16, 1:1, 4:3, 3:4
- **Image-to-video:** Provide `imageUrl` to animate a reference image
- **No speech** — Runway generates silent video only

## Checklist

- [ ] Clear subject, setting, and motion described.
- [ ] `aspectRatio` required for text-only generation.
- [ ] For image-to-video, upload the image first and use the URL in `imageUrl`.
- [ ] Keep prompts under 1800 characters.
- [ ] Choose quality/duration combo: 1080p+5s or 720p+5s/10s.

## Template

```text
{{SUBJECT}} in {{SETTING}}. {{MOTION_DESCRIPTION}}. Camera: {{CAMERA}}. Lighting: {{LIGHTING}}. Style: {{STYLE}}. Avoid: {{NEGATIVE}}.
```

## Example

```text
A woman walks through a sunlit flower market, trailing her hand across arrangements. Camera follows at waist height, shallow depth of field. Warm natural light, slight film grain, lifestyle editorial feel. No text overlays.
```

## curl example

```bash
source .env && curl -sS -X POST \
  -H "Authorization: Bearer $KIE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "...",
    "duration": 5,
    "quality": "1080p",
    "aspectRatio": "16:9"
  }' \
  "https://api.kie.ai/api/v1/runway/generate"
```
