function Manage-Modules {
    param()
    Write-Output "________________________________________________________________________________"
    Write-Output "-------------------------------Manage Modules-----------------------------------"
    
    # Array of module names
    $moduleNames = @("posh-git")

    # Array of possible scope options
    $scopeOptions = @("CurrentUser", "AllUsers")

    # Loop through each module
    foreach ($moduleName in $moduleNames) {
        # Check if module is installed
        if (Get-Module -ListAvailable -Name $moduleName) {
            Write-Host "$moduleName module is already installed."
        } else {
            # Prompt user to select scope
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
    param()
    Write-Output "________________________________________________________________________________"
    Write-Output "-------------------------------Manage Profiles----------------------------------"

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

function Manage-ExecPolicy {
    param()
    Write-Output "________________________________________________________________________________"
    Write-Output "-------------------------------Manage ExecPolicy--------------------------------"


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

function Manage-Certs {
    param()
    Write-Output "________________________________________________________________________________"
    Write-Output "-------------------------------Manage Certs-------------------------------------"

    # Certs in Store --------------------------------------------------------------------
    # Check if certificate already exists
    $certExists = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction SilentlyContinue
    Write-Output "Certificate exists: $($certExists -ne $null)"
    if ($certExists -eq $null) {
        Write-Output "Certificate does not exist. Generating..."
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
    try {
        $certPersonal = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
        Write-Output "Certificate in Personal store: $($certPersonal -ne $null)"
        if ($certPersonal -ne $null) {
            $status["CertInPersonalStore"] = "OK"
        } else {
            $status["CertInPersonalStore"] = "ERROR"
        }
    } catch {
        Write-Output "Error retrieving certificate from Personal store: $_"
        $status["CertInPersonalStore"] = "ERROR"
    }

    # Confirm if the self-signed Authenticode certificate exists in the computer's Root certificate store
    $certRoot = Get-ChildItem Cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
    Write-Output "Certificate in Root store: $($certRoot -ne $null)"
    if ($certRoot -ne $null) {
        $status["CertInRootStore"] = "OK"
    } else {
        $status["CertInRootStore"] = "ERROR"
    }

    # Confirm if the self-signed Authenticode certificate exists in the computer's Trusted Publishers certificate store
    $certPublisher = Get-ChildItem Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -eq "CN=LAB.PreConfig"} -ErrorAction Stop
    Write-Output "Certificate in Publisher store: $($certPublisher -ne $null)"
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


function Manage-ScheduledTasks {
    param()
    Write-Output "________________________________________________________________________________"
    Write-Output "-------------------------------Manage STask-------------------------------------"
    while ($true) {
            while ($true) {
                # Provide options to add or remove scheduled tasks
                Write-Host "Choose an action:"
                Write-Host "1. Add"
                Write-Host "2. Remove"
                Write-Host "3. Done"
                
                $option = Read-Host "Enter the number corresponding to your choice (1, 2, or 3)"

                switch ($option) {
                    "1" {
			try {
                        Write-Host "Loading stask.ps1 file..."
                    # Load functions from the stask.ps1 file
                    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "conf\stask.ps1"
                    if (Test-Path $scriptPath) {
                        Write-Host "stask.ps1 file found. Loading functions..."


                        # Read the content of stask.ps1 file
                        $scriptContent = Get-Content -Path $scriptPath -Raw

                        # Extract unique function names from the script content using regular expressions
                        $functionNames = @{}
                        [Regex]::Matches($scriptContent, 'function\s+([^\s\(]+)') | ForEach-Object { $functionNames[$_.Groups[1].Value] = $true }

                        Write-Host "Functions loaded:"
                        $functionNames = $functionNames.Keys
                        $functionNames

                        . $ScriptPath

                        # Display functions with indexes
                        Write-Host "Choose a task to add:"
                        for ($i = 0; $i -lt $functionNames.Count; $i++) {
                            Write-Host "$($i + 1). $($functionNames[$i])"
                        }

                        # Prompt user to select a function to add
                        $functionIndex = Read-Host "Enter the index of the task you want to add"
                        if ($functionIndex -ge 1 -and $functionIndex -le $functionNames.Count) {
                            $functionName = $functionNames[$functionIndex - 1]
                            Write-Host "Adding task using function: $functionName"
                           # Call the selected function directly
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

                        # Prompt user to select tasks to remove
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
            
        } elseif ($response -eq "n") {
            Write-Host "Okay, not managing scheduled tasks."
        } else {
            Write-Host "Invalid response. Please enter 'y' or 'n'."
        }
    }
}

try {
    # Start Transcript
    Start-Transcript -Path "$env:USERPROFILE\Logs\deploy.txt" -Append
    Write-Output "Script directory: $PSScriptRoot"

    while ($true) {
        Write-Output " "
        Write-Output "Script directory: $PSScriptRoot"
        Write-Output "________________________________________________________________________________"
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
    # Stop Transcript
    Stop-Transcript
}
