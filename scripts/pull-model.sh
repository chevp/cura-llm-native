#!/usr/bin/env bash
# Pull a model into the local Ollama store.
# Usage: ./scripts/pull-model.sh [model-name]
set -euo pipefail
MODEL="${1:-llama3.1:8b-instruct-q4_K_M}"
ollama pull "$MODEL"
echo "✓ Model '$MODEL' is ready"