# Run a one-shot prompt against the local Ollama HTTP API.
# Usage: .\scripts\test-prompt.ps1 [model] [prompt]
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$envFile = '.env'
if (-not (Test-Path $envFile)) { $envFile = '.env.example' }

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
    if ($_ -match '^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*)\s*$') {
        $name = $Matches[1]
        $value = $Matches[2].Trim('"').Trim("'")
        Set-Item -Path "Env:$name" -Value $value
    }
}

$model = if ($args.Count -ge 1) { $args[0] } else { 'llama3.1:8b-instruct-q4_K_M' }
$prompt = if ($args.Count -ge 2) { $args[1] } else { 'Erkläre CUDA in einem Satz.' }
$ollamaHost = if ($env:OLLAMA_HOST) { $env:OLLAMA_HOST } else { '127.0.0.1:11434' }

$body = @{ model = $model; prompt = $prompt; stream = $false } | ConvertTo-Json -Compress
$response = Invoke-RestMethod -Uri "http://$ollamaHost/api/generate" -Method Post -ContentType 'application/json' -Body $body
Write-Output $response.response