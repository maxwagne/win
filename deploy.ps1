try {
    Start-Transcript -Path "$env:USERPROFILE\Logs\deploy.txt" -Append
    Write-Output "Script directory: $PSScriptRoot"
    $status = @{}

function Manage-Modules {
    Write-Output "-------------------------------Manage Modules-----------------------------------"
    
    # Get the directory where the script resides
    $scriptDirectory = $PSScriptRoot
    if (-not $scriptDirectory) {
        $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
    }
    
    # Construct the path to the xmod.txt file
    $configFilePath = Join-Path -Path $scriptDirectory -ChildPath "conf\xmod.txt"
    
    # Check if the config file exists
    if (Test-Path $configFilePath) {
        # Read the module names from the config file
        $moduleNames = Get-Content $configFilePath
        
        # Display the table header
        Write-Host "┌───────────────┬────────────────────────────────────────────────────────────────┐"
        Write-Host "│   Status      │ Module Name                                                    │"
        Write-Host "├───────────────┼────────────────────────────────────────────────────────────────┤"
        
        # Display the list of modules loaded from the file
        foreach ($moduleName in $moduleNames) {
            $installed = if (Get-Module -ListAvailable -Name $moduleName) { "Installed" } else { "Not Installed" }
            Write-Host "│ $installed`t`t│ $moduleName`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t`t│"
        }
        
        # Display the table footer
        Write-Host "└───────────────┴────────────────────────────────────────────────────────────────┘"
    } else {
        Write-Host "Config file not found: $configFilePath"
        return
    }
    
    # Define other variables
    $scopeOptions = @("CurrentUser", "AllUsers")
    
    # Proceed with module management
    foreach ($moduleName in $moduleNames) {
        if (Get-Module -ListAvailable -Name $moduleName) {
            Write-Host "$moduleName module is already installed."
        } else {
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


    function Manage-Profiles {
        Write-Output "-------------------------------Manage Profiles----------------------------------"
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
        $confirmChange = $true
        if ($profileAvailable) {
            $confirmChange = Read-Host "A profile script exists. Do you still want to create a symlink in one of the possible locations? (Y/N)"
        }
        if ($confirmChange -eq "Y") {
            Write-Output "Select Profile Location:"
            Write-Output "1. All Users, All Hosts"
            Write-Output "2. All Users, Current Host"
            Write-Output "3. Current User, All Hosts"
            Write-Output "4. Current User, Current Host"
            $choice = Read-Host "Enter your choice (1-4)"
            switch ($choice) {
                1 { $profileLocation = $Profile.AllUsersAllHosts }
                2 { $profileLocation = $Profile.AllUsersCurrentHost }
                3 { $profileLocation = $Profile.CurrentUserAllHosts }
                4 { $profileLocation = $Profile.CurrentUserCurrentHost }
                default { throw "Invalid choice. Please enter a number between 1 and 4." }
            }
            $profileScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "profile.ps1"
            New-Item -Path $profileLocation -ItemType SymbolicLink -Value $profileScriptPath -Force
            Write-Output "Symlink created at $profileLocation pointing to $profileScriptPath"
            $status["ProfileLocationSelection"] = "OK"
        } else {
            $status["ProfileLocationSelection"] = "DENIED"
        }
        Write-Output "|--Profile Location Selection: ----------$($status["ProfileLocationSelection"])--|"
    }
    function Manage-ExecPolicy {
        Write-Output "-------------------------------Manage ExecPolicy--------------------------------"
        $executionPolicyList = Get-ExecutionPolicy -List
        Write-Output "Execution Policy List:"
        foreach ($policy in $executionPolicyList) {
            Write-Output "$($policy.Scope): $($policy.ExecutionPolicy)"
        }
        $confirmChange = Read-Host "Do you want to make changes to execution policies? (Y/N)"
        if ($confirmChange -eq "Y") {
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
            Set-ExecutionPolicy -Scope $scope -ExecutionPolicy $newPolicy -Force
            Write-Output "New Execution Policy for ${scope}: ${newPolicy}"
            $status["ExecutionPolicySetting"] = "OK"
        } else {
            Write-Output "DENIEDing execution policy changes."
            $status["ExecutionPolicySetting"] = "DENIED"
        }
        Write-Output "|--Execution Policy Setting: ------------$($status["ExecutionPolicySetting"])--|"
    }
function Manage-Certs {
    Write-Output "-------------------------------Manage Certs-------------------------------------"
    
    # Check if the certificate already exists
    $certExists = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction SilentlyContinue
    
    # If certificate doesn't exist, create it
    if ($certExists -eq $null) {
        # Create a new self-signed certificate
        $authenticode = New-SelfSignedCertificate -Subject "LAB.PreConfig" -CertStoreLocation Cert:\LocalMachine\My -Type CodeSigningCert -ErrorAction Stop
        
        # Add the certificate to the Root store
        $rootStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("Root","LocalMachine")
        $rootStore.Open("ReadWrite")
        $rootStore.Add($authenticode)
        $rootStore.Close()
        
        # Add the certificate to the Publisher store
        $publisherStore = [System.Security.Cryptography.X509Certificates.X509Store]::new("TrustedPublisher","LocalMachine")
        $publisherStore.Open("ReadWrite")
        $publisherStore.Add($authenticode)
        $publisherStore.Close()
        
        # Set status for certificate generation
        $status["CertificateGeneration"] = "OK"
        
        # Update status for certificate stores
        $status["CertInPersonalStore"] = "Yes"
        $status["CertInRootStore"] = "Yes"
        $status["CertInPublisherStore"] = "Yes"
    } else {
        # If certificate exists, use it
        Write-Output "Certificate already exists with subject 'CN=LAB.PreConfig'. Skipping certificate generation."
        $authenticode = $certExists
        $status["CertificateGeneration"] = "SKIP"
        
        # Update status for certificate stores
        $status["CertInPersonalStore"] = "Yes"
        $status["CertInRootStore"] = "Yes"
        $status["CertInPublisherStore"] = "Yes"
    }

    # Output certificate details
    Write-Output "|--Certificate in Personal Store: -------$($status["CertInPersonalStore"])--|"
    Write-Output "|--Certificate in Root Store: -----------$($status["CertInRootStore"])--|"
    Write-Output "|--Certificate in Publisher Store: ------$($status["CertInPublisherStore"])--|"
    Write-Output "|--Certificate Generation: --------------$($status["CertificateGeneration"])--|"

    # Ask user if they want to manage certificates further
    $manageMore = Read-Host "Do you still want to manage certificates? (Y/N)"

    if ($manageMore -eq "N") {
        return  # Exit the function
    } elseif ($manageMore -eq "Y") {
        # Prompt user for further actions
        Write-Output "Select an option:"
        Write-Output "1. Add certificate"
        Write-Output "2. Delete certificate"
        Write-Output "3. Display certificates"
        Write-Output "4. Quit function"
        
        $option = Read-Host "Enter the option number:"

        switch ($option) {
            1 {
                Write-Output "Placeholder for adding certificate."
            }
            2 {
                Write-Output "Placeholder for deleting certificate."
            }
            3 {
                Write-Output "Placeholder for displaying certificates."
            }
            4 {
                return  # Quit function
            }
            default {
                Write-Output "Invalid option. Please enter a valid option number."
            }
        }
    } else {
        Write-Output "Invalid input. Please enter Y or N."
    }
}
    function Manage-ScheduledTasks {
        Write-Output "-------------------------------Manage STask-------------------------------------"
                while ($true) {
                    Write-Host "Choose an action:"
                    Write-Host "1. Add"
                    Write-Host "2. Remove"
                    Write-Host "3. Done"
                    $option = Read-Host "Enter the number corresponding to your choice (1, 2, or 3)"
                    switch ($option) {
                        "1" {
                            try {
                                Write-Host "Loading stask.ps1 file..."
                                $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "conf\stask.ps1"
                                if (Test-Path $scriptPath) {
                                    Write-Host "stask.ps1 file found. Loading functions..."
                                    $scriptContent = Get-Content -Path $scriptPath -Raw
                                    $functionNames = @{}
                                    [Regex]::Matches($scriptContent, 'function\s+([^\s\(]+)') | ForEach-Object { $functionNames[$_.Groups[1].Value] = $true }
                                    Write-Host "Functions loaded:"
                                    $functionNames = $functionNames.Keys
                                    $functionNames
                                    . $ScriptPath
                                    Write-Host "Choose a task to add:"
                                    for ($i = 0; $i -lt $functionNames.Count; $i++) {
                                        Write-Host "$($i + 1). $($functionNames[$i])"
                                    }
                                    $functionIndex = Read-Host "Enter the index of the task you want to add"
                                    if ($functionIndex -ge 1 -and $functionIndex -le $functionNames.Count) {
                                        $functionName = $functionNames[$functionIndex - 1]
                                        Write-Host "Adding task using function: $functionName"
                                        & $functionName
                                    } else {
                                        Write-Host "Invalid index. Please choose a valid index."
                                    }
                                } else {
                                    Write-Host "The stask.ps1 file does not exist in the specified path."
                                }
                            } catch {
                                Write-Host "An error occurred while loading or executing stask.ps1 file: $_"
                            }
                        }
                        "2" {
                            Write-Host "Here is a list of scheduled tasks:"
                            $tasks = Get-ScheduledTask | ForEach-Object -Begin {$i=0} -Process {
                                [PSCustomObject]@{
                                    Index = $i++
                                    TaskName = $_.TaskName
                                    TaskPath = $_.TaskPath
                                    State = $_.State
                                    NextRunTime = $_.NextRunTime
                                    LastRunTime = $_.LastRunTime
                                    Author = $_.Author
                                    Description = $_.Description
                                }
                            }
                            $tasks | Format-Table -AutoSize
                            $indexes = Read-Host "Enter the indexes of the tasks you want to remove (separated by comma), or enter 'done' to return to the main menu"
                            if ($indexes -eq "done") {
                                break
                            }
                            $indexArray = $indexes -split ","
                            foreach ($index in $indexArray) {
                                $index = $index.Trim()
                                if ($index -ge 0 -and $index -lt $tasks.Count) {
                                    $taskToRemove = $tasks[$index]
                                    Unregister-ScheduledTask -TaskName $taskToRemove.TaskName -Confirm:$false
                                    Write-Host "Task $($taskToRemove.TaskName) removed successfully."
                                } else {
                                    Write-Host "Invalid index: $index"
                                }
                            }
                        }
                        "3" {
                            Write-Host "Returning to the main menu."
                            return
                        }
                        default {
                            Write-Host "Invalid option. Please choose '1' for add, '2' for remove, or '3' for done."
                        }
                    }
                }

            }

    while ($true) {
        Write-Output " "
        Write-Output "Script directory: $PSScriptRoot"
        Write-Output "-------------------------------Main Menu----------------------------------------"
        Write-Output "1. Manage Modules"
        Write-Output "2. Manage Profiles"
        Write-Output "3. Manage ExecPolicy"
        Write-Output "4. Manage Certs"
        Write-Output "5. Manage Scheduled Tasks"
        Write-Output "6. Exit"
        $choice = Read-Host "Enter your choice (1-6)"
        switch ($choice) {
            1 { Manage-Modules }
            2 { Manage-Profiles }
            3 { Manage-ExecPolicy }
            4 { Manage-Certs }
            5 { Manage-ScheduledTasks }
            6 { break }
            default { Write-Output "Invalid choice. Please enter a number between 1 and 6." }
        }
    }
}
catch {
    Write-Output "Error occurred: $_"
}
finally {
    Stop-Transcript
}
