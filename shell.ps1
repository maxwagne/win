

try {
    # Start Transcript
# Start Transcript

    Write-Host " "
    Start-Transcript -Path "$env:USERPROFILE\ShellLog.txt" -Append
    Write-Host " "

    $status = @{}


# Profile Availability --------------------------------------------------------------------
# Check if Profiles are available
$profilePaths = @(
    $Profile.AllUsersAllHosts,
    $Profile.AllUsersCurrentHost,
    $Profile.CurrentUserAllHosts,
    $Profile.CurrentUserCurrentHost
)

$profileAvailable = $false
foreach ($path in $profilePaths) {
    if (Test-Path $path) {
        Write-Host "Profile script found in $path"
        $profileAvailable = $true
    } else {
        Write-Host "Profile script not found in $path"
    }
}

if ($profileAvailable) {
    $status["ProfileAvailability"] = "OK"
} else {
    $status["ProfileAvailability"] = "ERROR"
}

Write-Host "|--Profile Availability: ----------------$($status["ProfileAvailability"])--|"
Write-Host " "


    # If profile is available, skip profile location selection and symlink creation
    if (-not $profileAvailable) {
        $confirmChange = Read-Host "Do you want to create a symlink in one of the possible locations? (Y/N)"
           if ($confirmChange -eq "Y") {

                # Select Profile Location
                Write-Host "Select Profile Location:"
                Write-Host "1. All Users, All Hosts"
                Write-Host "2. All Users, Current Host"
                Write-Host "3. Current User, All Hosts"
                Write-Host "4. Current User, Current Host"
                $choice = Read-Host "Enter your choice (1-4)"

                # Set the profile location based on user choice
                switch ($choice) {
                    1 { $profileLocation = $Profile.AllUsersAllHosts }
                    2 { $profileLocation = $Profile.AllUsersCurrentHost }
                    3 { $profileLocation = $Profile.CurrentUserAllHosts }
                    4 { $profileLocation = $Profile.CurrentUserCurrentHost }
                    default { throw "Invalid choice. Please enter a number between 1 and 4." }
                }


                # Create symlink for profile script
                $profileScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "profile.ps1"
                New-Item -Path $profileLocation -ItemType SymbolicLink -Value $profileScriptPath -Force

                Write-Host "Symlink created at $profileLocation pointing to $profileScriptPath"

                $status["ProfileLocationSelection"] = "OK"

                }

                else {
                 $status["ProfileLocationSelection"] = "DENIED"
                 }          
    }
    else {
        $status["ProfileLocationSelection"] = "SKIP"
    }
            
    Write-Host "|--Profile Location Selection: ----------$($status["ProfileLocationSelection"])--|"
    Write-Host " "


# Module Path Setting --------------------------------------------------------------------
# Output the Module Environment Variable:
$modulePaths = $env:PSModulePath -split ';'
foreach ($index in 0..($modulePaths.Count - 1)) {
    Write-Output "$index. Module path found in: $($modulePaths[$index])"
}
Write-Host " "

function Get-ModulePaths {
    $modulePaths = $env:PSModulePath -split ';'
    foreach ($index in 0..($modulePaths.Count - 1)) {
        Write-Output "$index. Module path found in: $($modulePaths[$index])"
    }
    Write-Host " "
}

function Remove-EmptyPaths {
    $emptyIndices = @()
    $modulePaths = $env:PSModulePath -split ';'
    foreach ($index in 0..($modulePaths.Count - 1)) {
        if ($modulePaths[$index] -eq '') {
            $emptyIndices += $index
        }
    }

    if ($emptyIndices.Count -gt 0) {
        Write-Host "Empty entries found in PSModulePath."
        $confirmDelete = Read-Host "Do you want to remove them? (Y/N)"
        if ($confirmDelete -eq "Y") {
            $modulePaths = $modulePaths -ne ''
            $newPSModulePath = $modulePaths -join ";"
            [Environment]::SetEnvironmentVariable("PSModulePath", $newPSModulePath, "User")
            Write-Host "Empty entries removed from PSModulePath."
        }
    }
}

# Check and remove empty entries from PSModulePath
Remove-EmptyPaths

function Manage-ModulePaths {
    param (
        [string]$Action
    )

    Get-ModulePaths
    $choice = Read-Host "Enter the modification you want to perform (A for Add, D for Delete, L for Leave)"

    switch ($choice) {
        "A" {
            $indexChoice = Read-Host "Enter the index of the module path you want to $Action"
            if ($indexChoice -match '^\d+$') {
                $index = [int]$indexChoice
                if ($index -ge 0 -and $index -lt $modulePaths.Count) {
                    $pathToAdd = $modulePaths[$index]
                    $confirmAdd = Read-Host "Are you sure you want to add '$pathToAdd'? (Y/N)"
                    if ($confirmAdd -eq "Y") {
                        $newPath = Read-Host "Enter the new module path"
                        $newPSModulePath = "$env:PSModulePath;$newPath"
                        [Environment]::SetEnvironmentVariable("PSModulePath", $newPSModulePath, "Machine")
                        Write-Host "Module path set to $env:PSModulePath"
                        $status["ModulePathSetting"] = "SET"
                    } else {
                        Write-Host "Add operation canceled."
                        $status["ModulePathSetting"] = "CANCELED"
                    }
                } else {
                    Write-Host "Invalid index."
                    $status["ModulePathSetting"] = "ERROR"
                }
            } else {
                Write-Host "Invalid index."
                $status["ModulePathSetting"] = "ERROR"
            }
        }
        "D" {
            $indexChoice = Read-Host "Enter the index of the module path you want to $Action"
            if ($indexChoice -match '^\d+$') {
                $index = [int]$indexChoice
                if ($index -ge 0 -and $index -lt $modulePaths.Count) {
                    $pathToDelete = $modulePaths[$index]
                    $confirmDelete = Read-Host "Are you sure you want to delete '$pathToDelete'? (Y/N)"
                    if ($confirmDelete -eq "Y") {
                        $modulePaths = $modulePaths -ne $modulePaths[$index]
                        $newPSModulePath = $modulePaths -join ";"
                        [Environment]::SetEnvironmentVariable("PSModulePath", $newPSModulePath, "Machine")
                        Write-Host "Module path set to $env:PSModulePath"
                        $status["ModulePathSetting"] = "SET"
                    } else {
                        Write-Host "Delete operation canceled."
                        $status["ModulePathSetting"] = "CANCELED"
                    }
                } else {
                    Write-Host "Invalid index."
                    $status["ModulePathSetting"] = "ERROR"
                }
            } else {
                Write-Host "Invalid index."
                $status["ModulePathSetting"] = "ERROR"
            }
        }
        "L" {
            Write-Host "Leaving the module path setting unchanged."
            $status["ModulePathSetting"] = "LEAVE"
        }
        default {
            Write-Host "Invalid choice."
            $status["ModulePathSetting"] = "ERROR"
        }
    }
}

# Main Script Logic
$status["ModulePathSetting"] = Manage-ModulePaths
Write-Host "|--Module Path Setting: -----------------$($status["ModulePathSetting"])--|"
Write-Host " "



    #Execution Policy Setting --------------------------------------------------------------------
    # Retrieve the current execution policy list
    $executionPolicyList = Get-ExecutionPolicy -List

    # Output the execution policy list
    Write-Host "Execution Policy List:"
    foreach ($policy in $executionPolicyList) {
        Write-Host "$($policy.Scope): $($policy.ExecutionPolicy)"
    }

    # Prompt user if they want to perform changes
    $confirmChange = Read-Host "Do you want to make changes to execution policies? (Y/N)"
    if ($confirmChange -eq "Y") {
        # Prompt user for changes
        Write-Host "Select the scope for the new Execution Policy:"
        Write-Host "1. LocalMachine"
        Write-Host "2. CurrentUser"
        $scopeChoice = Read-Host "Enter your choice (1-2)"

        switch ($scopeChoice) {
            1 { $scope = "LocalMachine" }
            2 { $scope = "CurrentUser" }
            default { throw "Invalid choice. Please enter either 1 or 2." }
        }

        Write-Host "Select the new Execution Policy:"
        Write-Host "1. Restricted"
        Write-Host "2. AllSigned"
        Write-Host "3. RemoteSigned"
        Write-Host "4. Unrestricted"
        Write-Host "5. Bypass"
        Write-Host "6. Undefined"
        $newPolicyChoice = Read-Host "Enter your choice (1-6)"

        switch ($newPolicyChoice) {
            1 { $newPolicy = "Restricted" }
            2 { $newPolicy = "AllSigned" }
            3 { $newPolicy = "RemoteSigned" }
            4 { $newPolicy = "Unrestricted" }
            5 { $newPolicy = "Bypass" }
            6 { $newPolicy = "Undefined" }
            default { throw "Invalid choice. Please enter a number between 1 and 6." }
        }

        # Set the new execution policy
        Set-ExecutionPolicy -Scope $scope -ExecutionPolicy $newPolicy -Force
        Write-Host "New Execution Policy for ${scope}: ${newPolicy}"
        $status["ExecutionPolicySetting"] = "OK"
    } else {
        Write-Host "DENIEDing execution policy changes."
        $status["ExecutionPolicySetting"] = "DENIED"
    }

    Write-Host "|--Execution Policy Setting: ------------$($status["ExecutionPolicySetting"])--|"
    Write-Host " "


    # Certs in Store --------------------------------------------------------------------
    # Check if certificate already exists
    $certExists = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction SilentlyContinue
    if ($certExists -eq $null) {
        # Generate a self-signed Authenticode certificate
        $authenticode = New-SelfSignedCertificate -Subject "LAB.PreConfig" -CertStoreLocation Cert:\LocalMachine\My -Type CodeSigningCert -ErrorAction Stop

        # Add the self-signed Authenticode certificate to the computer's root certificate store
        $rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","LocalMachine")
        $rootStore.Open("ReadWrite")
        $rootStore.Add($authenticode)
        $rootStore.Close()

        # Add the self-signed Authenticode certificate to the computer's trusted publishers certificate store
        $publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","LocalMachine")
        $publisherStore.Open("ReadWrite")
        $publisherStore.Add($authenticode)
        $publisherStore.Close()

        $status["CertificateGeneration"] = "OK"
    } else {
        Write-Host "Certificate already exists with subject 'CN=LAB.PreConfig'. SKIPing certificate generation."
        $authenticode = $certExists
        $status["CertificateGeneration"] = "SKIP"
    }

    # Output separator line
    Write-Host " "

    # Confirm if the self-signed Authenticode certificate exists in the computer's Personal certificate store
    $certPersonal = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
    if ($certPersonal -ne $null) {
        $status["CertInPersonalStore"] = "OK"
    } else {
        $status["CertInPersonalStore"] = "ERROR"
    }

    # Confirm if the self-signed Authenticode certificate exists in the computer's Root certificate store
    $certRoot = Get-ChildItem Cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
    if ($certRoot -ne $null) {
        $status["CertInRootStore"] = "OK"
    } else {
        $status["CertInRootStore"] = "ERROR"
    }

    # Confirm if the self-signed Authenticode certificate exists in the computer's Trusted Publishers certificate store
    $certPublisher = Get-ChildItem Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
    if ($certPublisher -ne $null) {
        $status["CertInPublisherStore"] = "OK"
    } else {
        $status["CertInPublisherStore"] = "ERROR"
    }



    Write-Host "|--Certificate in Personal Store: -------$($status["CertInPersonalStore"])--|"
    Write-Host "|--Certificate in Root Store: -----------$($status["CertInRootStore"])--|"
    Write-Host "|--Certificate in Publisher Store: ------$($status["CertInPublisherStore"])--|"
    Write-Host "|--Certificate Generation: --------------$($status["CertificateGeneration"])--|"
    Write-Host " "
    
    # Store the certificate in a variable to reference it later
    $cert = $certPersonal

}

catch {
    Write-Host "Error occurred: $_"
    # You can choose

}

finally {

    # Stop Transcript
    Stop-Transcript

}
