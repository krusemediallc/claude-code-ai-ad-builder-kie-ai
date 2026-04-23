## This repo specifically

- **API:** KIE.ai (`https://api.kie.ai`).
- **Auth:** Bearer token via `KIE_API_KEY` (single token, no pre-encoded header).
- **Skills:**
  - `kie-external-api` — main API reference (Veo/Sora/Nano Banana endpoints, auth, polling, jobs vs first-party paths).
  - `generate-youtube-thumbnail` — YouTube thumbnail batch workflow on top of Nano Banana 2.
- **Setup check:** `./scripts/check-kie-env.sh`.
- **Reference images:** KIE has no presigned-upload flow. Hosted public URLs only — see *Image hosting* in MASTER_CONTEXT.md.
- **Logging:** Log every generation call to `logs/kie-api.jsonl` (schema in `logs/README.md`).
- **Dashboards:** [kie.ai/logs](https://kie.ai/logs) · [kie.ai/api-key](https://kie.ai/api-key) · [kie.ai/pricing](https://kie.ai/pricing) · [kie.ai/market](https://kie.ai/market).
