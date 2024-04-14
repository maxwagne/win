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

Export-ModuleMember -Function compress-es