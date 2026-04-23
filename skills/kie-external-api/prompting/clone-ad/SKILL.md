---
name: clone-ad
description: >
  Clone an existing video ad for a different product or offer. Analyzes the source
  video's style, pacing, camera work, dialogue, and tone, then adapts and generates
  a new Seedance 2 video customized for the user's product. End-to-end workflow:
  input video → analysis → adapted prompt → generation → delivery. Use when someone
  says "clone this ad", "make this ad but for my product", "recreate this video for
  my brand", or provides a video ad and a product image asking for a similar video.
---

# Clone ad — Seedance 2

Clone an existing video ad for a different product or offer. The agent analyzes the
source video frame-by-frame, transcribes dialogue, extracts the visual style and
beat structure, then generates a new Seedance 2 video (via KIE.ai) adapted for the user's product.

**How this differs from analyze-video:**
- **analyze-video** → output is a **reusable markdown template** saved to `prompt-library/`
- **clone-ad** → output is a **generated Seedance 2 video** delivered to the user

## Prerequisites

Before starting, verify:

```bash
which ffmpeg || echo "MISSING — run: brew install ffmpeg"
python3 -c "import whisper; print('whisper OK')" 2>/dev/null || echo "MISSING — run: pip3 install openai-whisper"
```

Both `extract-frames.sh` and whisper depend on ffmpeg. If missing, install via `brew install ffmpeg` before proceeding.

> **Verify the exact Seedance model string on the [KIE marketplace page](https://kie.ai/market).**
> The likely value is `seedance-2`. Record the confirmed string in `MASTER_CONTEXT.md`.

## Workflow

### Step 0: Gather inputs

Collect from the user:

| Input | Required | Notes |
|-------|----------|-------|
| **Source video** | yes | The video ad to clone. File path to `.mp4`, `.mov`, `.webm` |
| **Product image URL** | recommended | PUBLIC URL of the user's product photo. Becomes `input.image_input[0]` and `@(img1)` in the prompt. KIE requires a reachable URL — no presigned upload flow. Without an image, Seedance invents its own product design. |
| **Product/offer description** | if no image | Text description of the product, its features, target audience, and key selling points. Used to rewrite dialogue and product references. |
| **Brand voice** | optional | Check `MASTER_CONTEXT.md` for brand blocks. If empty, ask the user for tone/audience preferences. |

If the user only provides a video and says "clone this for my product," ask them for
at least a product image URL or a text description before proceeding. **Chat-pasted
images do not count — KIE needs a real public URL.**

### Step 1: Extract frames and audio

Reuse the analyze-video extraction script — do NOT duplicate it.

```bash
bash "skills/kie-external-api/prompting/analyze-video/scripts/extract-frames.sh" \
  "<source_video_path>" "/tmp/clone-ad-analysis" <num_frames>
```

**Frame count by duration:**

| Source duration | Frames |
|-----------------|--------|
| Under 10s | 8 |
| 10–20s | 12 |
| 20–30s | 16 |
| Over 30s | 20 |

**Outputs:**
- `frame_001.jpg` through `frame_NNN.jpg`
- `audio.wav` (16 kHz mono, whisper-ready)
- `metadata.txt` (duration, resolution, fps, frame count)

Read `metadata.txt` to get the source video duration — you'll need it for step 6.

### Step 2: Transcribe audio

Use whisper to get the exact dialogue. This is critical — the dialogue pattern is what
gets adapted for the user's product.

```python
import whisper
model = whisper.load_model("base")
result = model.transcribe("/tmp/clone-ad-analysis/audio.wav")
```

Record:
- Full transcript text
- Per-segment timestamps and text (`result["segments"]`)
- Total word count
- Language detected

If the video is **silent** (no speech detected), note that and skip the dialogue
adaptation in step 7. The clone will be a visual-style clone only.

### Step 3: Compressed analysis

Read **ALL** extracted frames visually. For each frame, note:

**Structure and pacing:**
- How many distinct beats/shots are there?
- What's the narrative arc? (hook → demo → verdict? reveal → detail → CTA?)
- How long does each beat last? (map to segment timestamps)

**Camera and framing:**
- POV style: selfie/handheld, tripod, propped phone, over-the-shoulder?
- Framing per beat: wide, medium, close-up, macro?
- Camera movement: static, pan, dolly, handheld shake?
- Signature framing moves (e.g., "leans into camera," "tilts product toward lens")

**Edit style:**
- Transition type: jump cuts, dissolves, match cuts?
- Visual rhythm: fast cuts vs held shots?
- Any recurring motif (e.g., "every other beat is an extreme close-up")?

**Dialogue and script structure:**
- Hook format: question, statement, exclamation, reaction?
- Speech pattern: casual/formal, filler words, trailing thoughts, mid-sentence cuts?
- How many spoken lines? How many silent beats?
- CTA style: direct ("link in bio"), soft ("you need to try this"), none?

**Tone and energy:**
- Emotion words that describe the speaker/mood
- Energy arc: starts calm → builds excitement? Flat? Burst then settle?
- Speaker's relationship to viewer: friend, expert, skeptic, fan?

**Lighting and technical quality:**
- Light source: natural/artificial, direction, quality
- Camera quality: phone/DSLR/cinema, intentional flaws?
- Audio quality: phone mic, studio, car, outdoor?

**Product references:**
- How is the product physically shown? (held up, worn, applied, on a surface)
- What specific claims or features are called out?
- Brand mentions, labels visible, text overlays?

**What makes this ad distinctive (2–3 defining traits):**
- The unique combination of elements that makes this ad recognizable
- These are the traits that MUST transfer to the clone

Store this analysis internally — it does NOT get saved as a template file.

### Step 4: Present analysis summary

Show the user a structured breakdown before proceeding:

```
Source video analysis

Duration: Xs | Beats: N | Dialogue: Y words | Style: [style name]

Beat map:
  [00:00–00:03]  HOOK — close-up, excited expression, "opening line"
  [00:03–00:07]  SHOW — tilts product to camera, "feature call-out"
  [00:07–00:10]  DEMO — (silent) applies/uses product, close-up on texture
  [00:10–00:15]  VERDICT — back to camera, "closing line + CTA"

Defining traits:
  1. [trait 1]
  2. [trait 2]
  3. [trait 3]

What transfers to your product:
  - Beat structure, pacing, camera angles, edit style, tone, energy
  - Dialogue pattern (adapted for your product)
  - Lighting and technical quality cues

What gets swapped:
  - Product references → your product
  - Specific claims → your product's features
  - Brand mentions → your brand (if provided)

Proceed with adaptation? (yes / adjust)
```

Wait for user confirmation before continuing.

### Step 5: Decide generation mode

Walk through this decision tree:

```
┌─ Source video ≤ 15s?
│   YES → Single-clip generation
│   NO  → Multi-clip split at natural beat boundaries
│         Each clip ≤ 15s (Seedance max)
│         Identify best split points from beat map
│         Use the CHAINED MULTI-CLIP PIPELINE below
│
├─ User provided a product IMAGE URL?
│   YES → Image-to-video mode (image URL in input.image_input; @(img1) in prompt)
│         For multi-clip: use the product URL on clip 1; for clips 2+, use the
│         previous clip's output frame or a re-upload (see chaining notes below).
│   NO  → Text-only mode (describe product in prompt text only; input.image_input omitted)
│
├─ Source video has person SPEAKING?
│   YES → Include dialogue in prompt text.
│         Dialogue confirmation gate REQUIRED (step 7)
│   NO  → Skip dialogue; visual-only prompt
│         Skip dialogue gate
│
└─ User wants voice clone from source audio?
    → On KIE's Seedance, native reference-audio support is unverified.
      Verify on the KIE marketplace page. If unavailable, note the limitation
      and proceed with text-driven dialogue only.
```

### Chained multi-clip pipeline

When the source ad is longer than 15s, use this sequential pipeline for visual continuity:

```
Clip 1: image-to-video mode
  - input.image_input: ["https://.../product.jpg"]  ← establishes brand fidelity
  - Generate → poll → download output

Clip 2+: continuity mode
  - Option A (preferred): host the final frame of clip N as a public URL and pass
    it in input.image_input for clip N+1 to inherit hands/surface/lighting/product.
  - Option B: re-use the original product URL and lean on consistency anchors in
    the prompt ("The product from @(img1) must remain visually unchanged").
  - Generate → poll → download output

...continue for clips 3+
```

**Critical rules for chaining:**
1. **Always chain from the most recent clip.** Extract clip N's last frame with
   `ffmpeg -sseof -0.1 -i clipN.mp4 -vframes 1 clipN_last.jpg`, upload to your
   host, and pass the URL to clip N+1.
2. **Wait for each clip to reach `state: success`** before starting the next.
   Clips are sequential for continuity — do not fire in parallel.
3. **Hosted URLs must stay reachable** until generation completes. If using a
   temporary bucket, confirm expiry windows are longer than the job duration.
4. After all clips are generated, **stitch with ffmpeg**:
   `ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4`
   (use absolute paths in the list file).

**Why chaining works:** Seedance-style continuity comes from carrying visual
information (product, hands, surface, lighting) from clip N into clip N+1 via a
reference image. The first clip's product URL establishes product identity; each
subsequent clip's "last-frame-as-reference" propagates it through the series.

**Cost note:** Confirm per-second rates on the [KIE marketplace page](https://kie.ai/market)
and record them in `MASTER_CONTEXT.md`. Log every job to `logs/kie-api.jsonl` so rates
can be empirically verified from real runs.

**Important constraints to check:**
- KIE marketplace models use PUBLIC URLs in `input.image_input` — no file uploads.
- Up to 14 image URLs supported per job.
- Reference-video and reference-audio support on KIE's Seedance: verify on the
  marketplace page before planning around them. If unsupported, plan for
  image-reference + text-prompt workflows only.
- Content moderation: KIE runs its own safety checks. If a job fails moderation,
  credits may still be charged — rewrite the prompt rather than retrying the same
  payload.

Tell the user which mode you're using and why.

### Step 6: Adapt for user's product

This is the creative core. Using the analysis from step 3:

**Dialogue adaptation (if source has speech):**
- Keep the **same conversational pattern**: if the source uses a question hook, use a question hook. If it uses filler words ("like," "okay so"), keep filler words.
- Keep the **same number of spoken lines** and **same silent beat placement**
- Keep the **same energy arc** (excited → calm, or flat, or building)
- Replace **product-specific references** with the user's product name, features, and claims
- Match the **word count** of each line closely (±3 words per beat) to preserve pacing
- Read the adapted dialogue out loud at natural pace — it must fit the target duration

**Visual adaptation:**
- Keep the analyzed camera work, framing per beat, and edit style
- Replace the product description with the user's product (physical appearance, colors, materials, label details)
- Keep the setting, lighting, and atmosphere
- Keep the person description (or adapt if user specifies a different persona)
- Keep the technical flaw cues (phone quality, mic type, lighting imperfections)

**Prompt composition:**
- Read [seedance-2.md](../prompt-library/seedance-2.md) for platform rules before composing
- Read the closest matching style template (e.g., [seedance-2-ugc.md](../prompt-library/seedance-2-ugc.md) for UGC-style sources) for structural guidance
- Follow the **Subject + Action + Camera + Style + Constraints** order
- Stay within **100–260 words** (Seedance sweet spot)
- Include `@(img1)` token if user provided a product image URL
- Add consistency anchors: "The product from @(img1) must remain visually unchanged in every shot"
- Add pacing cues in the tone direction paragraph
- Use timestamps `[00:00]`, `[00:04]`, etc. for multi-beat sequences
- **No forbidden words:** cinematic, professional, stunning, 8k, studio, perfect

**Duration selection:**
- If source ≤ 15s: match source duration (or round to nearest second in 4–15 range)
- If source > 15s: split into clips, each ≤ 15s
- Use dialogue word count to validate (see main SKILL.md duration table: ~2.5 words/sec)

### Step 7: Dialogue confirmation gate

**MANDATORY** for any clone with spoken dialogue. Follow the exact format from the
main SKILL.md:

```
Dialogue script (please confirm before I generate)

  1. [HOOK]    "adapted line matching original pattern"
  2. [SHOW]    "adapted feature call-out for user's product"
  3. [DEMO]    (silent beat — physical demonstration, no dialogue)
  4. [VERDICT] "adapted closing line / CTA"

Total spoken words: ~N  |  Target duration: Xs  |  Fits at natural pace: yes/no

Approve this dialogue? (yes / edit / rewrite)
```

**Rules:**
- This gate is **separate** from the credit cost confirmation — both must be satisfied
- Never assume approval from earlier confirmations (tone, analysis, credit cost)
- If user says "edit" or proposes changes, revise and re-present until approved
- Skip ONLY if the source video is entirely silent (no speech detected in step 2)

### Step 8: Audio decision

On KIE's Seedance, audio behavior is driven by what you write in the prompt (spoken
lines are embedded in the prompt text). Native audio-toggle fields and reference-audio
fields are marketplace-model-specific.

Ask the user:

1. **Include dialogue in prompt?** Default yes if the source has speech. Default no
   if the source is silent.
2. **Voice cloning?** Check the KIE marketplace page for the Seedance model to see
   whether it accepts reference audio inputs. If it does not, explain the limitation
   and proceed with text-driven dialogue. If it does, follow the field shape listed
   on the marketplace page (and record it in `MASTER_CONTEXT.md`).

### Step 9: Credit cost estimation

Follow the main SKILL.md's mandatory estimation flow:

1. Check `logs/kie-api.jsonl` for matching `model` + similar config
2. Fall back to `MASTER_CONTEXT.md` rate table
3. For multi-clip: show per-clip and total
4. Present with source citation and estimate-only disclosure:

```
Estimated credit cost:
  Seedance 2 (15s i2v) × 1 clip × 1 variation = ~X credits
    (from logs/kie-api.jsonl YYYY-MM-DD)
  ─────────────────────────────────────
  Estimated total: ~X credits

  Estimate only — confirm exact cost in kie.ai/logs after the run.
  Proceed? (yes/no)
```

**Do NOT generate until the user confirms.**

### Step 10: Prepare inputs

1. Confirm the product image URL is PUBLIC and reachable (curl -I returns 200).
2. If user supplied a local file, ask them to upload it to their host and share the URL.
3. If running in multi-clip mode, plan where clip N's last-frame URL will live.
4. Confirm `KIE_API_KEY` is loaded from `.env`.

### Step 11: Generate

1. Compose the job body:
   ```json
   {
     "model": "seedance-2",
     "callBackUrl": "",
     "input": {
       "prompt": "<composed prompt>",
       "image_input": ["<public product image URL>"],
       "aspect_ratio": "9:16",
       "duration": 15,
       "resolution": "720p",
       "output_format": "mp4"
     }
   }
   ```
   - `aspect_ratio`: match source video (`9:16` or `16:9`)
   - `duration`: from step 6
   - `resolution`: `720p` (default)
   - Omit `image_input` entirely for text-only mode

2. Ask generation count (how many variations? default 1)

3. **Single-clip:** Fire N parallel `POST https://api.kie.ai/api/v1/jobs/createTask` calls.
   **Multi-clip (chained):** Fire clips **sequentially** per the chaining pipeline in step 5.
   Each clip depends on the previous clip's output — do not fire in parallel.

4. **Log immediately** to `logs/kie-api.jsonl`:
   ```json
   {
     "timestamp": "...",
     "endpoint": "POST /api/v1/jobs/createTask",
     "model": "seedance-2",
     "taskId": "...",
     "request": { "duration": 15, "resolution": "720p", "aspect_ratio": "9:16" },
     "response": { "state": "queuing" },
     "notes": "clone-ad: ..."
   }
   ```

5. Poll `GET https://api.kie.ai/api/v1/jobs/recordInfo?taskId=<taskId>` until `state`
   is `success` or `fail`. Intermediate states: `waiting`, `queuing`, `generating`.
   - Single-clip: poll all variation taskIds concurrently
   - Multi-clip: poll each clip individually, wait for `state: success` before proceeding
   - Update log entry with final `state`, credit usage (from `kie.ai/logs`), wall-clock
     generation time, and the URLs parsed out of `data.resultJson`.

6. For multi-clip: extract clip N's last frame, host it at a public URL, pass it as
   `input.image_input[0]` for clip N+1.

### Step 12: Present results

1. **Save all videos** to `outputs/clone-ad-tests/` (or a descriptive subfolder)
2. **Open the output folder** on the user's machine so they can immediately review:
   ```bash
   open "outputs/clone-ad-tests/"   # macOS
   ```
3. Present watch/download URLs (parsed from `data.resultJson`).
4. For multiple variations: numbered list for comparison
5. For multi-clip:
   - Present each clip separately
   - Stitch with ffmpeg using **absolute paths**:
     ```bash
     printf "file '%s'\n" "$(pwd)/clip1.mp4" "$(pwd)/clip2.mp4" "$(pwd)/clip3.mp4" > /tmp/stitch-list.txt
     ffmpeg -y -f concat -safe 0 -i /tmp/stitch-list.txt -c copy stitched-output.mp4
     ```
   - Provide both stitched file and individual clips
6. Link to [kie.ai/logs](https://kie.ai/logs) so the user can confirm the actual
   credit charge for each task.

## Seedance 2 constraints (quick reference)

Check [reference.md](../../reference.md) for full details. These are the ones most
likely to bite during clone-ad:

| Constraint | Impact |
|-----------|--------|
| Reference images must be PUBLIC URLs | No presigned upload on KIE — host externally |
| Up to 14 reference images per job | Plenty of room for multi-angle product shots |
| Content moderation | KIE runs safety checks; credits may be charged on rejection — rewrite, don't retry |
| Prompt length | 100–260 words (Seedance sweet spot) |
| Duration | 4–15 seconds (continuous integer) |
| Aspect ratio | `9:16` or `16:9` |
| Forbidden words | cinematic, professional, stunning, 8k, studio, perfect |
| Model string | Verify on [kie.ai/market](https://kie.ai/market) (likely `seedance-2`) |

## Error recovery

| Error | Recovery |
|-------|----------|
| Content moderation rejects prompt | Do NOT retry same payload. Remove potentially flagged language. Tighten motion descriptions. Check for forbidden words. |
| `state: fail` with error message | Check the error payload in `recordInfo`. If content-related, rewrite prompt. If server error, wait and retry once. |
| 4xx on createTask | Validate payload shape against the model's marketplace page. Most common causes: missing field, wrong aspect ratio string, unreachable `image_input` URL. |
| Prompt too long (> 260 words) | Trim: cut filler from tone direction, compress setting details, shorten consistency anchors. Prioritize beat structure and dialogue. |
| Source video > 15s | Split into clips at natural beat boundaries. Generate each separately. Offer to stitch. |
| Image URL unreachable | Re-host on a public endpoint. `curl -I <url>` must return 200 before submitting. |

## Related files

- [analyze-video/SKILL.md](../analyze-video/SKILL.md) — the template-creation cousin (creates reusable `.md` templates instead of generating)
- [analyze-video/scripts/extract-frames.sh](../analyze-video/scripts/extract-frames.sh) — frame + audio extraction (reused by this skill)
- [seedance-2.md](../prompt-library/seedance-2.md) — Seedance 2 platform rules (read before composing any prompt)
- [seedance-2-ugc.md](../prompt-library/seedance-2-ugc.md) — 9-layer UGC formula (use as structural reference for UGC-style source videos)
- [seedance-2-premium-reveal.md](../prompt-library/seedance-2-premium-reveal.md) — premium reveal formula (for dark-void product-only source videos)
- [seedance-2-product-hero.md](../prompt-library/seedance-2-product-hero.md) — product hero formula (for elemental/effects product-only source videos)
- [seedance-2-studio-lookbook.md](../prompt-library/seedance-2-studio-lookbook.md) — studio lookbook formula (for polished voiceover-style source videos)
- [seedance-2-feature-walkthrough.md](../prompt-library/seedance-2-feature-walkthrough.md) — feature walkthrough formula (for fast-paced demo source videos)
- [../../reference.md](../../reference.md) — API routes, job schemas, polling, constraints
- [../../SKILL.md](../../SKILL.md) — main execution checklist (dialogue gate, credit estimation, logging)
