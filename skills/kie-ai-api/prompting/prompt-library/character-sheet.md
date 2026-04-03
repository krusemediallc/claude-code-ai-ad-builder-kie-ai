# Character sheet — generate an AI influencer from a text description

**Use when:** The user wants to create a new AI influencer from scratch by describing them in plain English. Generates a 10-image character sheet (multiple angles, white background) that becomes the reference set for all future generations with that character.

## Required flow (do NOT skip steps)

1. User describes the influencer in plain English (e.g., "20-year-old female redhead")
2. Agent expands the description into a detailed visual prompt (Step 1)
3. Agent presents the expanded prompt for user review (Step 2)
4. **Generate 1 hero front portrait** (Step 3)
5. **User approves the hero image** — do NOT skip this step
6. **Generate 9 remaining angles** using the hero as `image_input` reference (Step 4)
7. **QA all images** (Step 5)
8. **Save to `references/influencers/`** using the naming convention (Step 6)

## Step 1: Expand the user's description

Take the user's plain-English description and expand it into a detailed visual prompt.

**Base prompt structure:**

```
A {age}-year-old {gender} influencer with {hair color} {hair texture} {hair length} hair, {skin tone} skin with {distinguishing features}, {eye color} eyes, {build} build, {makeup level}, wearing {clothing}. Clean white studio background, photorealistic, visible skin texture, individual hair strands catching light.
```

**Rules:**
- Use specific visual language, not vague adjectives
- Do NOT use celebrity names or real people's names
- Keep clothing simple and neutral
- Always include texture cues: "visible skin texture," "individual hair strands catching light"

## Step 2: Present the expanded prompt for approval

Show the user:
1. The expanded visual description
2. The 5 descriptor tags for the folder name (see naming convention below)
3. Ask if anything needs adjusting

## Step 3: Generate the hero image (full body front)

1. Compose the hero prompt: prepend `"Full body front view, head to toe."` to the base prompt.
2. Call `POST /api/v1/jobs/createTask` with:
   - `model`: `nano-banana-2` (default) or `google/nano-banana` (Pro)
   - `input.prompt`: the hero prompt
   - `input.aspect_ratio`: `9:16`
   - `input.resolution`: `2K` (for character sheets, higher res is worth it)
3. Poll `GET /api/v1/jobs/recordInfo?taskId=` until `state: success`.
4. **Post-generation QA:** Inspect per [nano-banana.md](nano-banana.md). Regenerate if needed (up to 2 retries).
5. Download the image and **open it for the user** using `open <path>` (macOS).
6. **Wait for explicit user approval.** Do NOT proceed without it.

## Step 4: Generate 9 remaining angles

Once the hero is approved:

1. Upload the hero image via KIE file upload (`POST https://kieai.redpandaai.co/api/file-base64-upload` or `/api/file-url-upload`) to get a `downloadUrl`.
2. For each of the 9 remaining angles, compose a prompt that:
   - Starts with the angle description
   - References the hero: `"The exact same person from the reference image — same face, same {hair}, same {features}, same {eyes}, same {build}, same {clothing}."`
   - Specifies white studio background, photorealistic
3. Call `POST /api/v1/jobs/createTask` for each with:
   - Same `model` and `input.aspect_ratio` as hero
   - `input.image_input`: `[hero_downloadUrl]`
   - The angle-specific prompt
4. Fire all 9 in sequence (to avoid rate limits), poll all concurrently.
5. QA each image per [nano-banana.md](nano-banana.md).

### The 10 angles

| # | File name | Angle | Prompt prefix |
|---|-----------|-------|---------------|
| 1 | `01-hero-front.jpg` | Full body front (hero) | `Full body front view, head to toe.` |
| 2 | `02-3q-left.jpg` | 3/4 left | `Three-quarter view from the left.` |
| 3 | `03-3q-right.jpg` | 3/4 right | `Three-quarter view from the right.` |
| 4 | `04-profile-left.jpg` | Profile left | `Left profile view.` |
| 5 | `05-profile-right.jpg` | Profile right | `Right profile view.` |
| 6 | `06-face-closeup.jpg` | Face close-up | `Face close-up, tight crop.` |
| 7 | `07-back-shoulder.jpg` | Back/over shoulder | `Back view, looking over shoulder.` |
| 8 | `08-medium-portrait.jpg` | Medium portrait | `Front-facing medium portrait, waist up.` |
| 9 | `09-full-body-3q.jpg` | Full body 3/4 | `Full body three-quarter view.` |
| 10 | `10-above-angle.jpg` | Above angle | `Slightly above angle, looking up at camera.` |

## Step 5: QA all images

Follow [nano-banana.md](nano-banana.md) QA checklist. Additionally check **cross-image consistency:**
- Same hair color, texture, and length across all 10
- Same face shape and features
- Same skin tone and distinguishing features
- Same clothing

## Step 6: Save to references folder

### Folder naming convention

```
references/influencers/{name}-{hair_color}-{hair_style}-{feature}-{eye_color}-{skin_tone}/
```

All lowercase, hyphens between words.

### File naming convention

```
01-hero-front.jpg  through  10-above-angle.jpg
```

`01-hero-front.jpg` is always the approved anchor image.

### After saving

- **Open the full character folder** for the user so they can review all 10 images
- Present results as a numbered list
- Note total credits used

## Credit cost

```
Hero image:     1 × Nano Banana 2
9 angle images: 9 × Nano Banana 2
────────────────────────────────────
Total:          10 generations
```

Plus any QA retry generations. Show breakdown and get confirmation before generating.

## Using a character sheet for subsequent workflows

Once a character sheet exists in `references/influencers/`, it can be used as input for:

- **Product showcase** ([product-showcase.md](product-showcase.md)) — use hero + product photo
- **Influencer recreation** ([influencer-recreation.md](influencer-recreation.md))
- **Video generation** — upload hero as `imageUrls` for Veo 3.1, `image_urls` for Sora 2 image-to-video
- **UGC selfie-style** ([ugc-selfie-style.md](ugc-selfie-style.md))

When referencing an existing character, load `01-hero-front.jpg` as the primary reference. For maximum consistency, load multiple angles as additional `image_input` references (up to 14 supported by NB2).
