#!/usr/bin/env bash
# Pull the chat model + embedding model needed for a basic RAG stack.
set -euo pipefail
ollama pull llama3.1:8b-instruct-q4_K_M
ollama pull nomic-embed-text
echo "✓ RAG models ready: llama3.1:8b (chat) + nomic-embed-text (embeddings)"