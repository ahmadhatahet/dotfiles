# init.ps1 - Run as Administrator
Write-Host "--- Starting Windows Setup ---" -ForegroundColor Cyan

# 1. Install Scoop (The 'Brew' for Windows) to manage uv and git
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Get https://get.scoop.sh | iex
}

# 2. Install Core Tools
Write-Host "Installing git and uv..."
scoop install git uv

# 3. Setup PowerShell Profile (Aliases)
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) {
    New-Item -Path $ProfilePath -ItemType File -Force
}

# init.ps1
Write-Host "--- Syncing Windows Aliases with Linux Dotfiles ---" -ForegroundColor Cyan

$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) { New-Item -Path $ProfilePath -ItemType File -Force }

$CustomFunctions = @"
# --- Core Navigation ---
function home { Set-Location `$HOME }
function devdir { Set-Location 'D:\scripts\' }
function l { Get-ChildItem @args }
function ll { Get-ChildItem @args | Select-Object Mode, LastWriteTime, Length, Name }
function la { Get-ChildItem -Force @args }

# --- Git Pro Shortcuts ---
function g { git @args }
function gs { git status -sb @args }
function ga { git add @args }
function gaa { git add --all @args }
function gc { git commit -m `$args }
function gp { git push @args }
function gpl { git pull @args }
function gup { git pull --rebase @args }
function gl { git log --oneline --graph --decorate @args }
function gd { git diff @args }
function gco { git checkout @args }
function gcb { git checkout -b @args }

# --- Tools ---
function wnv { while(`$true) { clear; nvidia-smi; Start-Sleep -Milliseconds 300 } }
function explorer { explorer.exe . }
"@

Set-Content -Path $ProfilePath -Value $CustomFunctions
Write-Host "Aliases successfully synchronized to `$PROFILE." -ForegroundColor Green

Write-Host "--- Windows Setup Complete! Restart PowerShell ---" -ForegroundColor Green
