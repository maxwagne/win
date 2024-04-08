function Backup-Drive {
    param (
        [string]$DriveLetter,
        [string]$Subfolder
    )

    # Check if the specified drive exists
    if (!(Test-Path "$DriveLetter`:\")) {
        Write-Host "Specified drive doesn't exist. Exiting."
        return
    }

    # Generate timestamp for the backup folder name
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolder = "C:/Users/var/Backup/$Subfolder/$timestamp"

    # Create the backup folder
    try {
        New-Item -ItemType Directory -Path $backupFolder -ErrorAction Stop | Out-Null
    } catch {
        Write-Host "Error creating backup folder: $_"
        return
    }

    # Construct the path for the log file
    $logFile = "C:/Users/var/Backup/$Subfolder/log_$timestamp.txt"

    # Construct the robocopy command with logging
    $robocopyCommand = "robocopy $($DriveLetter):\$Subfolder $backupFolder /mir /r:1 /w:1 /TEE /NP /log:`"$logFile`""

    # Execute the robocopy command
    try {
        Invoke-Expression -Command $robocopyCommand -ErrorAction Stop
    } catch {
        Write-Host "Error executing robocopy command: $_"
        return
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
}
