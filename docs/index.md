---
title: cura-llm-native
---

# cura-llm-native

Run an LLM **natively** for direct GPU access — Apple Metal on macOS, CUDA on Windows. Sister repo to [cura-llm-local](https://github.com/chevp/cura-llm-local) (Docker variant).

> **Source code & full README:** [github.com/chevp/cura-llm-native](https://github.com/chevp/cura-llm-native)

## When to pick which

| | cura-llm-local (Docker) | **cura-llm-native** |
|---|---|---|
| Prod parity | identical to AWS | host-specific |
| macOS GPU (Metal) | CPU-only | full Metal |
| Windows GPU (CUDA) | via WSL2 | direct |
| Larger models (13B+) | slow | fast |
| Setup | `docker compose up` | OS installer + `ollama serve` |

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

Same Ollama HTTP API on `localhost:11434` as the Docker variant — the rest of cura's stack is interchangeable between the two.