# cura-llm-native

Run an LLM **natively** for direct GPU access — Apple Metal (macOS) and CUDA (Windows). For larger models that don't fit the CPU-only Docker path. Submodule of [cura](https://github.com/chevp/cura).

📖 **Docs:** [chevp.github.io/cura-llm-native](https://chevp.github.io/cura-llm-native/)

---

## Why native (and not Docker)

Cura also ships [cura-llm-local](https://github.com/chevp/cura-llm-local), which runs Ollama in Docker for prod parity (production runs Linux/Docker on AWS). The trade-off there: Docker on macOS does not expose the Apple Silicon GPU, so the container is CPU-only — fine for 7B-q4 models, painful for anything larger.

This repo is the opposite trade-off: **native install, full GPU**. Use it when you want to run 13B / 34B / 70B models on a developer machine.

| | cura-llm-local (Docker) | **cura-llm-native (this repo)** |
|---|---|---|
| Prod parity | ✅ identical to AWS | ❌ host-specific |
| macOS GPU (Metal) | ❌ CPU-only | ✅ full Metal |
| Windows GPU (CUDA) | via WSL2 passthrough | ✅ direct |
| Larger models (13B+) | slow | fast |
| Setup | `docker compose up` | OS installer + `ollama serve` |

## Prerequisites

**macOS (Apple Silicon)**
- macOS 12+ on M1/M2/M3/M4
- [Homebrew](https://brew.sh)
- 16 GB unified memory minimum (32 GB+ for 13B–34B, 64 GB+ for 70B)

**Windows**
- Windows 10/11 x64
- NVIDIA GPU + recent driver (CUDA 12+) — required for GPU acceleration
- PowerShell 7+

## Quick start

### macOS

```bash
cp .env.example .env
./scripts/install.sh
./scripts/start.sh
./scripts/pull-model.sh llama3.1:8b-instruct-q4_K_M
./scripts/test-prompt.sh llama3.1:8b-instruct-q4_K_M "Was ist Metal?"
```

### Windows (PowerShell)

```powershell
Copy-Item .env.example .env
.\scripts\install.ps1
.\scripts\start.ps1
.\scripts\pull-model.ps1 llama3.1:8b-instruct-q4_K_M
.\scripts\test-prompt.ps1 llama3.1:8b-instruct-q4_K_M "Was ist CUDA?"
```

Direct API call (same on both platforms):

```bash
curl http://localhost:11434/api/generate \
  -d '{"model":"llama3.1:8b-instruct-q4_K_M","prompt":"Hello","stream":false}'
```

Interactive shell:

```bash
ollama run llama3.1:8b-instruct-q4_K_M
```

## Recommended models (GPU)

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

For a basic RAG stack (chat + embeddings):

```bash
./scripts/setup-rag.sh        # macOS
.\scripts\setup-rag.ps1       # Windows
```

## Configuration

`.env` is read by the start scripts and exported into the Ollama process:

| Variable | Default | Meaning |
|---|---|---|
| `OLLAMA_HOST` | `127.0.0.1:11434` | Bind address |
| `OLLAMA_KEEP_ALIVE` | `24h` | How long a model stays in (V)RAM after last request |
| `OLLAMA_MAX_LOADED_MODELS` | `2` | Parallel loaded models (chat + embed) |
| `OLLAMA_NUM_PARALLEL` | `1` | Concurrent requests per model |
| `OLLAMA_FLASH_ATTENTION` | `1` | Faster attention kernels (Metal + CUDA) |

## Stop / clean up

### macOS

```bash
./scripts/stop.sh                            # stop the server
ollama rm <model>                            # remove a single model
brew uninstall ollama && rm -rf ~/.ollama    # full removal incl. models
```

### Windows

```powershell
.\scripts\stop.ps1
ollama rm <model>
# Full removal: uninstall via Apps & Features, then:
Remove-Item -Recurse -Force "$env:USERPROFILE\.ollama"
```

## Platform notes

- **macOS Apple Silicon**: Ollama uses Metal automatically — no extra config. Watch unified-memory pressure with `mactop` or Activity Monitor; if you see swapping, drop to a smaller model.
- **Windows NVIDIA**: Ollama detects CUDA on launch. Verify with `ollama ps` (shows GPU layer count). If `0 layers on GPU`, your driver is too old or the model is too big — update the driver or pick a smaller model.
- **Windows AMD**: ROCm on Windows is experimental; expect CPU fallback. For AMD GPUs, prefer the Linux + Docker path in `cura-llm-local`.

## Troubleshooting

**`port already in use 11434`**
Another Ollama instance (Docker variant?) is running. Stop it, or set `OLLAMA_HOST=127.0.0.1:11435` in `.env`.

**macOS: model loads on CPU instead of Metal**
Confirm with `ollama ps`. If `100% CPU`, you likely installed an Intel build. Reinstall under arm64:
```bash
arch -arm64 brew reinstall ollama
```

**Windows: CUDA not detected**
Run `nvidia-smi`. If that fails, install/update the NVIDIA driver and reboot. After driver updates, restart Ollama.

**Out of memory loading a 70B model**
q4 70B needs ~46 GB. On 32 GB Macs, fall back to `mixtral:8x7b-instruct-q4_K_M` or `llama3.1:8b-instruct-q4_K_M`.

**Slow first response, fast afterwards**
Cold start: model is loading into (V)RAM. Increase `OLLAMA_KEEP_ALIVE` to keep it warm.

## Relation to cura

Submodule of [cura](https://github.com/chevp/cura) at `infrastructure/llm-native/`. Sister repos:

- [cura-llm-local](https://github.com/chevp/cura-llm-local) — Docker variant, prod-parity, CPU on macOS
- [cura-server](https://github.com/chevp/cura-server) — backend that talks to Ollama
- [cura-app](https://github.com/chevp/cura-app) — frontend chat UI

Either LLM repo exposes the same Ollama HTTP API on `localhost:11434`, so the rest of the stack is interchangeable.

## License

MIT