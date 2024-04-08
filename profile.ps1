# Specify the path to the "modu" folder
$moduleFolderPath = "C:\Users\var\Src\modu"

# Recursively search for module files (*.psm1) in all subfolders of the "modu" folder
$moduleFiles = Get-ChildItem -Path $moduleFolderPath -Recurse -Filter "*.psm1" -File

# Import each module found
foreach ($moduleFile in $moduleFiles) {
    try {
        Import-Module -Name $moduleFile.FullName -ErrorAction Stop
        Write-Host "Module $($moduleFile.Name) loaded successfully."
    } catch {
        Write-Host "Failed to load module $($moduleFile.Name): $_"
    }
}

Get-Module -Name "*mod*"