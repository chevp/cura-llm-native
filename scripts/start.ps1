# Start the native Ollama server in the background on Windows.
# Reads .env (or .env.example) for runtime config.
# Usage: .\scripts\start.ps1
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

$host_port = ($env:OLLAMA_HOST -split ':')[-1]
if (Get-NetTCPConnection -LocalPort $host_port -State Listen -ErrorAction SilentlyContinue) {
    Write-Host "OK Ollama already listening on $($env:OLLAMA_HOST)"
    return
}

New-Item -ItemType Directory -Force -Path .run | Out-Null
$proc = Start-Process -FilePath 'ollama' -ArgumentList 'serve' `
    -RedirectStandardOutput .run\ollama.log -RedirectStandardError .run\ollama.err.log `
    -WindowStyle Hidden -PassThru
$proc.Id | Out-File -FilePath .run\ollama.pid -Encoding ascii
Start-Sleep -Seconds 2

if (Get-NetTCPConnection -LocalPort $host_port -State Listen -ErrorAction SilentlyContinue) {
    Write-Host "OK Ollama started on $($env:OLLAMA_HOST) (pid $($proc.Id))"
    Write-Host "   Logs: .run\ollama.log"
} else {
    Write-Error "Ollama failed to start. Tail of .run\ollama.log:"
    Get-Content .run\ollama.log -Tail 20 -ErrorAction SilentlyContinue
    exit 1
}