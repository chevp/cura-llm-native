# Pull a model into the local Ollama store.
# Usage: .\scripts\pull-model.ps1 [model-name]
$ErrorActionPreference = 'Stop'
$model = if ($args.Count -ge 1) { $args[0] } else { 'llama3.1:8b-instruct-q4_K_M' }
ollama pull $model
Write-Host "OK Model '$model' is ready"