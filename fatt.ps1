# Define the path to the directory
$directoryPath = "C:\Users\var\Backup\Work\20240406_173527"

# Get the current file attributes
$currentAttributes = [System.IO.File]::GetAttributes($directoryPath)

# Remove the hidden attribute if it's set
if ($currentAttributes -band [System.IO.FileAttributes]::Hidden) {
    $currentAttributes = $currentAttributes -bxor [System.IO.FileAttributes]::Hidden
}

# Remove the system attribute if it's set
if ($currentAttributes -band [System.IO.FileAttributes]::System) {
    $currentAttributes = $currentAttributes -bxor [System.IO.FileAttributes]::System
}

# Add the write attribute
$currentAttributes = $currentAttributes -bor [System.IO.FileAttributes]::ReadOnly

# Apply the modified attributes
[System.IO.File]::SetAttributes($directoryPath, $currentAttributes)

# Get the current file attributes again to verify the change
$newAttributes = [System.IO.File]::GetAttributes($directoryPath)
Write-Host "New Attributes: $newAttributes"
