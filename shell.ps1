# Set the module path to the directory where the script resides
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Modules"

try {
    # Start Transcript
    Start-Transcript -Path "ShellLog.txt" -Append

    $status = @{}

    # Check if Profiles are available
    $profilePaths = @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    )

    foreach ($path in $profilePaths) {
        if (Test-Path $path) {
            Write-Host "Profile script found in $path"
            $status["ProfileAvailability"] = "OK"
        } else {
            Write-Host "Profile script not found in $path"
            $status["ProfileAvailability"] = "Not OK"
        }
    }

    # Set the module path
    if (!$env:PSModulePath.Contains($ModulePath)) {
        $env:PSModulePath += ";$ModulePath"
        $status["ModulePathSetting"] = "OK"
    } else {
        $status["ModulePathSetting"] = "Not OK"
    }

    # Set the execution policy for the local machine and current user
    Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    $status["ExecutionPolicySetting"] = "OK"

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
        Write-Host "Certificate already exists with subject 'CN=LAB.PreConfig'. Skipping certificate generation."
        $authenticode = $certExists
        $status["CertificateGeneration"] = "Skipped"
    }

    # Confirm if the self-signed Authenticode certificate exists in the computer's Personal certificate store
    $certPersonal = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
    if ($certPersonal -ne $null) {
        $status["CertInPersonalStore"] = "OK"
    } else {
        $status["CertInPersonalStore"] = "Not OK"
    }

    # Confirm if the self-signed Authenticode certificate exists in the computer's Root certificate store
    $certRoot = Get-ChildItem Cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
    if ($certRoot -ne $null) {
        $status["CertInRootStore"] = "OK"
    } else {
        $status["CertInRootStore"] = "Not OK"
    }

    # Confirm if the self-signed Authenticode certificate exists in the computer's Trusted Publishers certificate store
    $certPublisher = Get-ChildItem Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
    if ($certPublisher -ne $null) {
        $status["CertInPublisherStore"] = "OK"
    } else {
        $status["CertInPublisherStore"] = "Not OK"
    }

    # Output status summary
    Write-Host "Summary of Configuration Status:"
    foreach ($key in $status.Keys) {
        Write-Host "- ${key}: $($status[$key])"
    }

    # Store the certificate in a variable to reference it later
    $cert = $certPersonal

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
}

catch {
    Write-Host "Error occurred: $_"
    # You can choose to log the error to a file or take any other appropriate action here.
}

finally {
    # Stop Transcript
    Stop-Transcript
}
