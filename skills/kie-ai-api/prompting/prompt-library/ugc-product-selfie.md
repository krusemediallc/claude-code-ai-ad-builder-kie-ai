# UGC product selfie — character + product + style reference workflow

**Use when:** The user wants to generate a UGC-style selfie image of one of their AI influencers holding/using a product. Combines a character sheet, a product photo, and style reference images into a single Nano Banana generation.

## Required inputs

| Input | Source | Role in `image_input` |
|-------|--------|----------------------|
| **Character hero** | `references/influencers/{name}/01-hero-front.jpg` | Identity — face, hair, build, skin |
| **Product photo** | `references/products/{product}.png` | What they're holding/using |
| **Style references** (2-4) | `references/aesthetics/{style}/` | Visual vibe — lighting, framing, quality |

All inputs are uploaded via KIE file upload (`POST https://kieai.redpandaai.co/api/file-base64-upload` or `/api/file-url-upload`) and passed as `input.image_input` array.

## Reference image order

```
image_input = [
  character_hero_url,    # position 1: identity anchor
  product_url,           # position 2: product context
  style_ref_1_url,       # position 3+: style/vibe
  style_ref_2_url,
  style_ref_3_url,       # 3 style refs is the sweet spot
]
```

Nano Banana 2 supports up to 14 `image_input` references. Character hero should always be first.

## Prompt formula

### Structure

```
[Camera hardware] + [Framing] + [Character description] + [Action with product] + [Expression] + [Outfit] + [Setting/background] + [Imperfection block] + [Negative cues]
```

### The imperfection block (CRITICAL)

Always include at least 4-5 of these:
- `slight motion blur on hair strands`
- `slightly overexposed highlights on forehead and nose`
- `visible image grain and noise`
- `iPhone front camera wide-angle lens distortion on the extended arm`
- `slightly off-center framing, tilted a few degrees`
- `washed out flat color grading`
- `soft focus — nothing is tack sharp`
- `uneven ambient indoor lighting with one side of face slightly in shadow`

### Skin realism block (CRITICAL — always include)

Pick 3-4 of these inline with character description:
- `natural skin with visible pores`
- `slight unevenness in skin tone`
- `minor undereye shadows`
- `a hint of shine on the nose and forehead from natural oils`
- `slight pinkness on cheeks and nose`

**Do NOT use:** acne, pimples, breakouts, blemishes, redness.

### Negative cues (always include)

```
No retouching, no beauty filter, no studio lighting, not a professional photo, not overly polished. No airbrushed skin, no flawless complexion.
```

## Step-by-step flow

### Step 1: Gather inputs

1. **Character:** Ask which influencer. Load their `01-hero-front.jpg`.
2. **Product:** Ask which product or check `references/products/`.
3. **Style:** Default to `references/aesthetics/ugc-selfie/`. Load 3 images.
4. **Scene:** Ask for setting and outfit. If unspecified, pick a natural casual setting.

### Step 2: Upload all reference images

Upload all files via KIE file upload. Total: 4-6 `image_input` URLs per call.

### Step 3: Compose the prompt

1. Start with `"Raw iPhone front-camera selfie video frame grab."`
2. Describe character with key visual traits + skin realism cues.
3. Describe action with product — candid mid-speech expression.
4. Specify outfit and background/setting.
5. **Add full imperfection block** (non-negotiable).
6. End with negative cues.

### Step 4: Generate

Call `POST /api/v1/jobs/createTask` with:
- `model`: `nano-banana-2`
- `input.prompt`: the composed prompt
- `input.aspect_ratio`: `9:16`
- `input.image_input`: array of all uploaded URLs

Default to **3 variations** so the user can compare.

### Step 5: Present and iterate

1. Download and open all variations for the user.
2. QA each for anatomy issues (hands are the most common problem).
3. Present as numbered list.

## Combining with video

Once the user approves a UGC still, it can be used as `imageUrls` for Veo 3.1 video generation:

1. Upload approved still via KIE file upload
2. `POST /api/v1/veo/generate` with `imageUrls: [still_downloadUrl]` + dialogue in prompt
3. **Human motion cues (CRITICAL):** Include 3-4 natural movement cues
4. **ALWAYS end with:** `"No subtitles, no captions, no text overlays."`

### Sora 2 (NOT recommended for UGC stills → video)

Sora 2's `image_urls` is more of a **style reference** — it will not preserve the exact face/pose from the approved still. Only use when you need longer duration and don't need frame-one fidelity.
