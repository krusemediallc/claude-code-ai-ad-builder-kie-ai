# Product showcase — AI person with product

**Use when:** The user wants to generate a video of an AI person holding, using, or demonstrating a physical product.

## Workflow

```
User provides product image(s)
        |
        v
Agent writes Nano Banana prompt
(AI person + product interaction)
        |
        v
POST /api/v1/jobs/createTask
with input.image_input = [product_url]
        |
        v
Nano Banana generates still image
(person holding/using product)
        |
        v
User approves still image
        |
        v
Still hosted as URL -> passed to video gen
(Veo 3.1 / Sora 2 / Kling 3.0)
        |
        v
Final product showcase video
```

## Step-by-step

### 1. Collect product info

Ask the user for:
- **Product image(s)** — photos of the item from different angles. They need to be hosted at public HTTPS URLs (any CDN / signed URL) because KIE fetches references over HTTP; it does not accept base64 or file uploads.
- **Product context** — what it is, key features, target audience (check `MASTER_CONTEXT.md` for existing context)
- **Video intent** — UGC selfie-style? Polished ad? Unboxing?
- **Person description** — what should the AI person look like? (Or reuse an existing influencer prompt from `MASTER_CONTEXT.md`)
- **Nano Banana engine** — default **Nano Banana 2** (`nano-banana-2`), or **Nano Banana Pro** (`nano-banana-pro`) if they prefer (see [nano-banana.md](nano-banana.md))

### 2. Compose the Nano Banana image prompt

Follow the template below. The prompt should describe:

1. **The person** — age, gender, appearance, wardrobe, expression, pose
2. **The product interaction** — how they hold it, where it sits in frame, what angle, how prominent
3. **Match the video intent** — if the final video is UGC selfie-style, the still should already look like a selfie. If it's a polished product ad, frame accordingly
4. **Pass the product photo URL** in `input.image_input` so Nano Banana can composite it

### 3. Generate the still image

1. Auto-upscale the product image if needed before hosting (see SKILL.md "Image handling").
2. Call `POST /api/v1/jobs/createTask` with:
   - `model` — **`nano-banana-2`** unless the user chose Nano Banana Pro (`nano-banana-pro`)
   - `input.prompt` — the Nano Banana product showcase prompt
   - `input.aspect_ratio` — match the video intent (`9:16` for reels, `16:9` for landscape, `1:1` for square)
   - `input.image_input` — array of hosted URLs; at minimum the product photo. Add the influencer hero URL too if you have one.
   - `input.resolution` — `2K` default
3. Poll `GET /api/v1/jobs/recordInfo?taskId={id}` until `state: success`, then parse `data.resultJson` for the image URL.
4. **Post-generation QA:** Inspect the still per [nano-banana.md](nano-banana.md) (hands, product edges, merged geometry). **Regenerate** with a refined prompt if needed — up to **2** retries after the first attempt. **Only then** treat the still as ready to show.
5. Save the still(s) into the session outputs folder (`outputs/{date}-{slug}/`) so the whole run is reproducible.
6. Show the **QA-passed** (or best-effort after max retries) image to the user.

### 4. Get user approval

- Show the generated still to the user — **after** internal QA and auto-retries in step 3–4.
- **Wait for explicit approval** before proceeding to video.
- If the user wants a different creative direction (not just defect fixes), iterate on the prompt and regenerate per SKILL.md credit rules.

### 5. Generate video from approved still

1. Host the approved image at a publicly reachable HTTPS URL.
2. Pass that URL into the chosen video model:
   - **Veo 3.1:** `POST /api/v1/veo/generate` with `imageUrls: ["<url>"]` and `generationType: "REFERENCE_2_VIDEO"` (requires `model: "veo3_fast"`), or `"FIRST_AND_LAST_FRAMES_2_VIDEO"` with two URLs for a controlled end beat.
   - **Sora 2:** `POST /api/v1/jobs/createTask` with `model: "sora-2-image-to-video"` and `input.image_input: ["<url>"]`.
   - **Kling 3.0:** `POST /api/v1/jobs/createTask` with `model: "kling-3"` and `input.image_input: ["<url>"]`.
3. Include dialogue/script in the video prompt (see SKILL.md "Script and dialogue").
4. Poll until success (`successFlag: 1` for Veo; `state: "success"` for jobs route), save the result, and return watch/download URLs.

## Prompt template

```text
{{PERSON_DESCRIPTION}}. They are {{INTERACTION}} a {{PRODUCT_DESCRIPTION}}.
Setting: {{SETTING}}. Camera: {{CAMERA}}. Lighting: {{LIGHTING}}.
The product is {{PRODUCT_PLACEMENT}} — clearly visible, in-focus, natural grip.
Style: {{STYLE}}. Avoid: studio lighting, floating product, unnatural hand pose.
```

## Example

```text
A 25-year-old woman with shoulder-length brown hair in a casual white t-shirt,
smiling warmly at camera. She is holding a small amber glass skincare bottle in
her right hand at chin height, label facing camera. Setting: bright modern
bathroom, morning light through frosted window. Camera: front-facing selfie
angle, slightly above eye level. The product is centered in the lower third of
frame — clearly visible, natural grip with fingertips around the bottle.
Style: authentic, unfiltered, soft natural tones. Avoid: studio lighting,
floating product, perfect skin retouching.
```

## Script prompting for video stage

Once the starting frame is approved and video generation begins, the video model prompt should:

- Reference the starting frame ("continues from the still image")
- Add **motion and dialogue** — what the person says about the product
- Follow the relevant model's prompt library ([veo-3-1.md](veo-3-1.md), [sora-2.md](sora-2.md), [kling-3.md](kling-3.md))
- Pull product context from `MASTER_CONTEXT.md` (description, key features, pain point, perceived positioning)

### Video prompt template

```text
{{PERSON}} holds {{PRODUCT}} and speaks directly to camera. {{ACTION_BEATS}}.
Product details: {{KEY_FEATURES}}. Tone: {{TONE}}. Setting: {{SETTING}}.
Camera: {{CAMERA}}. Dialogue: "{{SCRIPT}}". {{STYLE_AND_IMPERFECTIONS}}.
```

## Product context

KIE does not store product metadata server-side — there's no product object to POST. Keep marketing context in `MASTER_CONTEXT.md` instead:

```
## Product: {name}
Description: What the product is
Target audience: Who it's for
Main features:
  - feature 1
  - feature 2
  - feature 3
Pain point: Problem it solves
Perceived: How customers see it
Image URL(s): https://... (hosted somewhere reachable)
```

The agent reads this block and feeds it into the prompt for every generation. Product images live locally under `references/products/` and get uploaded to a public URL (or re-used from a CDN) before each call.

## Tips

- **Product fidelity:** If the generated still distorts the product (wrong label, color shift), try a cleaner product photo with white/neutral background.
- **Hand pose:** "natural grip with fingertips" in the prompt helps avoid the common AI issue of unnatural hand poses around objects.
- **Consistency:** Save the approved person prompt in `MASTER_CONTEXT.md` for reuse across multiple product shoots with the same AI influencer.
