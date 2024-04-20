function backup-es {
    param (
        [string]$Subfolder
    )

    # Get the current directory path
    $currentDir = Get-Location

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
    $robocopyCommand = "robocopy `"$currentDir`" `"$fullBackupFolderPath`" /e /COPY:DAT /R:1 /W:1 /TEE /NP /log:`"$logFile`""

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

function compress-es {
    # Get the current directory
    $currentDir = Get-Location

    # Get the name of the current directory
    $folderName = (Get-Item $currentDir).Name

    # Get the parent directory
    $parentDir = Split-Path -Path $currentDir -Parent

    # Compress all files in the current directory into a zip file
    $zipFileName = Join-Path -Path $parentDir -ChildPath "$folderName.zip"
    Compress-Archive -Path "$currentDir\*" -DestinationPath $zipFileName

    # Output the path of the created zip file
    Write-Output "Compressed files into: $zipFileName"
}

function open-es {
    Param()

    # Get the current working directory
    $currentDir = Get-Location

    # Use the Start-Process cmdlet to open File Explorer
    Start-Process "explorer.exe" $currentDir
}

# Save this code in a .psm1 file (e.g., MyModule.psm1) within a PowerShell module directory.

function remove-es {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
        [string]$Path = (Get-Location)
    )

    process {
        if (-not (Test-Path $Path)) {
            Write-Error "The specified path '$Path' does not exist."
            return
        }

        $parentPath = (Get-Item $Path).FullName | Split-Path -Parent  # Get the parent directory

        if ($PSCmdlet.ShouldProcess("Removing item at $Path","Confirm")) {
            Set-Location $parentPath  # Change current directory to the parent directory
            Remove-Item $Path -Force -Recurse -ErrorAction SilentlyContinue  # Remove the directory and its contents
        }
    }
}


function save-es {
    # Step 1: Git status
    git status

    # Step 2: Git add .
    git add .

    # Step 3: Git commit -m
    $commitMessage = "standard"
    if ($args.Count -gt 0) {
        $commitMessage = $args[0]
    }
    git commit -m $commitMessage

    # Step 4: Git push origin master
    git push origin master
}

function set-es {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string]$Path = '.'
    )

    if ($Path -eq '.') {
        $Path = $PWD.Path
    }

    Write-Host "Processing path: $Path"

    try {
        # Get the current file attributes
        $currentAttributes = [System.IO.File]::GetAttributes($Path)

        Write-Host "Current Attributes for ${Path}: ${currentAttributes}"

        # Remove the hidden attribute if it's set
        if ($currentAttributes -band [System.IO.FileAttributes]::Hidden) {
            $currentAttributes = $currentAttributes -bxor [System.IO.FileAttributes]::Hidden
        }

        # Remove the system attribute if it's set
        if ($currentAttributes -band [System.IO.FileAttributes]::System) {
            $currentAttributes = $currentAttributes -bxor [System.IO.FileAttributes]::System
        }

        # Apply the modified attributes
        [System.IO.File]::SetAttributes($Path, $currentAttributes)

        # Get the new file attributes to verify the change
        $newAttributes = [System.IO.File]::GetAttributes($Path)
        Write-Host "New Attributes for ${Path}: ${newAttributes}"
    } catch {
        Write-Host "Error occurred: $_"
    }
}

function enter-es {
    param(
        [string]$theme
    )

    # Build the path based on the provided theme
    $themeFilePath = "C:\Windows\Resources\Themes\${theme}.theme"

    # Check if the theme file exists
    if (Test-Path $themeFilePath) {
        # Open the theme file
        Invoke-Item $themeFilePath

        Write-Output "Changed theme to $theme."
    } else {
        Write-Error "Theme file $themeFilePath not found."
    }
}
