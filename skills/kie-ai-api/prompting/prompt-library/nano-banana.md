# Nano Banana — prompts for KIE AI

**Vendor guide:** [Google Cloud — Ultimate prompting guide for Nano Banana](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-nano-banana)

## KIE API endpoint

**Image generation:** `POST /api/v1/jobs/createTask` with the appropriate `model` field.

This is the Nano Banana route for still-image generation. Use it for:
- Influencer recreation stills (see [influencer-recreation.md](influencer-recreation.md))
- Product showcase starting frames (see [product-showcase.md](product-showcase.md))
- Standalone Nano Banana images (product heroes, lifestyle shots, etc.)
- Character sheet generation (see [character-sheet.md](character-sheet.md))

Poll with `GET /api/v1/jobs/recordInfo?taskId=` until `state` is `success`.

## Model selection

| User-facing name | API `model` value | Reference images | Max prompt |
|------------------|-------------------|-----------------|------------|
| **Nano Banana 2** (default) | `nano-banana-2` | Up to 14 via `input.image_input` | 20,000 chars |
| **Nano Banana Pro** | `google/nano-banana` | Not supported | 5,000 chars |

**Agent behavior:** Default to `nano-banana-2`. Before the first image call in a session, ask once: *"Use default Nano Banana 2, or Nano Banana Pro?"* If they don't care, use `nano-banana-2`.

## Request body — Nano Banana 2

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `nano-banana-2` |
| `input.prompt` | string | Yes | Follow template and checklist below |
| `input.image_input` | string[] | No | Up to 14 reference image URLs (JPEG/PNG/WebP, max 30MB each) |
| `input.aspect_ratio` | string | No | `1:1`, `9:16`, `16:9`, `3:4`, `4:3`, `auto` (default: auto) |
| `input.resolution` | string | No | `1K`, `2K`, `4K` (default: 1K) |
| `input.output_format` | string | No | `png`, `jpg` (default: jpg) |
| `callBackUrl` | string | No | Webhook URL |

## Request body — Nano Banana Pro

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | Yes | `google/nano-banana` |
| `input.prompt` | string | Yes | Max 5,000 chars |
| `input.image_size` | string | No | Same aspect ratio options (default: 1:1) |
| `input.output_format` | string | No | `png`, `jpeg` (default: png) |
| `callBackUrl` | string | No | Webhook URL |

**Note:** NB Pro uses `image_size` (not `aspect_ratio`) and `jpeg` (not `jpg`).

## Checklist

- [ ] Follow the vendor guide for framing **subject**, **style**, and **constraints**.
- [ ] State whether the output should be **photoreal**, **illustration**, **product hero**, etc.
- [ ] Call out **text on image** only if the pipeline supports legible text for your use case.
- [ ] After `state: success`, run **post-generation QA** (see below) before treating the image as final.

### Post-generation QA (mandatory)

After downloading or viewing the result, check for:

- Extra or missing **hands** or **fingers**; wrong finger count; fused or blurred digits
- Wrong number of **limbs**; duplicated or missing arms/legs; impossible joints or poses
- **Face:** duplicate or merged features, asymmetry beyond natural range, distorted eyes or teeth
- **Objects:** merged geometry, floating items, melted product edges
- **Artifacts:** obvious seams, texture soup, stray body parts at frame edges

If anything looks off, follow **Regeneration loop**.

### Regeneration loop

1. **Inspect** the image from the result URL.
2. If **defective:** compose a **new prompt** that names the fix (e.g. "exactly two hands visible, five fingers each"). Keep the rest of the creative intent.
3. Call `POST /api/v1/jobs/createTask` again with same parameters but revised prompt.
4. **Cap:** at most **2** regeneration attempts after the first (**3** total). After that, describe remaining issues and ask the user.
5. **Credits:** each generation bills separately.

## Template

```text
{{SUBJECT}}. Style: {{STYLE}}. Composition: {{COMPOSITION}}. Lighting: {{LIGHT}}. Background: {{BG}}. Avoid: {{AVOID}}.
```

## Example

```text
Minimal product hero: matte black earbuds on concrete, soft studio three-point lighting, subtle reflection, no people, no extra props.
```

## curl example

```bash
source .env && curl -sS -X POST \
  -H "Authorization: Bearer $KIE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nano-banana-2",
    "input": {
      "prompt": "Minimal product hero: matte black earbuds on concrete, soft studio three-point lighting, subtle reflection, no people, no extra props.",
      "aspect_ratio": "1:1",
      "resolution": "1K"
    }
  }' \
  "https://api.kie.ai/api/v1/jobs/createTask"
```
