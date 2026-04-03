# UGC selfie-style video — cross-model prompting guide

**Applies to:** Veo 3.1, Sora 2, Kling 3.0, Runway (via KIE AI API)
**Aesthetic:** iPhone-shot, Instagram Reels, unpolished realism

Use this guide when the user wants **authentic-looking UGC** — selfie angles, handheld shake, imperfect lighting, casual speech.

## Core principles (all models)

### 1. Camera physics — simulate a smartphone

Stop using "cinematic," "8k," or "award-winning." Instead:

- **Lens:** "iPhone 15 Pro front camera in selfie mode," "native wide lens (~26 mm)," "f/2.2 aperture"
- **Focus:** "Autofocus micro-pulses," "deep focus," "no artificial blur"
- **Lighting:** "Unbalanced exposure," "slight overexposure," "auto white balance with slight blue cast"
- **Imperfections:** "Subtle edge distortion," "natural micro lens flare," "mild luminance grain"

### 2. "Accidental" composition

- "Awkward angle," "messy crop," "deliberately mediocre framing"
- "Unpolished casual home environment," "cluttered background"
- Avoid "centered framing" or "perfect composition"

### 3. Natural human motion (CRITICAL)

**Always include at least 3-4 of these cues:**

#### Eye behavior
- "Briefly breaks eye contact, glances down or to the side, then looks back"
- "Eyes dart to something off-screen for a moment"
- "Looks at the product in their hand, then back to camera"

#### Head and face
- "Slight head tilts while talking"
- "Nods along with their own words"
- "Raises eyebrows for emphasis mid-sentence"
- "Caught mid-thought, slight hesitation"

#### Body movement
- "Shifts weight from one foot to the other"
- "Leans toward camera for emphasis, then leans back"
- "Adjusts their grip on the product"
- "Fidgets with their hair"

#### Selfie arm
- "Holding camera at arm's length, arm clearly visible in frame"
- "Adjusts phone angle mid-video"
- "Quick handheld adjustments, slightly shaky"

### 4. Negative prompting

Always exclude: "studio lighting, professional photography, stock photo, perfect skin, heavy makeup, centered framing, staged, cinematic, LUT, color graded, stabilization, no subtitles, no captions, no text overlays, no on-screen text"

## Model-specific strategies

### Veo 3.1 — scene and shot designer

**Formula:** `[Camera] + [Subject] + [Action] + [Context/Lighting] + [Style/Imperfections] + [Dialogue/Audio]`

- Start with `"A selfie video of..."`
- Add `"The image is slightly grainy, looks very film-like"`
- **ALWAYS end with:** `"No subtitles, no captions, no text overlays."`
- Sweet spot: **75-125 words**

### Sora 2 — narrative director

**Formula:** Structure with `Format & Style`, `Camera`, `Main Subject`, `Location`, `Lighting`, `Actions & Camera Beats`

- Break into **second-by-second beats**
- Specify raw audio: "Raw phone audio, slight room echo, fridge hum"
- Use "autofocus micro-pulses," "completely ungraded iPhone video"

### Kling 3.0 — motion operator

**Formula:** `[Environment] -> [Lighting] -> [Camera Movement] -> [Subject/Product Behavior]`

- **Describe physics:** "She turns her head slowly left to right. Hair follows, catches light."
- **Anchor hands** to objects to avoid morphing
- **Emphasize texture:** "Visible breath," "condensation," "visible skin pores"
- Keep prompts **compact and operational**

### Runway — silent motion

Runway generates **silent video only**. Use for:
- B-roll clips, product shots, ambient scenes
- Image-to-video animations from approved stills
- NOT for UGC with speech (use Veo 3.1 or Sora 2 instead)

## Instagram Reels checklist (final pass)

- [ ] **Aspect ratio:** 9:16 specified
- [ ] **Hook:** First 2 seconds have dynamic motion or strong expression
- [ ] **Lighting:** "Natural," "window light," or "room lighting" — NOT "studio"
- [ ] **Camera:** "iPhone front camera," "selfie-style," "handheld shake"
- [ ] **Flaws:** At least two imperfections included

## References

- [iPhone selfie simulation prompts](https://createvision.ai/templates/community-hyper-realistic-iphone-17-pro-selfie-simulation-prompt-6647)
- [Sora 2 prompt guide](https://higgsfield.ai/sora-2-prompt-guide)
- [UGC AI prompting guide](https://adlibrary.com/guides/ai-prompting-guide-ugc-content-creators)
- [Kling 3.0 realistic motion](https://www.atlascloud.ai/blog/guides/mastering-kling-3.0-10-advanced-ai-video-prompts-for-realistic-human-motion)
- [Veo 3 prompting guide (GitHub)](https://github.com/snubroot/Veo-3-Prompting-Guide)
