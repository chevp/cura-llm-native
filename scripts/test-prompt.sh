#!/usr/bin/env bash
# Run a one-shot prompt against the local Ollama HTTP API.
# Usage: ./scripts/test-prompt.sh [model] [prompt]
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env"
[[ -f "$ENV_FILE" ]] || ENV_FILE=".env.example"
# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

MODEL="${1:-llama3.1:8b-instruct-q4_K_M}"
PROMPT="${2:-Erkläre Apple Metal in einem Satz.}"
HOST="${OLLAMA_HOST:-127.0.0.1:11434}"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required (brew install jq)" >&2
  exit 1
fi

curl -s "http://${HOST}/api/generate" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n --arg m "$MODEL" --arg p "$PROMPT" '{model:$m, prompt:$p, stream:false}')" \
  | jq -r '.response'