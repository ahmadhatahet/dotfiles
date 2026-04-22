# Define variables - Replace the email string with your own
$email = "REPLACE_WITH_YOUR_EMAIL"
$sshDir = "$env:USERPROFILE\.ssh"
$configFile = "$sshDir\config"

if (-not (Test-Path $sshDir)) { New-Item -Path $sshDir -ItemType Directory }

Write-Host "Generating Secure Ed25519 Keys..."

# 1. Generate Keys
"y" | & ssh-keygen -t ed25519 -a 100 -C $email -f "$sshDir\tuc_gitlab" -N '""'
"y" | & ssh-keygen -t ed25519 -a 100 -C $email -f "$sshDir\gh" -N '""'

# 2. Generate SSH Config
# We use 'User git' because the platform identifies YOU via the key.
$configContent = @"
Host github.com
    User git
    Hostname github.com
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/gh
    IdentitiesOnly yes

Host gitlab.tu-clausthal.de
    HostName gitlab.tu-clausthal.de
    User git
    IdentityFile ~/.ssh/tuc_gitlab
    IdentitiesOnly yes

Host ai121
    HostName 139.174.67.121
    User ah19
    PreferredAuthentications password

Host ai122
    HostName 139.174.67.122
    User ah19
    PreferredAuthentications password

Host ai123
    HostName 139.174.67.123
    User ah19
    PreferredAuthentications password

Host ai124
    HostName 139.174.67.124
    User ah19
    PreferredAuthentications password

Host ai125
    HostName 139.174.67.125
    User ah19
    PreferredAuthentications password

Host a100_tuc
    HostName cloud-243.rz.tu-clausthal.de
    User ah19
    PreferredAuthentications password

Host h100_tuc
    HostName cloud-247.rz.tu-clausthal.de
    User ah19
    PreferredAuthentications password
"@

Set-Content -Path $configFile -Value $configContent

# 3. Fix Windows Permissions (The "Too Open" Error Fix)
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
icacls "$sshDir\tuc_gitlab" /inheritance:r /grant:r "${currentUser}:(R,W)"
icacls "$sshDir\gh" /inheritance:r /grant:r "${currentUser}:(R,W)"
icacls $configFile /inheritance:r /grant:r "${currentUser}:(R,W)"

Write-Host "`nSuccessfully configured! Copy the keys below to your Profile Settings:"
Write-Host "--- GitLab Key ---"
Get-Content "$sshDir\tuc_gitlab.pub"
Write-Host "`n--- GitHub Key ---"
Get-Content "$sshDir\gh.pub"
