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
POST /api/v1/jobs/createTask (nano-banana-2)
with product photo in image_input
        |
        v
Nano Banana generates still image
        |
        v
User approves still image
        |
        v
Still → imageUrls for video gen
(Veo 3.1 / Sora 2 / Kling 3.0)
        |
        v
Final product showcase video
```

## Step-by-step

### 1. Collect product info

Ask the user for:
- **Product image(s)** — photos of the item
- **Product context** — what it is, key features, target audience
- **Video intent** — UGC selfie-style? Polished ad? Unboxing?
- **Person description** — what should the AI person look like? (Or reuse existing influencer from `references/influencers/`)
- **Nano Banana engine** — default NB2 or Pro

### 2. Compose the Nano Banana image prompt

Describe: (1) the person, (2) the product interaction, (3) match the video intent, (4) include the product image as reference.

### 3. Generate the still image

1. Upload product image via KIE file upload to get `downloadUrl`.
2. Call `POST /api/v1/jobs/createTask` with:
   - `model`: `nano-banana-2`
   - `input.prompt`: the product showcase prompt
   - `input.image_input`: `[product_downloadUrl]` (optionally add character hero too)
   - `input.aspect_ratio`: match video intent (`9:16` for reels, `16:9` for landscape)
3. Poll until `state: success`.
4. **Post-generation QA** per [nano-banana.md](nano-banana.md).
5. Show the image to the user.

### 4. Get user approval

**Wait for explicit approval** before video.

### 5. Generate video from approved still

1. Upload approved still via KIE file upload.
2. For **Veo 3.1:** `POST /api/v1/veo/generate` with `imageUrls: [still_downloadUrl]`
3. For **Sora 2:** `POST /api/v1/jobs/createTask` with `model: "sora-2-image-to-video"` and `input.image_urls: [still_downloadUrl]`
4. Include dialogue in the video prompt.
5. Poll until complete, return URLs.

## Prompt template

```text
{{PERSON_DESCRIPTION}}. They are {{INTERACTION}} a {{PRODUCT_DESCRIPTION}}.
Setting: {{SETTING}}. Camera: {{CAMERA}}. Lighting: {{LIGHTING}}.
The product is {{PRODUCT_PLACEMENT}} — clearly visible, in-focus, natural grip.
Style: {{STYLE}}. Avoid: studio lighting, floating product, unnatural hand pose.
```

## Tips

- **Product fidelity:** If the generated still distorts the product, try a cleaner product photo with white/neutral background.
- **Hand pose:** "natural grip with fingertips" in the prompt helps avoid unnatural hand poses.
- **Consistency:** Save the approved person prompt in `MASTER_CONTEXT.md` for reuse.
