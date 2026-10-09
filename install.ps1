# Installs the harness plugin for your user (all projects).
# Run: powershell -ExecutionPolicy Bypass -File .\install.ps1
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Error "claude CLI not found on PATH"
}
$gitBash = @("$env:ProgramFiles\Git\bin\bash.exe", "${env:ProgramFiles(x86)}\Git\bin\bash.exe", "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe") |
  Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $gitBash) {
  Write-Warning "Git for Windows (Git Bash) not found. The hooks need it. Install it from https://git-scm.com/download/win"
}

claude plugin marketplace add "$dir"
claude plugin install harness@harness
Write-Host ""
Write-Host "Done. Start Claude Code in a project and run /harness:init"
Write-Host "Keep this folder where it is: Claude Code reads the plugin from it."
