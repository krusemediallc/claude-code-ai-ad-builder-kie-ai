#!/usr/bin/env bash
# Quick connectivity check (loads .env if present). Does not print secrets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "$ROOT/.env" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ROOT/.env"
  set +a
fi
BASE="${KIE_BASE_URL:-https://api.kie.ai}"

if [[ -z "${KIE_API_KEY:-}" ]] || [[ "$KIE_API_KEY" == "your_api_key_here" ]]; then
  echo "No valid API key found. Edit .env with your KIE API key." >&2
  echo "Get your key at: https://kie.ai/api-key" >&2
  exit 1
fi

code="$(curl -sS -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $KIE_API_KEY" \
  -H "Content-Type: application/json" \
  "$BASE/api/v1/chat/credit")"
echo "GET /api/v1/chat/credit → HTTP $code"
if [[ "$code" != "200" ]]; then
  echo "Auth failed (HTTP $code). Check your API key in .env." >&2
  exit 1
fi
echo "OK — connection verified."
