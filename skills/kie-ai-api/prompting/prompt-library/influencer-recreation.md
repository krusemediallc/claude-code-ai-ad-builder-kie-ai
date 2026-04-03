# Influencer recreation from reference image

**Use when:** The user provides a photo of an influencer (or themselves) and wants to recreate that person in AI-generated content via KIE AI.

## Required flow (do NOT skip steps)

1. User provides a reference image
2. Agent analyzes the image (Step 1 below)
3. Agent writes a Nano Banana-style recreation prompt (Step 2)
4. **Generate a still image** via Nano Banana with the original as `image_input` reference
5. **User approves** the still image
6. **Only after approval** → generate video using the approved image

**KIE route for image:** `POST /api/v1/jobs/createTask` with `model: "nano-banana-2"`. Include the original reference photo in `input.image_input` so Nano Banana can match the person's appearance. Poll `GET /api/v1/jobs/recordInfo?taskId=` until `state: success`.

**KIE route for video (after approval):** Upload approved still via KIE file upload → use `downloadUrl` in `imageUrls` for Veo 3.1, or `input.image_urls` for Sora 2 image-to-video.

## Workflow

### Step 1: Analyze the reference image

When the user shares an image, **dissect it systematically:**

**Face and features:** age range, skin tone, face shape, distinctive features
**Hair:** color, length, texture, parting
**Eyes and brows:** eye color, brow shape, makeup
**Makeup and skin:** level, lip color, skin finish
**Body and pose:** build, posture, hand position
**Clothing and accessories:** garments, jewelry, accessories
**Lighting and environment:** light direction, background, color temperature
**Vibe / energy:** expression, overall aesthetic

### Step 2: Write the recreation prompt

Combine analysis into **one dense paragraph** (80-150 words):

```
[Subject description with physical features] in [setting/environment].
[Clothing and accessories described specifically].
[Pose and expression]. [Lighting described as physical properties].
[Camera and style]. [Skin and texture realism cues].
```

**Rules:**
- Use specific visual language, not vague adjectives
- Describe lighting as physics, not mood words alone
- Include at least one texture cue for realism
- Do NOT use celebrity names

### Step 3: Present to user for approval of the PROMPT

Show: (1) your breakdown, (2) the recreation prompt, (3) ask if anything needs adjusting.

### Step 4: Generate the still image (Nano Banana)

1. Read **[nano-banana.md](nano-banana.md)** and follow the vendor guide.
2. Upload the reference image via KIE file upload to get a `downloadUrl`.
3. Call `POST /api/v1/jobs/createTask` with:
   - `model`: `nano-banana-2` (default) or `google/nano-banana` (Pro)
   - `input.prompt`: the recreation prompt
   - `input.image_input`: `[reference_image_downloadUrl]`
   - `input.aspect_ratio`: match reference or user preference
4. Poll until `state: success`.
5. **Post-generation QA** per [nano-banana.md](nano-banana.md). Regenerate if needed (up to 2 retries).
6. Show the recreation next to the original reference.

### Step 5: User approves the still image

- Show result alongside the original.
- **Wait for explicit approval** before video.

### Step 6: Generate video from approved image

1. Upload approved still via KIE file upload to get `downloadUrl`.
2. For **Veo 3.1:** `POST /api/v1/veo/generate` with `imageUrls: [downloadUrl]`.
3. For **Sora 2:** `POST /api/v1/jobs/createTask` with `model: "sora-2-image-to-video"` and `input.image_urls: [downloadUrl]`.
4. Poll until complete, return URLs.

## Tips for consistency

- Save the approved prompt text in `MASTER_CONTEXT.md` for future reuse.
- Use the Nano Banana image as `imageUrls[0]` for Veo 3.1 (start-frame behavior with 1 image).
- Keep the core description **frozen** and only vary pose, clothing, or setting in subsequent prompts.
