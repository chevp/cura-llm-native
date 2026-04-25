#!/usr/bin/env bash
# Start the native Ollama server in the background.
# Reads .env (or .env.example) for runtime config.
# Usage: ./scripts/start.sh
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env"
[[ -f "$ENV_FILE" ]] || ENV_FILE=".env.example"
# shellcheck disable=SC1090
set -a; source "$ENV_FILE"; set +a

PORT="${OLLAMA_HOST##*:}"
if lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "✓ Ollama already listening on $OLLAMA_HOST"
  exit 0
fi

mkdir -p .run
nohup ollama serve >.run/ollama.log 2>&1 &
echo $! >.run/ollama.pid
sleep 2

if lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "✓ Ollama started on $OLLAMA_HOST (pid $(cat .run/ollama.pid))"
  echo "  Logs: .run/ollama.log"
else
  echo "✗ Ollama failed to start. Tail of .run/ollama.log:" >&2
  tail -n 20 .run/ollama.log >&2 || true
  exit 1
fi