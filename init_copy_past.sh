& {
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
        Write-Error "Scoop installation failed or is not in PATH."
    }

    # 3. Install MesloLGS NF Regular Font
    Write-Host "Installing MesloLGS NF Font..." -ForegroundColor Cyan
    $fontUrl = "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    $fontName = "MesloLGS NF Regular.ttf"
    $fontDestination = Join-Path $env:TEMP $fontName

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
    Write-Host "--- Windows Setup Complete! Restart PowerShell ---" -ForegroundColor Green
}
