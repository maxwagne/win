function Backup-es {
    param (
        [string]$Subfolder
    )

    # Get the current directory path
    $currentDirectory = Get-Location

    # Get the current date and time in the desired format
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

    # Define the backup folder path
    $backupFolder = "C:/Users/var/Backup"  # Assuming "var" is the user's name

    # Check if the backup folder exists, if not, create it
    if (!(Test-Path $backupFolder)) {
        New-Item -ItemType Directory -Path $backupFolder | Out-Null
    }

    # Construct the full backup folder name including the current date and time
    $backupFolderName = "$Subfolder`_$timestamp"

    # Define the full path for the backup folder
    $fullBackupFolderPath = Join-Path -Path $backupFolder -ChildPath $backupFolderName

    # Create the backup folder
    New-Item -ItemType Directory -Path $fullBackupFolderPath | Out-Null

    # Construct the path for the log file
    $logFile = Join-Path -Path $fullBackupFolderPath -ChildPath "log_$timestamp.txt"

    # Construct the robocopy command with best practice parameters and logging
    $robocopyCommand = "robocopy `"$currentDirectory`" `"$fullBackupFolderPath`" /e /COPY:DAT /R:1 /W:1 /TEE /NP /log:`"$logFile`""

    # Execute the robocopy command
    try {
        Invoke-Expression -Command $robocopyCommand -ErrorAction Stop
    } catch {
        Write-Host "Error executing robocopy command: $_"
        return
    }

    # Output confirmation message
    Write-Host "Backup completed. Files copied to: $fullBackupFolderPath"
    Write-Host "Log file: $logFile"

    # Move the log file to the backup folder
    try {
        Move-Item -Path $logFile -Destination $fullBackupFolderPath -ErrorAction Stop
        Write-Host "Log file moved to backup folder."
    } catch {
        Write-Host "Error moving log file: $_"
    }
}
