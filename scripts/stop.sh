#!/usr/bin/env bash
# Stop the native Ollama server started via start.sh.
# Usage: ./scripts/stop.sh
set -euo pipefail
cd "$(dirname "$0")/.."

PID_FILE=".run/ollama.pid"
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  kill "$(cat "$PID_FILE")"
  rm -f "$PID_FILE"
  echo "✓ Ollama stopped"
else
  pkill -x ollama 2>/dev/null && echo "✓ Killed stray ollama process(es)" || \
    echo "ℹ No running Ollama process found"
fi