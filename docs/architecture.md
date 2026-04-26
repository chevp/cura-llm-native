---
title: Architecture
---

# Architecture

How `cura-llm-native` fits into the cura stack, and why it exists alongside `cura-llm-local`.

## The two LLM repos

cura intentionally ships **two interchangeable LLM backends**, both speaking the same Ollama HTTP API on `localhost:11434`:

```
┌─────────────────────────────────────────────────────────────┐
│  cura-app (frontend)  ──HTTP──▶  cura-server (backend)      │
│                                       │                     │
│                                       ▼ HTTP /api/generate  │
│                       ┌───────────────────────────────┐     │
│                       │   localhost:11434  (Ollama)   │     │
│                       └───────────┬───────────────────┘     │
│                            same wire protocol              │
│                ┌───────────────────┴────────────────┐       │
│                ▼                                     ▼       │
│   cura-llm-local (Docker)            cura-llm-native (this)  │
│   • CPU on macOS                     • Apple Metal           │
│   • prod-parity with AWS             • NVIDIA CUDA           │
│   • 7B-q4 sweet spot                 • 13B / 34B / 70B       │
└─────────────────────────────────────────────────────────────┘
```

The contract is the **HTTP API**, not the install method. cura-server doesn't know (or care) which backend is running — it just calls `POST /api/generate`. Swap the backend; the rest of the stack keeps working.

## Why two backends?

Docker on macOS does not expose the Apple Silicon GPU. So:

| Use case | Backend |
|---|---|
| CI, prod, linux dev box | `cura-llm-local` (Docker, prod-parity) |
| macOS dev with M-series chip, want GPU | `cura-llm-native` (this repo) |
| Windows dev with NVIDIA GPU, want CUDA | `cura-llm-native` |
| Quick test, 7B-q4 is enough | `cura-llm-local` (one-command Docker) |

Picking the wrong one isn't catastrophic — small models work either way — but you'll see ~5–10× slowdown on >13B models running CPU-only.

## What `cura-llm-native` actually installs

```
brew install ollama
   ├── ollama (the daemon + CLI)
   ├── mlx, mlx-c (Apple Silicon ML runtime, used by some models)
   ├── python@3.14 (Ollama dependency)
   └── sqlite, openssl, ca-certificates (transitive)
```

Models are *not* installed by `install.sh` — they are pulled on demand into `~/.ollama/models/` by `pull-model.sh`. This keeps the install footprint small (~150 MB) and lets each developer choose their model size.

## Runtime layout

After `start.sh`:

```
cura-llm-native/
├── .env                    # OLLAMA_HOST=127.0.0.1:11434 (or :11435)
├── .run/
│   ├── ollama.pid          # PID of the nohup'd ollama serve
│   └── ollama.log          # stdout + stderr
└── scripts/                # thin shell wrappers around ollama CLI / HTTP
```

The actual Ollama daemon (`ollama serve`) runs as a normal user process — no LaunchDaemon, no Docker, no systemd. `start.sh` / `stop.sh` are the lifecycle.

Models live in `~/.ollama/models/` (shared across all Ollama instances on the machine, including `brew services start ollama` if you ever run it that way).

## Network surface

Default bind: `127.0.0.1:<port>` — **loopback only**. Nothing on the LAN can reach it. To expose on the LAN (e.g., for testing from a phone):

```bash
OLLAMA_HOST=0.0.0.0:11434
```

⚠️ The Ollama API has **no authentication**. Anyone who can reach the port can run any model and any prompt — and consume your GPU time. Only bind on `0.0.0.0` on a trusted network.

## Coexistence with `cura-llm-local`

Both repos can be installed on the same machine. They cannot listen on the same port at the same time. Conventions for cura developers:

- **Docker variant on `11434`** (the production-parity port).
- **Native variant on `11435`** (set in `.env` as `OLLAMA_HOST=127.0.0.1:11435`).

Pointing cura-server at one or the other is a one-line `.env` change in cura-server.

## Migration to/from `cura-llm-local`

You can re-pull the same model name in both backends — Ollama uses the same model registry. Pulled models are **not** shared between the two (Docker has its own volume, native uses `~/.ollama/`), so expect to download twice if you switch.

Prompts and responses are bit-for-bit identical for the same model + temperature, so behavioral testing in one backend is valid for the other.
