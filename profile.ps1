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