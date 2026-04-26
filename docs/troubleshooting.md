---
title: Troubleshooting
---

# Troubleshooting

Concrete failure modes seen in the wild on cura developer machines, with the diagnosis path and fix.

## `null` response from `test-prompt.sh`

```
$ ./scripts/test-prompt.sh llama3.1:8b-instruct-q4_K_M "Was ist Metal?"
null
```

`null` means: the HTTP call succeeded, but the JSON returned by Ollama did **not** contain a `.response` field — `jq -r '.response'` then prints the literal `null`. Three real causes:

### 1. Model is not pulled

Most common. The script doesn't auto-pull; missing models surface as:

```bash
curl -s http://127.0.0.1:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"model":"llama3.1:8b-instruct-q4_K_M","prompt":"x","stream":false}'
# {"error":"model 'llama3.1:8b-instruct-q4_K_M' not found"}
```

**Fix:** `./scripts/pull-model.sh llama3.1:8b-instruct-q4_K_M` and retry.

### 2. You're talking to the wrong Ollama

If `cura-llm-local` (Docker) is up on `11434` and you started the native Ollama on a different port (or it failed to start), `test-prompt.sh` may hit the Docker container — which has a *different* set of pulled models. `model not found` again, but for a different reason.

**Fix:** confirm which Ollama you're hitting, and that it has the model:

```bash
echo $OLLAMA_HOST                     # what start.sh / test-prompt.sh use
lsof -iTCP:11434 -sTCP:LISTEN         # who is on the conflict port
curl -s http://${OLLAMA_HOST:-127.0.0.1:11434}/api/tags | jq -r '.models[].name'
```

If the listening process is `com.docke...`, it's the Docker variant. See [Port conflict](#port-conflict-with-cura-llm-local).

### 3. Server isn't running at all

```bash
curl -s http://127.0.0.1:11434/api/tags
# (empty) — connection refused
```

**Fix:** `./scripts/start.sh`. If start fails, read `.run/ollama.log`.

## Port conflict with `cura-llm-local`

```
Error: listen tcp 127.0.0.1:11434: bind: address already in use
```

Both repos default to `11434`. Both expose the same Ollama HTTP API. Only one can own the port at a time.

**The cura convention:** Docker on `11434` (prod-parity), native on `11435`. Edit `.env`:

```bash
OLLAMA_HOST=127.0.0.1:11435
```

Then `./scripts/stop.sh && ./scripts/start.sh`. Update any client (cura-server `.env`, `curl` examples) to point at `:11435`.

## Model loads on CPU instead of Metal

Confirm with `ollama ps`. If the `PROCESSOR` column shows `100% CPU`, Metal is *not* active.

Cause: Intel build of Ollama under Rosetta. Re-install under native arm64:

```bash
which ollama
# /usr/local/bin/ollama   → BAD (Intel/Rosetta)
# /opt/homebrew/bin/ollama → GOOD (arm64)

arch -arm64 brew reinstall ollama
./scripts/stop.sh && ./scripts/start.sh
```

## Out of memory loading a model

q4 70B needs ~46 GB unified memory. If macOS swaps heavily during model load (`Activity Monitor → Memory Pressure` red), fall back to a smaller model:

| Symptom | Try |
|---|---|
| Beachball, swap > 5 GB during load | drop one tier (70B → mixtral 8x7b → 8b) |
| Load succeeds but inference is slow | `OLLAMA_FLASH_ATTENTION=1` already on? Lower `OLLAMA_NUM_PARALLEL` to `1` |
| GPU offload fails silently | check `~/.ollama/logs/server.log` for `unable to allocate` |

## Slow first response, fast afterwards

Cold start: the model is loading from disk into unified memory (~3–8 s for 8B, ~30 s for 70B). After that, subsequent prompts hit a warm model.

If models keep cold-starting between requests, raise `OLLAMA_KEEP_ALIVE`:

```bash
OLLAMA_KEEP_ALIVE=24h     # default — model stays warm 24 h after last use
OLLAMA_KEEP_ALIVE=-1      # never unload (eats memory until restart)
```

## Server won't start, no useful error

Always check the server log first:

```bash
tail -n 50 .run/ollama.log
```

Common entries:

| Log line | Meaning |
|---|---|
| `bind: address already in use` | Port conflict — see above |
| `Couldn't find ... id_ed25519` | First-run only; harmless, key is generated |
| `panic: ... metal` | Bad install or macOS too old (need 12+) |
| `failed to load model` | Disk full, corrupt download — `ollama rm <model>` and re-pull |

## Reset to a clean slate

```bash
./scripts/stop.sh
brew uninstall ollama
rm -rf ~/.ollama .run
brew install ollama        # or re-run ./scripts/install.sh
```

This drops every pulled model. Pull what you need again.
