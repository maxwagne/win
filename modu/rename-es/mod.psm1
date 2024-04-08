function Rename-ES {
    [CmdletBinding()]
    param ()

    # Get the current working directory
    $moduleFolderPath = Get-Location

    # Get a list of all folders in the current directory
    $moduleFolders = Get-ChildItem -Path $moduleFolderPath -Directory

    # Initialize variables to store changes and skipped files
    $changes = @()
    $skippedFiles = @()

    # Iterate through each module folder
    foreach ($folder in $moduleFolders) {
        $psmFiles = Get-ChildItem -Path $folder.FullName -Filter "*.psm1"

        # If there's exactly one .psm1 file in the folder
        if ($psmFiles.Count -eq 1) {
            $psmFile = $psmFiles[0].FullName
            $functionNames = Get-Content -Path $psmFile | Where-Object { $_ -match 'function\s+([^\s\(]+)' } | ForEach-Object { $matches[1] }

            # Check if any function name is found
            if ($functionNames -ne $null -and $functionNames.Count -gt 0) {
                $functionName = $functionNames -join "_" # Join multiple function names with underscore
                
                # Sanitize the function name
                $sanitizedFunctionName = $functionName -replace '[^\w\d]', '_' # Replace non-alphanumeric characters with underscores
                $sanitizedFunctionName = $sanitizedFunctionName -replace '\s+', '_' # Replace multiple spaces with a single underscore

                # Check if the folder is already named after the function
                if ($folder.Name -ne $sanitizedFunctionName) {
                    # Prompt before renaming
                    Write-Host "Function name: $sanitizedFunctionName"
                    Write-Host "Folder name: $($folder.Name)"
                    $confirmation = Read-Host "Press Enter to rename the folder or any other key to skip..."

                    # Check if user wants to skip renaming
                    if ($confirmation -eq "") {
                        # Rename the folder
                        Rename-Item -Path $folder.FullName -NewName $sanitizedFunctionName -ErrorAction SilentlyContinue
                        $changes += "Folder $($folder.Name) renamed to $sanitizedFunctionName"
                    }
                } else {
                    $changes += "Folder $($folder.Name) already named after the function $sanitizedFunctionName. Skipping."
                }
            } else {
                $skippedFiles += "No function found in $($psmFiles[0].Name), skipping folder $($folder.Name)"
            }
        } else {
            $skippedFiles += "Folder $($folder.Name) does not contain exactly one .psm1 file, skipping"
        }
    }

    # Output all changes and skipped files
    Write-Host "Changes:"
    $changes | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Skipped files:"
    $skippedFiles | ForEach-Object { Write-Host $_ }
}

# Call the function
Rename-ES
