# KIE.ai API logs

This directory contains **append-only logs** of every KIE.ai generation call made by the agent. The logs power smarter credit-cost estimation over time and give you a locally-searchable history independent of [kie.ai/logs](https://kie.ai/logs).

## Files

- **`kie-api.jsonl`** — one JSON object per line. Every `POST` to a generation endpoint (`/api/v1/veo/generate`, `/api/v1/jobs/createTask`) appends one line when the request is fired and updates the same line with final status/credits after polling completes.

## Entry schema

```json
{
  "timestamp": "2026-04-20T19:18:24.611Z",
  "endpoint": "POST /api/v1/jobs/createTask",
  "model": "nano-banana-2",
  "taskId": "task_abc123",
  "request": {
    "aspect_ratio": "1:1",
    "resolution": "1K",
    "output_format": "jpg",
    "imageInputCount": 3,
    "promptWordCount": 142,
    "generationType": null,
    "duration": null
  },
  "response": {
    "state": "success",
    "successFlag": null,
    "creditsCharged": 0.03,
    "generationTimeSec": 42,
    "resultUrls": ["https://tempfile.kie.ai/.../image.png"],
    "error": null
  },
  "session": {
    "folderName": "outputs/2026-04-20-ugc-batch"
  }
}
```

Notes on the schema:

- `endpoint` distinguishes Veo (`/api/v1/veo/generate`) from jobs (`/api/v1/jobs/createTask`).
- `taskId` is the only server-side identifier — keep it for cross-reference with [kie.ai/logs](https://kie.ai/logs).
- `state` (jobs) and `successFlag` (Veo) are both recorded — one will be null depending on the endpoint family.
- For Veo calls, populate `generationType` (`TEXT_2_VIDEO` / `REFERENCE_2_VIDEO` / `FIRST_AND_LAST_FRAMES_2_VIDEO`) and leave `output_format` null.
- For jobs with image inputs, `imageInputCount` is the length of `input.image_input`; for Veo, `imageInputCount` is the length of `imageUrls`.

## How the agent uses this file

- **Before any new generation:** grep the log for entries with the same `model` + similar config and use the **actual recorded `creditsCharged`** to compute the estimate — not a hardcoded table.
- **After each generation:** append the request metadata and the final polled response (including `creditsCharged` and elapsed time).
- **When pricing patterns emerge:** derive per-second or per-unit rates from recorded data and document them in `MASTER_CONTEXT.md`.

## What NOT to log

Logs are **not gitignored** — historical cost data across sessions is valuable. To keep the log safe to share:

- **Never log API keys** or `Authorization` headers.
- **Never log full prompt text** (can be large; store a word count instead).
- **Never log full reference image URLs** if they contain tokens or sensitive paths — store the count.
