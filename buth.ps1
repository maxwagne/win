# Prompt for the drive letter to backup
$driveLetter = Read-Host -Prompt "Enter the drive letter you want to backup (e.g., D)"
$subfolder = Read-Host -Prompt "Enter the Backup Subfolder (e.g, Work)"

# Check if the specified drive exists
if (!(Test-Path "$($driveLetter):\")) {
    Write-Host "Specified drive doesn't exist. Exiting."
    exit
}

# Generate timestamp for the backup folder name
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFolder = "C:/Users/var/Backup/$subfolder/$timestamp"

# Create the backup folder
try {
    New-Item -ItemType Directory -Path $backupFolder -ErrorAction Stop | Out-Null
} catch {
    Write-Host "Error creating backup folder: $_"
    exit
}

# Construct the path for the log file
$logFile = "C:/Users/var/Backup/$subfolder/log_$timestamp.txt"

# Construct the robocopy command with logging
$robocopyCommand = "robocopy $($driveLetter):\$subfolder $backupFolder /mir /r:1 /w:1 /TEE /NP /log:`"$logFile`""

# Execute the robocopy command
try {
    Invoke-Expression -Command $robocopyCommand -ErrorAction Stop
} catch {
    Write-Host "Error executing robocopy command: $_"
    exit
}

# Output confirmation message
Write-Host "Backup completed. Files copied to: $backupFolder"
Write-Host "Log file: $logFile"

# Move the log file to the backup folder
try {
    Move-Item -Path $logFile -Destination $backupFolder -ErrorAction Stop
    Write-Host "Log file moved to backup folder."
} catch {
    Write-Host "Error moving log file: $_"
}
