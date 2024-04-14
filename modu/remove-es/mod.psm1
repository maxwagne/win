function remove-es {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path
    )

    process {
        if (Test-Path $Path) {
            if ($PSCmdlet.ShouldProcess("Removing item at $Path","Confirm")) {
                Remove-Item $Path -Force -Recurse
            }
        }
        else {
            Write-Error "The specified path '$Path' does not exist."
        }
    }
}

Export-ModuleMember -Function remove-es
