---
title: Installation Walkthrough
---

# Installation Walkthrough (macOS)

Step-by-step guide for installing `cura-llm-native` on Apple Silicon. The TL;DR is in the [README]({{ site.github.repository_url | default: "https://github.com/chevp/cura-llm-native" }}#quick-start) — this page explains **what each step does**, **how to verify it**, and **what the common failure modes look like**.

> Windows users: the PowerShell variant follows the same logic. Replace `*.sh` with `*.ps1` throughout.

## 0. Prerequisites

| | Required | Verify |
|---|---|---|
| macOS | 12+ on Apple Silicon (M1/M2/M3/M4) | `uname -sm` → `Darwin arm64` |
| Homebrew | any recent version | `brew --version` |
| Disk | 10 GB free per model (q4 8B ≈ 5 GB; q4 70B ≈ 40 GB) | `df -h ~` |
| RAM | 16 GB minimum, 32 GB+ for 13B–34B, 64 GB+ for 70B | `sysctl -n hw.memsize` |

If `brew` is missing, install from [brew.sh](https://brew.sh) first. The install script will refuse to continue without it.

## 1. Clone & configure

```bash
git clone https://github.com/chevp/cura-llm-native.git
cd cura-llm-native
cp .env.example .env
```

The `.env` file controls the runtime. Defaults are sensible — only edit if you hit a port conflict (see [§3](#3-start-the-server)) or want to bind on the LAN (`OLLAMA_HOST=0.0.0.0:11434`).

| Variable | Default | When to change |
|---|---|---|
| `OLLAMA_HOST` | `127.0.0.1:11434` | Conflict with `cura-llm-local` (Docker) → set `:11435` |
| `OLLAMA_KEEP_ALIVE` | `24h` | Lower if you want models unloaded after idle |
| `OLLAMA_MAX_LOADED_MODELS` | `2` | Raise only if you have headroom for chat + embed + extras |
| `OLLAMA_NUM_PARALLEL` | `1` | Raise for a multi-user setup |
| `OLLAMA_FLASH_ATTENTION` | `1` | Set `0` only when debugging unexpected output |

## 2. Install Ollama

```bash
./scripts/install.sh
```

What happens:

1. Verifies you are on `Darwin` (arm64).
2. Verifies `brew` is on `PATH`.
3. Either prints `✓ Ollama already installed` and exits, or runs `brew install ollama` (pulls in `mlx`, `mlx-c`, `python@3.14`, `sqlite`, `openssl@3` as dependencies).

**Verify:**

```bash
ollama --version          # ollama version is 0.21.2 (or newer)
which ollama              # /opt/homebrew/bin/ollama → confirms arm64 build
```

If `which ollama` resolves under `/usr/local/...` you have the Intel build under Rosetta — re-install under arm64:

```bash
arch -arm64 brew reinstall ollama
```

## 3. Start the server

```bash
./scripts/start.sh
```

What happens:

1. Sources `.env` and reads `OLLAMA_HOST`.
2. Probes the port — if something already listens, prints `✓ Ollama already listening` and exits.
3. Launches `ollama serve` via `nohup`, writes the PID to `.run/ollama.pid` and stdout/stderr to `.run/ollama.log`.
4. Sleeps 2 s and re-probes the port; reports success or tails the log on failure.

**Verify:**

```bash
curl -s http://127.0.0.1:11434/api/tags | jq .
# {"models": []}     ← fresh install, no models yet
```

### 3a. Port conflict with `cura-llm-local` (Docker variant)

The most common failure on cura developer machines:

```
Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

Both `cura-llm-local` (Docker) and `cura-llm-native` default to port `11434`. They cannot run side-by-side on the same port. Pick one:

**Option A — keep both, native on 11435** (recommended for cura devs)

```bash
# .env
OLLAMA_HOST=127.0.0.1:11435
```

Then restart: `./scripts/stop.sh && ./scripts/start.sh`.

**Option B — stop the Docker variant**

```bash
docker compose -f /path/to/cura-llm-local/docker-compose.yml down
./scripts/start.sh
```

Identify which Ollama is bound to the port:

```bash
lsof -iTCP:11434 -sTCP:LISTEN
# COMMAND     PID  USER ...
# com.docke   ...           ← Docker variant
# ollama      ...           ← native variant
```

## 4. Pull a model

```bash
./scripts/pull-model.sh llama3.1:8b-instruct-q4_K_M
```

What happens: a streaming download from the Ollama registry into `~/.ollama/models/`. The default 8B model is ~5 GB — expect a few minutes on a fast connection.

Pick the right model for your machine:

| Unified memory | Recommended max model | Disk |
|---|---|---|
| 16 GB | `llama3.1:8b-instruct-q4_K_M` | ~5 GB |
| 32 GB | `mixtral:8x7b-instruct-q4_K_M` | ~26 GB |
| 64 GB+ | `llama3.1:70b-instruct-q4_K_M` | ~40 GB |
| any | `nomic-embed-text` (embeddings) | ~270 MB |

**Verify:**

```bash
ollama list
# NAME                              SIZE     MODIFIED
# llama3.1:8b-instruct-q4_K_M       4.7 GB   1 minute ago
```

## 5. Smoke-test

```bash
./scripts/test-prompt.sh llama3.1:8b-instruct-q4_K_M "Was ist Apple Metal?"
```

A correct answer is a paragraph of text. If you get `null`, see [Troubleshooting → null response](troubleshooting.md#null-response-from-test-promptsh).

**Verify GPU utilization** while the model is loaded:

```bash
ollama ps
# NAME                              PROCESSOR
# llama3.1:8b-instruct-q4_K_M       100% GPU      ← Metal active
```

If `ollama ps` shows `100% CPU`, the model is running on CPU — almost always because the wrong arch was installed (see [§2](#2-install-ollama)).

## 6. Optional: RAG stack

For chat + embeddings (cura's default RAG configuration):

```bash
./scripts/setup-rag.sh
```

This pulls one chat model and `nomic-embed-text` so the server can keep both warm (`OLLAMA_MAX_LOADED_MODELS=2`).

## Where to next

- [Troubleshooting](troubleshooting.md) — port conflicts, `null` responses, CPU fallback, OOM
- [Recommended models](models.md) *(coming soon)*
- [README]({{ site.github.repository_url | default: "https://github.com/chevp/cura-llm-native" }}) — the canonical reference
