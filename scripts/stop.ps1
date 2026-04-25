# Stop the native Ollama server started via start.ps1.
# Usage: .\scripts\stop.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

$pidFile = '.run\ollama.pid'
if (Test-Path $pidFile) {
    $serverPid = Get-Content $pidFile
    try {
        Stop-Process -Id $serverPid -Force -ErrorAction Stop
        Remove-Item $pidFile
        Write-Host "OK Ollama stopped"
        return
    } catch {
        Write-Warning "PID $serverPid not running; cleaning up."
        Remove-Item $pidFile -ErrorAction SilentlyContinue
    }
}

$running = Get-Process -Name ollama -ErrorAction SilentlyContinue
if ($running) {
    $running | Stop-Process -Force
    Write-Host "OK Killed stray ollama process(es)"
} else {
    Write-Host "i No running Ollama process found"
}