function Compress-es {
    param (
        [string]$Path = "."
    )

    # Get the current directory
    $currentDir = Get-Location

    # Navigate to the specified path
    Set-Location $Path

    # Get the name of the current directory
    $folderName = (Get-Item $currentDir).Name

    # Get the parent directory
    $parentDir = Split-Path -Path $currentDir -Parent

    # Compress all files in the current directory into a zip file
    $zipFileName = Join-Path -Path $parentDir -ChildPath "$folderName.zip"
    Compress-Archive -Path "$currentDir\*" -DestinationPath $zipFileName

    # Navigate back to the original directory
    Set-Location $currentDir

    # Output the path of the created zip file
    Write-Output "Compressed files into: $zipFileName"
}
