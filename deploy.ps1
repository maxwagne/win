try {
    Start-Transcript -Path "$env:USERPROFILE\Logs\deploy.txt" -Append
    Write-Output "Script directory: $PSScriptRoot"
    $status = @{}


function Main-Menu {
      
        while ($true) {
            Write-Output " "
            Write-Output "Script directory: $PSScriptRoot"
            Write-Output "-------------------------------Main Menu----------------------------------------"
            Write-Output "1. Manage Modules & Variable"
            Write-Output "2. Manage Profiles"
            Write-Output "3. Manage ExecPolicy"
            Write-Output "4. Manage Certs"
            Write-Output "5. Manage Scheduled Tasks"
            Write-Output "--------------------------------------------------------------------------------"
            $choice = Read-Host "Enter your choice"
            switch ($choice) {
                1 { Manage-Modules }
                2 { Manage-Profiles }
                3 { Manage-ExecPolicy }
                4 { Manage-Certs }
                5 { Manage-ScheduledTasks }
                default { Write-Output "Invalid choice. Please enter a number between 1 and 6." }
            }
        }
    }


function Manage-Modules {
    while ($true) {
        Write-Output " "
        Write-Output "-----------------------------Manage Modules ------------------------------------"
        Write-Output "1. Manage Module Variable"
        Write-Output "2. Manage Module Installation"
        Write-Output "3. Back to previous Menu"
        Write-Output "--------------------------------------------------------------------------------"

        $choice = Read-Host "Enter your choice"
        
        # Input validation
        if ($choice -match '^[1-3]$') {
            switch ($choice) {
                1 { Manage-Module-Var }
                2 { Manage-Module-Installation }
                3 { Main-Menu }
            }
        }
        else {
            Write-Output "Invalid choice. Please enter a number between 1 and 3."
        }
    }
}

function Manage-Module-Var {
    while ($true) {
        Write-Output " "
        Write-Output "--------------------------------------------------------------------------------"
        Write-Output "1. Display env:PSModulePath split by semicolon."
        Write-Output "2. Display env:PSModulePath split by semicolon, excluding empty entries and edit variable."
        Write-Output "3. Add a new value to env:PSModulePath."
        Write-Output "4. Delete a value from env:PSModulePath."
        Write-Output "5. Export module folders to exportmodules.txt."
        Write-Output "6. Back to previous Menu"
        Write-Output "--------------------------------------------------------------------------------"
        
        $option = Read-Host "Enter your choice"

        # Input validation
        if ($option -match '^[1-6]$') {
            switch ($option) {
                '1' {
                    Write-Host""
                    $env:PSModulePath -split ';'
                }
                '2' {
                    Write-Host""
                    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object { $_ -ne '' }) -join ';'
                }
                '3' {
                    Write-Host""
                    $newValue = Read-Host "Enter the value to add"
                    $env:PSModulePath += ';' + $newValue
                }
                '4' {
                    Write-Host""
                    $toDelete = Read-Host "Enter the value to delete"
                    $env:PSModulePath = ($env:PSModulePath -split ';' | Where-Object { $_ -ne $toDelete }) -join ';'
                }
                '5' {
                    Write-Host""
                    $moduleFolders = $env:PSModulePath -split ';' | Where-Object { $_ -ne '' }

                    # Cleanup the exportmodules.txt file
                    $exportFile = "$PSScriptRoot\conf\xmod.txt"
                    if (Test-Path $exportFile) {
                        Clear-Content -Path $exportFile -ErrorAction SilentlyContinue
                    }

                    # Loop through each module folder
                    foreach ($folder in $moduleFolders) {

                        if (Test-Path $folder -PathType Container) {
                            # Export main module folder to .txt
                            $folder -replace '^(.*)$', '#$1' | Out-File -FilePath $exportFile -Append
                            # Get subfolders within the main module folder
                            $subFolders = Get-ChildItem -Path $folder -Directory | Select-Object -ExpandProperty Name
                            # Export subfolders to .txt
                            $subFolders | ForEach-Object { "$_" | Out-File -FilePath $exportFile -Append }
                        } else {
                            Write-Host "Folder not found: $folder"
                        }
                    }

                    Write-Host "Module folders exported to .txt"
                }


                '6' {
                     Manage-Modules
                }
            }
        }
        else {
            Write-Host "Invalid option. Please choose 1, 2, 3, 4, 5, or 6."
        }
    }
}


function Manage-Module-Installation {
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
        Write-Host "┌───────────┬────────────────────────────────┬───────────────────────────────────────────────────────────────────────┐"
        Write-Host ("│ {0,-6} │ {1,-30} │ {2,-69} │" -f "installed", "moduleName", "description")
        Write-Host "├───────────┼────────────────────────────────┼───────────────────────────────────────────────────────────────────────┤"

        # Display the list of modules loaded from the file
        foreach ($moduleName in $moduleNames) {
            $installed = if (Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue) { "        X" } else { "         " }
            $moduleInfo = Find-Module -Name $moduleName -ErrorAction SilentlyContinue
            $description = if ($moduleInfo) { $moduleInfo.Description.Substring(0, [Math]::Min(67, $moduleInfo.Description.Length)) + '..' } else { "Description not available" }
            Write-Host ("│ {0,-6} │ {1,-30} │ {2,-69} │" -f $installed, $moduleName, $description)
        }

        # Display the table footer
        Write-Host "└───────────┴────────────────────────────────┴───────────────────────────────────────────────────────────────────────┘"

        # Prompt user for module installation
        $moduleNameToInstall = Read-Host "Enter the name of the module you want to install (or type 'exit' to exit):"

        if ($moduleNameToInstall -eq "exit") {
            Write-Host "Exiting without installing any module."
            return
        }

        if ($moduleNameToInstall -in $moduleNames) {
            if (Get-Module -ListAvailable -Name $moduleNameToInstall -ErrorAction SilentlyContinue) {
                Write-Host "$moduleNameToInstall module is already installed."
            } else {
                # Retrieve available installation scopes
                $scopeOptions = @( "CurrentUser", "AllUsers" )

                Write-Host "Select scope for $moduleNameToInstall installation:"
                for ($i = 0; $i -lt $scopeOptions.Count; $i++) {
                    Write-Host "$($i+1): $($scopeOptions[$i])"
                }
                $selectedScopeIndex = Read-Host "Enter the index of the desired scope:"

                if ($selectedScopeIndex -ge 1 -and $selectedScopeIndex -le $scopeOptions.Count) {
                    $selectedScope = $scopeOptions[$selectedScopeIndex - 1]
                    Write-Host "$moduleNameToInstall module is not installed. Installing..."
                    Install-Module $moduleNameToInstall -Scope $selectedScope -Force
                } else {
                    Write-Host "Invalid scope index selected."
                }
            }
        } else {
            Write-Host "Invalid module name. Please enter a module name from the list."
        }

    } else {
        Write-Host "Config file not found: $configFilePath"
        return
    }
}


 function Manage-Profiles {
    # Display header for profile management section
    Write-Output "-------------------------------Manage Profiles----------------------------------"
    
    # Define an array of possible profile paths
    $profilePaths = @(
        $Profile.AllUsersAllHosts,
        $Profile.AllUsersCurrentHost,
        $Profile.CurrentUserAllHosts,
        $Profile.CurrentUserCurrentHost
    )
    
    # Flag to track if any profile script is available
    $profileAvailable = $false
    
    # Check each profile path for the existence of a profile script
    foreach ($path in $profilePaths) {
        if (Test-Path $path) {
            Write-Output "Profile script found in $path"
            $profileAvailable = $true
        } else {
            Write-Output "Profile script not found in $path"
        }
    }
    
    # Update status based on profile availability
    if ($profileAvailable) {
        $status["ProfileAvailability"] = "OK"
    } else {
        $status["ProfileAvailability"] = "ERROR"
    }
    
    # Display profile availability status
    Write-Output "Profile Availability: $($status["ProfileAvailability"])"
    Write-Output "--------------------------------------------------------------------------------"
    
    # Ask for confirmation if a profile script exists
    $confirmChange = $true
    if ($profileAvailable) {
        $confirmChange = Read-Host "A profile script exists. Do you still want to create a symlink in one of the possible locations? (Y/N)"
    }
    
    # Proceed with creating symlink if user confirms
    if ($confirmChange -eq "Y") {
        # Display options for profile location selection
        Write-Output "Select Profile Location:"
        Write-Output "1. All Users, All Hosts"
        Write-Output "2. All Users, Current Host"
        Write-Output "3. Current User, All Hosts"
        Write-Output "4. Current User, Current Host"
        
        # Prompt user for choice
        $choice = Read-Host "Enter your choice (1-4)"
        
        # Select profile location based on user choice
        switch ($choice) {
            1 { $profileLocation = $Profile.AllUsersAllHosts }
            2 { $profileLocation = $Profile.AllUsersCurrentHost }
            3 { $profileLocation = $Profile.CurrentUserAllHosts }
            4 { $profileLocation = $Profile.CurrentUserCurrentHost }
            default { throw "Invalid choice. Please enter a number between 1 and 4." }
        }
        
        # Define path for profile script to be symlinked
        $profileScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "profile.ps1"
        
        # Create symbolic link to profile script
        New-Item -Path $profileLocation -ItemType SymbolicLink -Value $profileScriptPath -Force
        
        # Display success message
        Write-Output "Symlink created at $profileLocation pointing to $profileScriptPath"
        
        # Update status for profile location selection
        $status["ProfileLocationSelection"] = "OK"
    } else {
        # Deny profile location selection if user declines
        $status["ProfileLocationSelection"] = "DENIED"
    }
    
    # Display profile location selection status
    Write-Output "Profile Location Selection: $($status["ProfileLocationSelection"])"
    Write-Output "--------------------------------------------------------------------------------"
}

function Manage-ExecPolicy {
    # Display header for execution policy management section
    Write-Output "-------------------------------Manage ExecPolicy--------------------------------"
    
    # Retrieve the list of execution policies
    $executionPolicyList = Get-ExecutionPolicy -List
    # Display the current execution policies
    foreach ($policy in $executionPolicyList) {
        Write-Output "$($policy.Scope): $($policy.ExecutionPolicy)"
    }
    
    # Ask for confirmation to make changes to execution policies
    Write-Output "--------------------------------------------------------------------------------"
    $confirmChange = Read-Host "Do you want to make changes to execution policies? (Y/N)"  
    
    # Proceed with execution policy changes if confirmed
    if ($confirmChange -eq "Y") {
        # Select the scope for the new execution policy
        Write-Output "--------------------------------------------------------------------------------"
        Write-Output "Select the scope for the new Execution Policy:"
        Write-Output "1. LocalMachine"
        Write-Output "2. CurrentUser"
        Write-Output "--------------------------------------------------------------------------------"
        $scopeChoice = Read-Host "Enter your choice (1-2)"
        switch ($scopeChoice) {
            1 { $scope = "LocalMachine" }
            2 { $scope = "CurrentUser" }
            default { throw "Invalid choice. Please enter either 1 or 2." }
        }
        
        # Select the new execution policy
        Write-Output "Select the new Execution Policy:"
        Write-Output "1. Restricted"
        Write-Output "2. AllSigned"
        Write-Output "3. RemoteSigned"
        Write-Output "4. Unrestricted"
        Write-Output "5. Bypass"
        Write-Output "6. Undefined"
        Write-Output "--------------------------------------------------------------------------------"
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
        
        # Display the new execution policy
        Write-Output "New Execution Policy for ${scope}: ${newPolicy}"
        
        # Update status for execution policy setting
        $status["ExecutionPolicySetting"] = "OK"
    } else {
        # Deny execution policy changes if user declines
        Write-Output "DENIEDing execution policy changes."
        $status["ExecutionPolicySetting"] = "DENIED"
    }
    
    # Display execution policy setting status
    Write-Output "Execution Policy Setting: $($status["ExecutionPolicySetting"])"
    Write-Output "--------------------------------------------------------------------------------"
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
    Write-Output "Certificate in Personal Store: $($status["CertInPersonalStore"])"
    Write-Output "Certificate in Root Store: $($status["CertInRootStore"])"
    Write-Output "Certificate in Publisher Store: $($status["CertInPublisherStore"])"
    Write-Output "Certificate Generation: $($status["CertificateGeneration"])"

    # Ask user if they want to manage certificates further
    Write-Output "--------------------------------------------------------------------------------"
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
        Write-Output "--------------------------------------------------------------------------------"      
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
                    Write-Output "--------------------------------------------------------------------------------"
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
                                    Write-Output "--------------------------------------------------------------------------------"
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

            Main-Menu

}

catch {
    Write-Output "Error occurred: $_"




}
finally {
    Stop-Transcript
}