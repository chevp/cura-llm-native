# Install Ollama natively on Windows via winget.
# Usage: .\scripts\install.ps1
$ErrorActionPreference = 'Stop'

if ($IsLinux -or $IsMacOS) {
    Write-Error "This script targets Windows. For macOS use scripts/install.sh."
    exit 1
}

if (Get-Command ollama -ErrorAction SilentlyContinue) {
    $version = (ollama --version) -join ' '
    Write-Host "OK Ollama already installed: $version"
    return
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget is required. Install 'App Installer' from the Microsoft Store, or download Ollama directly from https://ollama.com/download/windows."
    exit 1
}

Write-Host "-> Installing Ollama via winget..."
winget install --id Ollama.Ollama --accept-source-agreements --accept-package-agreements

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Write-Warning "Installation completed but 'ollama' not on PATH. Open a new PowerShell window and try again."
    exit 1
}

$version = (ollama --version) -join ' '
Write-Host "OK Ollama installed: $version"