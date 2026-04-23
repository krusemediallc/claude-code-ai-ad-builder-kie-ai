#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Reusable YouTube thumbnail batch generator (Nano Banana 2 via KIE.ai)
#
# This is a TEMPLATE. Copy to scripts/generate-thumbnails-vN.sh and customize:
#   1. Populate COMMON_REF_URLS with PUBLIC URLs (one per reference image).
#      KIE has no presigned-upload flow — every reference must be a reachable
#      URL before you run this script. Host on your own CDN/bucket, GitHub
#      raw, any image host, etc.
#   2. Replace PROMPTS array with your composed prompts.
#   3. Run: bash scripts/generate-thumbnails-vN.sh > output/run.log 2>&1 &
#   4. Monitor: tail -F output/run.log | grep -E "DONE|FAILED|Task"
#
# Features:
#   - Parallel firing of POST /api/v1/jobs/createTask with model=nano-banana-2
#     (override MODEL env var for nano-banana-pro on hero shots)
#   - Retry on failure with backoff
#   - Polls GET /api/v1/jobs/recordInfo?taskId=... until state=success/fail
#   - Parses data.resultJson (JSON-encoded string) for result URLs
#   - Downloads final images into a dated session folder
#   - Optional local Lanczos upsample helper (for when you host images yourself)
#
# Concurrency / rate limits:
#   KIE supports 100+ concurrent tasks with a 20 req / 10s rate limit.
#   Default stagger is 0.3s between fires. Bump the stagger if you see 429s.
#
# Requires:
#   - .env with KIE_API_KEY
#   - Python 3 (stdlib only — for JSON parsing)
#   - Pillow only if you enable the optional prepare_image() helper
#   - macOS bash 3.2+ or any bash 4+
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
cd "$(dirname "$0")/.."
source .env

# ─── CONFIG ─────────────────────────────────────────────────────────────────
API="https://api.kie.ai"
MODEL="${MODEL:-nano-banana-2}"   # Override: MODEL=nano-banana-pro bash ...
ASPECT="16:9"                     # 1:1, 16:9, 9:16 (check model card for exact supported set)
OUTPUT_DIR="${OUTPUT_BASE:-output}/thumbnails-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"
TMP_DIR="$OUTPUT_DIR/.tmp"
mkdir -p "$TMP_DIR"

if [ -z "${KIE_API_KEY:-}" ]; then
  echo "ERROR: KIE_API_KEY not set. Add it to .env before running." >&2
  exit 1
fi

# ─── REFERENCE IMAGE URLS ───────────────────────────────────────────────────
# KIE requires PUBLIC URLs for reference images. No file upload path.
# Aim for 5+ face references for good likeness alignment. Up to 14 URLs total.

declare -a COMMON_REF_URLS=(
  "https://your-host.example.com/face/headshot.jpg"
  "https://your-host.example.com/face/three-quarter.jpg"
  "https://your-host.example.com/face/close-up.jpg"
  "https://your-host.example.com/face/smile.jpg"
  "https://your-host.example.com/face/neutral.jpg"
  "https://your-host.example.com/logos/brand-1.png"
  "https://your-host.example.com/logos/brand-2.png"
  # Add product photos, comparison material, etc. as needed (max 14 total)
)

# Verify every URL is reachable before firing. Stop the whole batch if any URL fails —
# one bad reference typically means a whole variation renders garbage.
for url in "${COMMON_REF_URLS[@]}"; do
  code=$(curl -sS -I -o /dev/null -w "%{http_code}" "$url" || echo "000")
  if [ "$code" != "200" ] && [ "$code" != "302" ] && [ "$code" != "301" ]; then
    echo "UNREACHABLE ($code): $url" >&2
    exit 1
  fi
done

# ─── OPTIONAL: local Lanczos upsample helper ────────────────────────────────
# Call prepare_image in/place.jpg out/place.jpg if you're hosting files from this
# machine and want to upsample before uploading to your host. Disabled by default
# because KIE reads URLs, not local paths — this is just a pre-hosting convenience.
prepare_image() {
  python3 - "$1" "$2" <<'PY'
import sys
from PIL import Image
inp, out = sys.argv[1], sys.argv[2]
img = Image.open(inp).convert("RGB")
w, h = img.size
longest = max(w, h)
if longest < 1080:
    scale = 1080.0 / longest
    img = img.resize((int(w*scale), int(h*scale)), Image.LANCZOS)
img.save(out, "JPEG", quality=92)
PY
}

# ─── HELPERS ────────────────────────────────────────────────────────────────

# Generate a single thumbnail: submit task → poll → parse resultJson → download.
# Expects REF_URLS_RAW (JSON array of URL strings) to be exported in the environment.
generate_one() {
  local idx=$1
  local prompt=$2

  echo "[#$idx] Submitting task (model=$MODEL)..."
  local body
  body=$(PROMPT="$prompt" MODEL_NAME="$MODEL" ASPECT_NAME="$ASPECT" python3 -c "
import json, os
body = {
  'model': os.environ['MODEL_NAME'],
  'callBackUrl': '',
  'input': {
    'prompt': os.environ['PROMPT'].strip(),
    'image_input': json.loads(os.environ['REF_URLS_RAW']),
    'aspect_ratio': os.environ['ASPECT_NAME'],
    'output_format': 'png'
  }
}
print(json.dumps(body))
")

  local response task_id
  response=$(curl -sS \
    -H "Authorization: Bearer $KIE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "$API/api/v1/jobs/createTask" 2>&1)

  task_id=$(echo "$response" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('data', {}).get('taskId', '') or '')
except Exception:
    print('')
" 2>/dev/null || echo "")

  if [ -z "$task_id" ]; then
    echo "[#$idx] CREATE TASK ERROR: $response"
    echo "$response" > "$OUTPUT_DIR/${idx}_error.json"
    return 1
  fi

  echo "[#$idx] Task $task_id — polling..."
  local poll state result_json url
  for attempt in $(seq 1 60); do
    sleep 5
    poll=$(curl -sS -H "Authorization: Bearer $KIE_API_KEY" \
      "$API/api/v1/jobs/recordInfo?taskId=$task_id" 2>&1)
    state=$(echo "$poll" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    print(d.get('data', {}).get('state', 'unknown'))
except Exception:
    print('unknown')
" 2>/dev/null || echo "unknown")

    case "$state" in
      success)
        url=$(echo "$poll" | python3 -c "
import json, sys
try:
    d = json.loads(sys.stdin.read())
    rj = d.get('data', {}).get('resultJson', '')
    parsed = json.loads(rj) if isinstance(rj, str) and rj else (rj or {})
    urls = parsed.get('resultUrls') or parsed.get('urls') or []
    if isinstance(urls, list) and urls:
        print(urls[0])
    elif isinstance(parsed, dict):
        # Fallback: first string value in the parsed object
        for v in parsed.values():
            if isinstance(v, str) and v.startswith('http'):
                print(v)
                break
except Exception:
    pass
" 2>/dev/null || echo "")
        echo "[#$idx] DONE! state=success"
        echo "$poll" > "$OUTPUT_DIR/${idx}_task.json"
        if [ -n "$url" ]; then
          curl -sS -o "$OUTPUT_DIR/${idx}_thumbnail.png" "$url"
          echo "[#$idx] Downloaded -> $OUTPUT_DIR/${idx}_thumbnail.png"
        else
          echo "[#$idx] WARN: success but no result URL parsed"
        fi
        return 0
        ;;
      fail)
        echo "[#$idx] FAILED: $poll"
        echo "$poll" > "$OUTPUT_DIR/${idx}_failed.json"
        return 1
        ;;
      waiting|queuing|generating|unknown)
        # Keep polling
        ;;
    esac
  done
  echo "[#$idx] TIMEOUT after 300s"
  return 1
}

# Wrapper: try once, then retry once after 15s.
run_with_retry() {
  local idx=$1
  local prompt=$2
  generate_one "$idx" "$prompt" || {
    echo "[#$idx] Retrying after 15s..."
    sleep 15
    generate_one "$idx" "$prompt" || echo "[#$idx] Failed twice — giving up"
  }
}

# Stash ref URLs as a JSON array string; generate_one's Python helper reads it from env.
REF_URLS_RAW=$(python3 -c "
import json, sys
urls = sys.argv[1:]
print(json.dumps(urls))
" "${COMMON_REF_URLS[@]}")
export REF_URLS_RAW

# ─── PROMPTS ────────────────────────────────────────────────────────────────
# Define your prompts here. Each entry generates one thumbnail.
# See ../prompting/guide.md and ../prompting/formulas.md for templates.

declare -a PROMPTS=(

# Example 1 — Peace-sign / branding formula
"YouTube thumbnail, 16:9 landscape. CRITICAL CHARACTER LIKENESS: The subject is the exact same person shown in ALL the face reference photos. Match his face EXACTLY: [DESCRIBE FEATURES]. Maintain the exact same facial proportions, eye shape, beard style, and skin tone as the reference photos. Do not generalize — this is a specific real person and his exact likeness must be preserved. He is wearing [CLOTHING]. The shot is a tight head-and-shoulders crop with his face large and prominent, filling the central 50 percent of the frame. NO HANDS VISIBLE. Just head and upper shoulders, facing camera. Expression: wide excited open-mouth smile showing teeth, eyebrows raised in genuine excitement, eyes wide. To his LEFT side at chest level is a large rounded-square app icon containing [LOGO 1 DESCRIPTION] — use the [LOGO 1] reference exactly. To his RIGHT side at chest level is a large rounded-square app icon containing [LOGO 2 DESCRIPTION] — use the [LOGO 2] reference exactly. Across the very top of the frame in massive bold yellow block letters with a thick black outline reads [TITLE]. Background: dark navy gradient with subtle blue glow. Style: clean high-impact YouTube thumbnail. Avoid: distorted face, hands visible, peace signs, generic face, blurry logos, illegible text."

# Add more prompts here, one per array entry
)

# ─── EXECUTION ──────────────────────────────────────────────────────────────

echo "═══════════════════════════════════════"
echo "Generating ${#PROMPTS[@]} thumbnails in parallel..."
echo "Model: $MODEL"
echo "Output: $OUTPUT_DIR"
echo "═══════════════════════════════════════"

for i in "${!PROMPTS[@]}"; do
  idx=$((i + 1))
  run_with_retry "$idx" "${PROMPTS[$i]}" &
  sleep 0.3  # small stagger to stay under 20 req / 10s rate limit
done

wait

echo "═══════════════════════════════════════"
echo "DONE. Results in: $OUTPUT_DIR"
DOWNLOADED=$(ls "$OUTPUT_DIR"/*_thumbnail.png 2>/dev/null | wc -l | tr -d ' ')
ERRORS=$(ls "$OUTPUT_DIR"/*_error.json "$OUTPUT_DIR"/*_failed.json 2>/dev/null | wc -l | tr -d ' ')
echo "$DOWNLOADED downloaded, $ERRORS errors"
echo "Confirm exact credit usage at: https://kie.ai/logs"
echo "═══════════════════════════════════════"
open "$OUTPUT_DIR" 2>/dev/null || true
