# `.che/workflows/`

Local pipelines for `cura-llm-native`, runnable via [che-cli](https://chevp.github.io/che-cli/).

These YAML files are pointers — they declare order, args, and inputs but contain
no inline bash. The actual logic lives in [`scripts/`](../../scripts/), which
remains independently runnable for users without `che` installed.

## Workflows

| Workflow  | Purpose                                                              |
|-----------|----------------------------------------------------------------------|
| `up`      | Complete first-time setup: install Ollama → start → pull model → smoke-test |
| `rag-up`  | Start server + pull the RAG stack (chat model + embedding model)     |

## Usage

```sh
che workflow list                 # discover workflows
che workflow show up              # print parsed plan
che run up                        # complete first-time setup, defaults
che run up --model=mixtral:8x7b-instruct-q4_K_M
che run up --model=llama3.1:70b-instruct-q4_K_M --prompt="Was ist CUDA?"
che run rag-up                    # bring up the RAG-ready stack
che run up --dry-run              # plan only, no execution
```

## Manual fallback (no `che`)

Every step is a plain shell script, so the manual path from the README still
works one-to-one:

```sh
./scripts/install.sh
./scripts/start.sh
./scripts/pull-model.sh llama3.1:8b-instruct-q4_K_M
./scripts/test-prompt.sh llama3.1:8b-instruct-q4_K_M "Was ist Metal?"
```

## Notes

- **Bash-only.** che-cli runs on bash (macOS, Linux, Git Bash, WSL). Native
  PowerShell users on Windows should keep using the `scripts/*.ps1` variants
  directly — they are not wrapped here.
- **Stop / start are not workflows.** `./scripts/start.sh` and
  `./scripts/stop.sh` are single-step operations; per the che-cli authoring
  guidelines, they don't warrant a workflow file.
- **Scripts handle defaults.** When `--model` or `--prompt` is omitted, the
  empty substitution falls through to the script's own `${1:-default}` logic.

See the full che-cli workflow guide:
<https://chevp.github.io/che-cli/workflow.html>
