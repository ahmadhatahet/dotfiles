# PowerShell Script for Incremental D: Drive Backup

<#
.SYNOPSIS
    This script performs an incremental backup of your D: drive to an external HDD
    using robocopy. It copies new files and updated versions of existing files,
    without deleting files from the destination that are no longer in the source.

.DESCRIPTION
    The script defines the source (your D: drive) and the destination (your external HDD).
    It uses 'robocopy' with specific flags to ensure only new or modified files are copied.
    A main log file is created for each backup run, detailing the operation.
    Additionally, a separate "error summary" log is created ONLY if robocopy
    reports errors, pointing to the main log for details.

.NOTES
    - Before running, ensure your external HDD is connected and you know its drive letter.
    - Modify the $destinationPath variable to match your external HDD's path.
    - Test with a small folder first to understand its behavior.
    - This script does NOT delete files from the destination if they are removed from the source.
      If you want a perfect mirror (where deletions on source are also applied to destination),
      change the robocopy flags to '/MIR' (and remove '/E /XO').
    - The console output will now show a progress bar for the current file being copied
      and the file name itself, but not a full list of all files being processed.
#>

# --- Force Administrator Rights Check ---
# This section ensures the script runs with elevated privileges.
# If not running as administrator, it will re-launch itself with admin rights.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting script with administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File", "`"$($MyInvocation.MyCommand.Path)`""
    exit
}
# --- End of Admin Check ---

# --- Configuration ---

# Source path (your D: drive)
$sourcePath = "D:\"

# Destination path (your external HDD).
# IMPORTANT: CHANGE THIS TO THE ACTUAL PATH OF YOUR EXTERNAL HDD.
# Example: "E:\D_Drive_Backup" or "F:\Backups\MyD_Drive"
$destinationPath = "E:\" # <--- !!! MODIFY THIS LINE !!!

# Log file directory
$logDirectory = "$env:USERPROFILE\Documents\RobocopyLogs"

# --- Script Logic ---

Write-Host "Starting D: Drive Backup..." -ForegroundColor Green

# Ensure the destination path exists
if (-not (Test-Path $destinationPath -PathType Container)) {
    Write-Host "Destination path '$destinationPath' does not exist. Creating it..." -ForegroundColor Yellow
    try {
        New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
        Write-Host "Destination path created successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to create destination path: $_"
        Write-Host "Please ensure the external HDD is connected and the path is correct." -ForegroundColor Red
        Read-Host "Press Enter to exit."
        exit 1
    }
}

# Ensure the log directory exists
if (-not (Test-Path $logDirectory -PathType Container)) {
    Write-Host "Log directory '$logDirectory' does not exist. Creating it..." -ForegroundColor Yellow
    try {
        New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
        Write-Host "Log directory created successfully." -ForegroundColor Green
    } catch {
        Write-Error "Failed to create log directory: $_"
        Write-Host "Backup will proceed without logging to file." -ForegroundColor Red
        $mainLogFile = $null # Disable logging to file
        $errorLogFile = $null # Disable error logging to file
    }
}

# Generate timestamps for log files
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$mainLogFile = Join-Path $logDirectory "D_Drive_Backup_Log_$timestamp.txt"
$errorSummaryLogFile = Join-Path $logDirectory "D_Drive_Backup_Errors_$timestamp.txt"

Write-Host "Source: $sourcePath"
Write-Host "Destination: $destinationPath"
Write-Host "Main Log File: $mainLogFile"

# Robocopy command with flags:
# /E        - Copies subdirectories, including empty ones.
# /XO       - Excludes older files (i.e., only copies newer or identical files).
#             This ensures only new files or newer versions of existing files are copied.
# /ZB       - Uses restartable mode; if access denied, uses Backup mode.
# /DCOPY:T  - Copies directory timestamps.
# /MT:16    - Multithreaded copying, 16 threads (can be adjusted).
# /R:3      - Number of retries on failed copies (default is 1 million, 3 is more reasonable).
# /W:1      - Wait time between retries (in seconds).
# /LOG+:$mainLogFile - Appends output to the main log file.
# /TEE      - Outputs to console window as well as the log file.
# /ETA      - Shows estimated time of arrival of copied files and the current file name.
#             (Removed /V for less verbose console output, removed /NP to allow progress bar)

Write-Host "`nStarting robocopy process... You will see progress for the current file." -ForegroundColor Cyan

try {
    robocopy $sourcePath $destinationPath /E /XO /ZB /DCOPY:T /MT:16 /R:3 /W:1 /LOG+:$mainLogFile /TEE /ETA

    # Check robocopy exit code for success/failure
    # Robocopy exit codes:
    # 0 - No files copied. No failure. No files match criteria.
    # 1 - All files copied successfully.
    # 2 - Some extra files or mismatched files were found. No failure.
    # 3 - Some files were copied. Some extra files or mismatched files were found. No failure.
    # 4 - Some mismatched files were found. No failure.
    # 5 - Some files were copied. Some mismatched files were found. No failure.
    # 6 - Some extra files were found. No failure.
    # 7 - Some files were copied. Some extra files were found. No failure.
    # 8 - Some files were not copied (e.g., due to permissions). This indicates a failure.
    # Any code >= 8 indicates at least one failure during the copy operation.

    $lastExitCode = $LASTEXITCODE

    if ($lastExitCode -ge 8) {
        Write-Error "Robocopy completed with errors (Exit Code: $lastExitCode). Please check the main log file for details: $mainLogFile"
        Write-Host "Backup completed with potential issues." -ForegroundColor Red

        # Write to the error summary log
        if ($errorSummaryLogFile) {
            "Error: Robocopy completed with exit code $lastExitCode, indicating errors." | Out-File -FilePath $errorSummaryLogFile -Encoding UTF8
            "Please review the main log file for full details: $mainLogFile" | Out-File -FilePath $errorSummaryLogFile -Append -Encoding UTF8
            Write-Host "An error summary has been saved to: $errorSummaryLogFile" -ForegroundColor Red
        }
    } elseif ($lastExitCode -ge 0 -and $lastExitCode -le 7) {
        Write-Host "`nRobocopy completed successfully (Exit Code: $lastExitCode)." -ForegroundColor Green
        Write-Host "Backup completed." -ForegroundColor Green
    } else {
        Write-Host "`nRobocopy completed with an unexpected exit code: $lastExitCode" -ForegroundColor Yellow
        Write-Host "Please check the main log file for details: $mainLogFile" -ForegroundColor Yellow
    }

} catch {
    Write-Error "An error occurred during the robocopy execution: $_"
    Write-Host "Backup process terminated due to an error." -ForegroundColor Red
    if ($errorSummaryLogFile) {
        "Critical Error: An unexpected PowerShell error occurred during script execution." | Out-File -FilePath $errorSummaryLogFile -Encoding UTF8
        "Error details: $_" | Out-File -FilePath $errorSummaryLogFile -Append -Encoding UTF8
        "Please review the main log file for any robocopy output: $mainLogFile" | Out-File -FilePath $errorSummaryLogFile -Append -Encoding UTF8
        Write-Host "A critical error summary has been saved to: $errorSummaryLogFile" -ForegroundColor Red
    }
}

Write-Host "`nBackup process finished. You can review the main log file at: $mainLogFile" -ForegroundColor DarkCyan
