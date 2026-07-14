# Single entry point for native Windows (PowerShell) setup.
# Usage: .\install.ps1

$DotfilesDir = $PSScriptRoot

Write-Host "--- Starting Windows Setup ---" -ForegroundColor Cyan

# 1. Install Scoop
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..."
    $installScript = Invoke-RestMethod -Uri https://get.scoop.sh
    Invoke-Expression $installScript
    $env:PATH += ";$env:USERPROFILE\scoop\shims"
}

# 2. Install Core Tools
Write-Host "Installing git and uv..."
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    scoop install git uv
} else {
    Write-Error "Scoop installation failed or is not in PATH. Please restart PowerShell and run again."
}

# 3. Install MesloLGS NF Font
Write-Host "Installing MesloLGS NF Font..." -ForegroundColor Cyan
$fontUrl = "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
$fontDestination = Join-Path $env:TEMP "MesloLGS NF Regular.ttf"
Invoke-WebRequest -Uri $fontUrl -OutFile $fontDestination
$shellApp = New-Object -ComObject Shell.Application
$fontsFolder = $shellApp.Namespace(0x14)
$fontsFolder.CopyHere($fontDestination, 16)
Write-Host "Font installed successfully." -ForegroundColor Gray

# 4. Setup PowerShell Profile (Aliases)
Write-Host "--- Syncing Windows Aliases ---" -ForegroundColor Cyan
$ProfilePath = $PROFILE
if (!(Test-Path $ProfilePath)) {
    $null = New-Item -Path $ProfilePath -ItemType File -Force
}

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

# 5. SSH key + config
Write-Host "--- SSH Setup ---" -ForegroundColor Cyan
$sshDir = "$env:USERPROFILE\.ssh"
$configFile = "$sshDir\config"
$localHosts = Join-Path $DotfilesDir "ssh_config.local"

if (-not (Test-Path $sshDir)) { New-Item -Path $sshDir -ItemType Directory | Out-Null }

if (-not (Test-Path "$sshDir\gh")) {
    $email = Read-Host "Email for the SSH key comment (GitHub)"
    "y" | & ssh-keygen -t ed25519 -a 100 -C $email -f "$sshDir\gh" -N '""'
} else {
    Write-Host "$sshDir\gh already exists, skipping key generation."
}

$configContent = @"
Host github.com
    User git
    Hostname github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/gh
    IdentitiesOnly yes
"@
Set-Content -Path $configFile -Value $configContent

if (Test-Path $localHosts) {
    Write-Host "Appending personal host entries from ssh_config.local..."
    Add-Content -Path $configFile -Value "`n$(Get-Content $localHosts -Raw)"
} else {
    Write-Host "No ssh_config.local found - copy ssh_config.local.example if you need extra hosts."
}

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
icacls "$sshDir\gh" /inheritance:r /grant:r "${currentUser}:(R,W)" | Out-Null
icacls $configFile /inheritance:r /grant:r "${currentUser}:(R,W)" | Out-Null

Write-Host "`n--- Public key (add to GitHub: Settings -> SSH and GPG keys) ---"
Get-Content "$sshDir\gh.pub"

Write-Host "`n--- Windows Setup Complete! Restart PowerShell ---" -ForegroundColor Green
