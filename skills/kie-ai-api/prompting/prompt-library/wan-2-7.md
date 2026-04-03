# Wan 2.7 — image prompts for KIE AI

**KIE endpoint:** `POST /api/v1/jobs/createTask` with `model: "wan/2-7-image"` or `"wan/2-7-image-pro"`.

## Models

| Model | `model` value | Max refs | Max resolution | Best for |
|-------|--------------|----------|---------------|----------|
| **Wan 2.7 Image** | `wan/2-7-image` | 9 images | 2K | General image generation, editing |
| **Wan 2.7 Image Pro** | `wan/2-7-image-pro` | 9 images | 4K | Higher quality, complex scenes |

## Key features

- **Multi-image output:** Generate 1-4 images per call (1-12 with `enable_sequential: true`)
- **Reference images:** Up to 9 input URLs for guided generation
- **Thinking mode:** Enhanced reasoning for complex prompts
- **Color palette:** Custom color themes with hex + ratio definitions
- **Bilingual:** Supports Chinese and English prompts

## Checklist

- [ ] Specify the visual style and subject clearly.
- [ ] Choose the right model: standard for quick iterations, Pro for final quality.
- [ ] Set `n` to control how many variations you get (default: 4).
- [ ] Use `input_urls` for reference-guided generation (style transfer, edits).
- [ ] Consider `thinking_mode: true` for complex multi-element scenes.

## Template

```text
{{SUBJECT}}. Style: {{STYLE}}. Composition: {{COMPOSITION}}. Lighting: {{LIGHT}}. Background: {{BG}}. Details: {{DETAILS}}. Avoid: {{AVOID}}.
```

## curl example

```bash
source .env && KIE_KEY=$(grep '^KIE_API_KEY=' .env | sed 's/^KIE_API_KEY=//') && curl -sS -X POST \
  -H "Authorization: Bearer $KIE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "wan/2-7-image",
    "input": {
      "prompt": "A minimalist product flat lay: matte black earbuds on white marble surface, soft natural window light from the left, subtle shadow, clean composition",
      "aspect_ratio": "1:1",
      "resolution": "2K",
      "n": 2
    }
  }' \
  "https://api.kie.ai/api/v1/jobs/createTask"
```
