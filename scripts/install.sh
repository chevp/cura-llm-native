#!/usr/bin/env bash
# Install Ollama natively on macOS via Homebrew.
# Usage: ./scripts/install.sh
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script targets macOS. For Windows use scripts/install.ps1." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it from https://brew.sh first." >&2
  exit 1
fi

if command -v ollama >/dev/null 2>&1; then
  echo "✓ Ollama already installed: $(ollama --version)"
else
  echo "→ Installing Ollama via Homebrew..."
  brew install ollama
  echo "✓ Ollama installed: $(ollama --version)"
fi
