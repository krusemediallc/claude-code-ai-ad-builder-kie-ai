# Nano Banana — prompts for KIE.ai

**Vendor guide:** [Google Cloud — Ultimate prompting guide for Nano Banana](https://cloud.google.com/blog/products/ai-machine-learning/ultimate-prompting-guide-for-nano-banana)

## KIE API endpoint

**Image generation:** `POST /api/v1/jobs/createTask` with a Nano Banana `model` value.

Use this route for:
- Influencer recreation stills (see [influencer-recreation.md](influencer-recreation.md))
- Product showcase starting frames (see [product-showcase.md](product-showcase.md))
- Standalone Nano Banana images (product heroes, lifestyle shots, etc.)

Poll with `GET /api/v1/jobs/recordInfo?taskId={id}` until `state` is `success`. Final image URLs come back as a JSON-encoded string in `data.resultJson` (parse it to get the `resultUrls` array).

## Model selection (`model` field on `POST /api/v1/jobs/createTask`)

KIE exposes multiple Nano Banana model strings — pick the one that matches intent:

| User-facing name | API `model` value | When to use |
|------------------|-------------------|-------------|
| **Nano Banana 2** (default) | `nano-banana-2` | Use unless the user asks for Pro or a legacy behavior. |
| **Nano Banana Pro** | `nano-banana-pro` | Real Pro tier, runs on Gemini 3. Use when the user explicitly asks for Pro. |
| Nano Banana (legacy) | `nano-banana` | Only when the user specifically wants the first-gen engine. |
| Nano Banana Edit | `nano-banana-edit` | Edit an existing hosted image rather than generating from scratch. |

**Agent behavior:** Default to `nano-banana-2`. Before the first image call in a session, ask once: *"Use default Nano Banana 2, or Nano Banana Pro?"* If they don't care, use `nano-banana-2`.

**Credits:** Pricing differs per model — read `data.creditsCharged` (or the equivalent consumption field) off the job record and cross-reference the user's cost table in `MASTER_CONTEXT.md`.

## Request body (KIE jobs) — confirmed 2026-04-20

See [reference.md](../../reference.md) for the full schema. Key fields:

- `model` (required) — e.g. `nano-banana-2` (default) or `nano-banana-pro`
- `input` (required object) — snake_case fields inside:
  - `prompt` (required) — follow the template and checklist below
  - `image_input` (optional) — array of **hosted image URLs** (up to 14) used as references. KIE does **not** accept base64 or uploaded file paths — host the image somewhere publicly reachable (any CDN / signed URL that resolves over HTTPS) and pass the URL.
  - `aspect_ratio` (optional) — `1:1`, `1:4`, `1:8`, `2:3`, `3:2`, `3:4`, `4:1`, `4:3`, `4:5`, `5:4`, `8:1`, `9:16`, `16:9`, `21:9`, `auto` (default `auto`)
  - `resolution` (optional) — `1K` / `2K` / `4K`
  - `output_format` (optional) — e.g. `png`, `jpeg`

**Generation time:** ~35 seconds typical for Nano Banana images (varies).

## Checklist

- [ ] Follow the vendor guide for framing **subject**, **style**, and **constraints**.
- [ ] State whether the output should be **photoreal**, **illustration**, **product hero**, etc.
- [ ] Call out **text on image** only if the pipeline supports legible text for your use case.
- [ ] Use `POST /api/v1/jobs/createTask` with the right `model` string.
- [ ] After `state: success`, run **post-generation QA** (see below) before treating the image as final.

### Post-generation QA (mandatory)

After downloading or viewing the result, check for:

- Extra or missing **hands** or **fingers**; wrong finger count; fused or blurred digits
- Wrong number of **limbs**; duplicated or missing arms/legs; impossible **joints** or poses
- **Face:** duplicate or merged features, asymmetry beyond natural range, distorted eyes or teeth
- **Objects:** merged geometry, floating items, melted product edges (product shots)
- **Artifacts:** obvious seams, texture soup, stray body parts at frame edges

If anything looks off, follow **Regeneration loop** — do not pass a defective still to the user as the only option without at least one retry (unless the user explicitly waives QA).

### Regeneration loop

1. **Inspect** the image from the URL parsed out of `data.resultJson` (or a local download).
2. If **defective:** compose a **new prompt** that names the fix (e.g. "exactly two hands visible, five fingers each," "single coherent face," "product label sharp and readable"). Keep the rest of the creative intent; add corrective constraints rather than resending the exact same JSON.
3. Call `POST /api/v1/jobs/createTask` again with the same `model`, `input.aspect_ratio`, `input.resolution`, and `input.image_input` as before unless you are intentionally changing them.
4. **Cap:** at most **2** regeneration attempts after the first image (**3** total generations per deliverable). After that, describe remaining issues, list result URLs, and ask the user how to proceed.
5. **Credits:** each generation bills separately — note cumulative credits when reporting. QA retries use the [QA-fix exception](../../SKILL.md) (no second pre-confirmation, but still billed).

Full agent steps: [SKILL.md — Generated image QA](../../SKILL.md#generated-image-qa-mandatory).

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
      "resolution": "2K",
      "output_format": "png"
    }
  }' \
  "https://api.kie.ai/api/v1/jobs/createTask"
```
