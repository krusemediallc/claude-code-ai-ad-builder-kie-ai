---
name: generate-youtube-thumbnail
description: >-
  Generate high-CTR YouTube thumbnails using Nano Banana 2 via the KIE.ai API. Handles public URL reference images, character likeness alignment, proven CTR-tested prompt formulas, and parallel batch generation. Use when the user asks to create a YouTube thumbnail, video thumbnail, A/B test thumbnail variations, or refers to thumbnail design with their face, brand assets, or product photos.
---

# Generate YouTube Thumbnail

A reusable workflow for creating YouTube thumbnails via KIE.ai's Nano Banana 2 image model with proper character likeness and proven CTR formulas.

## When to use this skill

Trigger on phrases like:
- "make me a YouTube thumbnail"
- "create a thumbnail for this video"
- "I need thumbnail variations / A/B tests"
- "remake this thumbnail with my face"
- "generate 10 thumbnail concepts"
- "thumbnail with [me / my product / my brand]"

## Read order

1. **This file** — workflow, decision tree, batch generation
2. **[shared/skills/generate-youtube-thumbnail/prompting/guide.md](../../shared/skills/generate-youtube-thumbnail/prompting/guide.md)** — likeness alignment, expressions cheat sheet, prompt structure (shared across all generative-AI APIs in this portfolio)
3. **[shared/skills/generate-youtube-thumbnail/prompting/formulas.md](../../shared/skills/generate-youtube-thumbnail/prompting/formulas.md)** — 5 proven thumbnail formulas with templates (shared)
4. **[scripts/generate-batch.sh](scripts/generate-batch.sh)** — KIE-specific batch script (URL-based references, jobs endpoint)

## Prerequisites

- `.env` with `KIE_API_KEY`
- Reference images **hosted at PUBLIC URLs** before the batch runs. KIE has no presigned
  upload flow — reference images in `input.image_input` must be reachable URLs (your own
  CDN/bucket, an image host, GitHub raw, etc.). The batch script does NOT upload for you.
- Suggested reference categories (the script reads URLs from arrays you fill in):
  - `face/` — 5+ photos of the subject (headshot + 3/4 angles + close-ups + expressions)
  - `logos/` — brand logos
  - `products/` — clean product shots
  - `examples/` — real ad screenshots, comparison material
  - `style/` — example thumbnails the user wants to match aesthetically

If references are missing or the user pastes images in chat instead of providing URLs,
**stop and ask the user for either (a) public URLs for each reference, or (b) file paths
they can upload to a host themselves.** Chat paste is not a URL.

## Workflow

### 1. Gather requirements (in order)

Ask the user for any missing context, but only what you actually need:

1. **Concept** — what's the video about? Single concept, A/B variations, or specific recreation of an existing thumbnail style?
2. **Subject** — who is in the thumbnail (the user themselves, an AI character, no person)?
3. **Brand assets** — which logos / products / brand colors should appear?
4. **Text** — what should the title text say? Will text be baked in, or added in post (Canva/Photoshop)?
5. **Comparison material** — for "real vs AI" thumbnails, what real ad and what AI-generated ad?

### 2. Verify reference URLs are reachable

```bash
for url in "${REF_URLS[@]}"; do
  curl -I -s -o /dev/null -w "%{http_code} %{url_effective}\n" "$url"
done
```

Each URL must return `200`. If any return 4xx/5xx, ask the user to re-host or share a new URL. **Do not proceed with text-only descriptions for brand-specific items** (logos, branded products, branded apparel) — you'll get generic AI approximations that don't match the brand. Generic descriptions are OK for backgrounds, expressions, and clothing.

### 3. Estimate cost and confirm

Always present cost as an **estimate** before firing:

> "Estimated cost: N variations × {per-image rate from MASTER_CONTEXT.md} = X credits. Confirm exact pricing in [kie.ai/logs](https://kie.ai/logs) after the run."

### 4. Pick a formula

See **[shared/skills/generate-youtube-thumbnail/prompting/formulas.md](../../shared/skills/generate-youtube-thumbnail/prompting/formulas.md)** for the 5 proven formulas. Match the user's intent:

| User says... | Use formula |
|---|---|
| "Just me with my brand" / "branding thumbnail" | **Peace-sign / branding** |
| "Real vs AI" / "compare" / "before/after" | **Real vs AI comparison** |
| "Show the process" / "with the terminal" | **Terminal flow** |
| "Surprised face" / "shocked reaction" | **Reaction shock** |
| "Replace" / "alternative" / "swap out" | **Before/after split** |

### 5. Compose prompts

Follow the template in **[shared/skills/generate-youtube-thumbnail/prompting/guide.md](../../shared/skills/generate-youtube-thumbnail/prompting/guide.md)**:

```
YouTube thumbnail, 16:9 landscape.
[SUBJECT — likeness block + clothing + framing + "no hands" if applicable]
Expression: [specific expression from expressions cheat sheet]
[LEFT visual element + reference]
[RIGHT visual element + reference]
Across the top in massive bold yellow block letters with thick black outline reads [TITLE].
Background: [color + glow]
Style: [aesthetic notes]
Avoid: distorted face, extra fingers, hands visible, blurry logos, generic face
```

**Always include the CRITICAL CHARACTER LIKENESS block** when the subject is a real person. See `shared/skills/generate-youtube-thumbnail/prompting/guide.md`.

### 6. Generate (use the batch script)

Copy `scripts/generate-batch.sh` to a new versioned script (`scripts/generate-thumbnails-vN.sh`) and modify:

1. Update `COMMON_REF_URLS` array with your public reference URLs (one per reference image)
2. Replace the `PROMPTS` array entries with your composed prompts
3. Run with `bash scripts/generate-thumbnails-vN.sh > output/run.log 2>&1 &`
4. Monitor with `tail -F output/run.log | grep -E "DONE|FAILED|Task"`

The script handles:
- Optional local Lanczos upsample (if user supplies local files they plan to host)
- Parallel firing of `POST /api/v1/jobs/createTask` with `model: "nano-banana-2"`
- Retry on failure with backoff
- Polling `GET /api/v1/jobs/recordInfo?taskId=...` until `state: success` or `fail`
- Parsing `data.resultJson` for result URLs and downloading
- Session folder organization under `output/thumbnails-<timestamp>/`

### 7. Review and present

After all generations complete, read each thumbnail with the Read tool and present:

- Brief verdict per thumbnail (likeness, readability, emotional impact)
- Top 3 picks ranked by CTR potential
- Specific reasons for the picks (which expression, which color contrast, which formula)
- Offer next-step refinements (different expression, background color, copy variation)

### 8. Mandatory disclosures

- **Always label credit totals as estimates** and direct the user to [kie.ai/logs](https://kie.ai/logs) for exact charges
- **Cost data:** Record Nano Banana 2 per-image credits in `MASTER_CONTEXT.md` from first-run logs; confirm on the [KIE marketplace page](https://kie.ai/market)
- **Generation time:** typically 20-60 seconds per image on Nano Banana 2
- **Parallel budget:** KIE supports 100+ concurrent tasks with a 20 req/10s rate limit — 10 parallel is comfortable; add stagger/backoff for larger fan-outs

## Quirks and pitfalls

### Reference images must be PUBLIC URLs

KIE does not have a presigned-upload endpoint. Every entry in `input.image_input` is a
URL string that KIE's fetchers must be able to reach. If you use a private bucket, either
generate a temporary signed URL yourself and pass that, or use a public host.

### Image preprocessing

Small or low-quality reference images produce weak likenesses. Before hosting, upsample
with Lanczos to ~1080px longest side and flatten to RGB JPEG. The batch script includes
an optional `prepare_image()` helper if you're hosting from this machine.

### `input.image_input` is an array of plain URL strings

Not objects. Send `["https://.../a.jpg", "https://.../b.jpg"]`. Up to 14 URLs supported
per task.

### Chat-pasted images are NOT URLs

If the user pastes an image directly in chat, you cannot pass it to the API. Ask them to
upload the file to a host and share the URL.

### Likeness drift without enough references

With 1-2 face references the AI generalizes to "generic bearded man with glasses." With
5+ face references from different angles it locks in the specific person. **Always use
5+ face references for character work.**

### macOS bash 3.2

Default macOS bash doesn't support `declare -A` (associative arrays). The batch script
uses indexed arrays and jq / python3 for JSON work.

### Model variants on KIE

KIE offers multiple Nano Banana variants via the jobs endpoint:
- `nano-banana-2` (default — current generation)
- `nano-banana-pro` (Gemini 3 Pro backbone, higher fidelity)
- `nano-banana` (legacy)
- `nano-banana-edit` (edit-focused)

The batch script defaults to `nano-banana-2` and exposes `MODEL` as an env override so
you can swap to `nano-banana-pro` for higher-stakes hero shots.

### Brand-specific items need real reference URLs

Text descriptions of brand-specific items (logos, branded apparel, custom merchandise)
will produce generic approximations. For pixel-accurate brand reproduction, host the
actual brand asset on a public URL and pass it as a reference.

## Cost reference

Record per-call credit costs in `MASTER_CONTEXT.md` after the first real run by checking
[kie.ai/logs](https://kie.ai/logs). Typical patterns:

| Operation | Notes |
|---|---|
| Nano Banana 2 image (1 generation) | Confirm credits in kie.ai/logs |
| 6-variation batch | Typical for first explorations |
| 10-variation batch | Typical for refinements |
| 20-variation batch | Typical for broad concept exploration |

Always present as estimates, confirm exact in [kie.ai/logs](https://kie.ai/logs).

## See also

- **[shared/skills/generate-youtube-thumbnail/prompting/guide.md](../../shared/skills/generate-youtube-thumbnail/prompting/guide.md)** — likeness alignment, expressions, prompt structure (shared across APIs)
- **[shared/skills/generate-youtube-thumbnail/prompting/formulas.md](../../shared/skills/generate-youtube-thumbnail/prompting/formulas.md)** — 5 proven CTR formulas with prompt templates (shared)
- **[scripts/generate-batch.sh](scripts/generate-batch.sh)** — KIE-specific bash batch generator (URL refs, jobs endpoint)
- **[kie-external-api skill](../kie-external-api/SKILL.md)** — underlying API reference for Nano Banana 2 and the KIE jobs endpoint
