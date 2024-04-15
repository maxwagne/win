# Aliases
Set-Alias vim nvim
Set-Alias v nvim
Set-Alias g git

# Module Importer
Import-Module posh-git

# Module Loader
# Determine the original location of the PowerShell profile
$originalProfilePath = $null
$symlinkPath = $PROFILE.CurrentUserAllHosts
if ((Get-Item $symlinkPath).LinkType -eq 'SymbolicLink') {
    $originalProfilePath = [System.IO.Path]::GetFullPath((Get-Item $symlinkPath).Target)
}

# Convert the user folder to lowercase
$symlinkPath = $symlinkPath.ToLower()
$originalProfilePath = $originalProfilePath.ToLower()

# Determine the path to the "modu" folder based on the original location of the profile
$moduleFolderPath = Join-Path -Path (Split-Path $originalProfilePath) -ChildPath "modu"

# Output the paths
Write-Output "The symlink location of your PowerShell profile is: $symlinkPath"
if ($originalProfilePath -ne $null) {
    Write-Output "The original location of your PowerShell profile is: $originalProfilePath"
}
Write-Output "The path of the 'modu' folder is: $moduleFolderPath"

# Recursively search for module files (*.psm1 and *.psd1) in all subfolders of the "modu" folder
$moduleFiles = Get-ChildItem -Path $moduleFolderPath -Recurse -Include "*.psm1", "*.psd1" -File

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

# Bracket Closer
Set-PSReadLineKeyHandler -Key '(', '{', '[' `
    -BriefDescription InsertPairedBraces `
    -LongDescription "Insert matching braces" `
    -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar) {
        '(' { [char]')'; break }
        '{' { [char]'}'; break }
        '[' { [char]']'; break }
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
}

Set-PSReadLineKeyHandler -Key ')', ']', '}' `
    -BriefDescription SmartCloseBraces `
    -LongDescription "Insert closing brace or skip" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line[$cursor] -eq $key.KeyChar) {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
    else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
    }
}
