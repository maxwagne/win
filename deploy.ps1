

try {
    # Start Transcript
# Start Transcript

    Write-Output " "
    Start-Transcript -Path "$env:USERPROFILE\ShellLog.txt" -Append
    Write-Output " "

    $status = @{}

function Manage-Modules {
    param()
    
    # Array of module names
    $moduleNames = @("posh-git", "oh-my-posh")

    # Array of possible scope options
    $scopeOptions = @("CurrentUser", "AllUsers")

    # Loop through each module
    foreach ($moduleName in $moduleNames) {
        # Check if module is installed
        if (Get-Module -ListAvailable -Name $moduleName) {
            Write-Host "$moduleName module is already installed."
        } else {
            # Prompt user to select scope
            Write-Host "Select scope for $moduleName installation:"
            for ($i = 0; $i -lt $scopeOptions.Count; $i++) {
                Write-Host "$($i+1): $($scopeOptions[$i])"
            }
            $selectedScopeIndex = Read-Host "Enter the index of the desired scope:"
            $selectedScope = $scopeOptions[$selectedScopeIndex - 1]

            Write-Host "$moduleName module is not installed. Installing..."
            Install-Module $moduleName -Scope $selectedScope -Force
        }
    }
}

# Call the Manage-Modules function
Manage-Modules


function Manage-Profiles {
	param()

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
            Write-Output "Profile script found in $path"
            $profileAvailable = $true
        } else {
            Write-Output "Profile script not found in $path"
        }
    }

    if ($profileAvailable) {
        $status["ProfileAvailability"] = "OK"
    } else {
        $status["ProfileAvailability"] = "ERROR"
    }

    Write-Output "|--Profile Availability: ----------------$($status["ProfileAvailability"])--|"
    Write-Output " "

    # If profile is available, provide the option to create a symlink in one of the possible locations
    $confirmChange = $true
    if ($profileAvailable) {
        $confirmChange = Read-Host "A profile script exists. Do you still want to create a symlink in one of the possible locations? (Y/N)"
    }

    if ($confirmChange -eq "Y") {
        # Select Profile Location
        Write-Output "Select Profile Location:"
        Write-Output "1. All Users, All Hosts"
        Write-Output "2. All Users, Current Host"
        Write-Output "3. Current User, All Hosts"
        Write-Output "4. Current User, Current Host"
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

        Write-Output "Symlink created at $profileLocation pointing to $profileScriptPath"

        $status["ProfileLocationSelection"] = "OK"
    } else {
        $status["ProfileLocationSelection"] = "DENIED"
    }

    Write-Output "|--Profile Location Selection: ----------$($status["ProfileLocationSelection"])--|"
    Write-Output " "
}

# Call the function
Manage-Profiles


function Manage-ExecPolicy {
    param()

    # Retrieve the current execution policy list
    $executionPolicyList = Get-ExecutionPolicy -List

    # Output the execution policy list
    Write-Output "Execution Policy List:"
    foreach ($policy in $executionPolicyList) {
        Write-Output "$($policy.Scope): $($policy.ExecutionPolicy)"
    }

    # Prompt user if they want to perform changes
    $confirmChange = Read-Host "Do you want to make changes to execution policies? (Y/N)"
    if ($confirmChange -eq "Y") {
        # Prompt user for changes
        Write-Output "Select the scope for the new Execution Policy:"
        Write-Output "1. LocalMachine"
        Write-Output "2. CurrentUser"
        $scopeChoice = Read-Host "Enter your choice (1-2)"

        switch ($scopeChoice) {
            1 { $scope = "LocalMachine" }
            2 { $scope = "CurrentUser" }
            default { throw "Invalid choice. Please enter either 1 or 2." }
        }

        Write-Output "Select the new Execution Policy:"
        Write-Output "1. Restricted"
        Write-Output "2. AllSigned"
        Write-Output "3. RemoteSigned"
        Write-Output "4. Unrestricted"
        Write-Output "5. Bypass"
        Write-Output "6. Undefined"
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
        Write-Output "New Execution Policy for ${scope}: ${newPolicy}"
        $status["ExecutionPolicySetting"] = "OK"
    } else {
        Write-Output "DENIEDing execution policy changes."
        $status["ExecutionPolicySetting"] = "DENIED"
    }

    Write-Output "|--Execution Policy Setting: ------------$($status["ExecutionPolicySetting"])--|"
    Write-Output " "
}

# Call the function
Manage-ExecPolicy


   function Manage-Certs {
    param()

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
        Write-Output "Certificate already exists with subject 'CN=LAB.PreConfig'. SKIPing certificate generation."
        $authenticode = $certExists
        $status["CertificateGeneration"] = "SKIP"
    }

    # Output separator line
    Write-Output " "

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

    Write-Output "|--Certificate in Personal Store: -------$($status["CertInPersonalStore"])--|"
    Write-Output "|--Certificate in Root Store: -----------$($status["CertInRootStore"])--|"
    Write-Output "|--Certificate in Publisher Store: ------$($status["CertInPublisherStore"])--|"
    Write-Output "|--Certificate Generation: --------------$($status["CertificateGeneration"])--|"
    Write-Output " "
    
    # Store the certificate in a variable to reference it later
    $cert = $certPersonal
}

# Call the function
Manage-Certs


}

catch {
    Write-Output "Error occurred: $_"
    # You can choose

}

finally {

    # Stop Transcript
    Stop-Transcript

}
