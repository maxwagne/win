function open-es {
    Param()

    # Get the current working directory
    $currentDirectory = Get-Location

    # Use the Start-Process cmdlet to open File Explorer
    Start-Process "explorer.exe" $currentDirectory
}

Export-ModuleMember -Function open-es