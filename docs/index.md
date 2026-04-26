---
title: cura-llm-native
---

# cura-llm-native

Run an LLM **natively** for direct GPU access — Apple Metal on macOS, CUDA on Windows. Sister repo to [cura-llm-local](https://github.com/chevp/cura-llm-local) (Docker variant).

> **Source code & full README:** [github.com/chevp/cura-llm-native](https://github.com/chevp/cura-llm-native)

## Documentation

- [**Installation walkthrough**](installation.md) — step-by-step macOS install with verification at every step
- [**Troubleshooting**](troubleshooting.md) — `null` responses, port conflicts, CPU fallback, OOM
- [**Architecture**](architecture.md) — how the two cura LLM backends fit together

## When to pick which

| | cura-llm-local (Docker) | **cura-llm-native** |
|---|---|---|
| Prod parity | identical to AWS | host-specific |
| macOS GPU (Metal) | CPU-only | full Metal |
| Windows GPU (CUDA) | via WSL2 | direct |
| Larger models (13B+) | slow | fast |
| Setup | `docker compose up` | OS installer + `ollama serve` |

Rule of thumb: **dev on macOS/Apple Silicon and want speed → native**. **CI / prod / cross-platform parity → Docker**. Both expose the same Ollama HTTP API on `localhost:11434`, so the rest of cura's stack is interchangeable between them.

## Quick start

**macOS**

```bash
git clone https://github.com/chevp/cura-llm-native.git
cd cura-llm-native
cp .env.example .env
./scripts/install.sh
./scripts/start.sh
./scripts/pull-model.sh llama3.1:8b-instruct-q4_K_M
./scripts/test-prompt.sh llama3.1:8b-instruct-q4_K_M "Was ist Metal?"
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/chevp/cura-llm-native.git
cd cura-llm-native
Copy-Item .env.example .env
.\scripts\install.ps1
.\scripts\start.ps1
.\scripts\pull-model.ps1 llama3.1:8b-instruct-q4_K_M
.\scripts\test-prompt.ps1 llama3.1:8b-instruct-q4_K_M "Was ist CUDA?"
```

If you also have `cura-llm-local` (Docker variant) running, port `11434` will be in use — set `OLLAMA_HOST=127.0.0.1:11435` in `.env` before starting. See [Troubleshooting → Port conflict](troubleshooting.md#port-conflict-with-cura-llm-local) for the full story.

## Recommended models

Apple Silicon (sized to unified memory):

| Memory | Recommended max model | Disk |
|---|---|---|
| 16 GB | `llama3.1:8b-instruct-q4_K_M` | ~5 GB |
| 32 GB | `mixtral:8x7b-instruct-q4_K_M` | ~26 GB |
| 64 GB+ | `llama3.1:70b-instruct-q4_K_M` | ~40 GB |
| any | `nomic-embed-text` (embeddings) | ~270 MB |

Windows NVIDIA (sized to VRAM):

| VRAM | Recommended max model |
|---|---|
| 8 GB | `llama3.1:8b-instruct-q4_K_M` |
| 12 GB | `mistral-nemo:12b-instruct-q4_K_M` |
| 24 GB | `mixtral:8x7b-instruct-q4_K_M` (partial offload) |
| 48 GB+ | `llama3.1:70b-instruct-q4_K_M` |
