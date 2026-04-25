# Pull the chat model + embedding model needed for a basic RAG stack.
$ErrorActionPreference = 'Stop'
ollama pull llama3.1:8b-instruct-q4_K_M
ollama pull nomic-embed-text
Write-Host "OK RAG models ready: llama3.1:8b (chat) + nomic-embed-text (embeddings)"