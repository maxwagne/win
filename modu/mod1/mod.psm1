function Remove-FileAttributes {
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
