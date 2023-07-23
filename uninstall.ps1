# Start PowerShell script
$script = {
    # Winget list all XAMPP installations
    Write-Output "Listing all installed XAMPP versions..."
    $installedVersions = winget list | Where-Object { $_ -match 'ApacheFriends' } | Out-String

    
    # Print the search results
    Write-Output "XAMPP versions found:"
    Write-Output $installedVersions
    $versionList = $installedVersions -split "`n" | Select-Object -Skip 3 | Where-Object { $_ -match 'ApacheFriends' } | ForEach-Object {
        $splitLine = $_ -split '\s+', 4
        [PSCustomObject]@{
            'Name'    = $splitLine[0]
            'Version' = $splitLine[1]
            'ID'      = $splitLine[2]
        }
    }

    # Print the search results with corresponding numbers
    Write-Output "Please select the version you want to uninstall:"
    for ($i = 0; $i -lt $versionList.Count; $i++) {
        Write-Output ("{0}. Name: {1}, ID: {2}, Version: {3}" -f ($i + 1), $versionList[$i].Name, $versionList[$i].ID, $versionList[$i].Version)
    }

    
    # Select XAMPP version to install
    $versionToUninstall = Read-Host -Prompt 'Enter the number of the version you want to uninstall (from the list above)'

    # Convert input to integer
    try {
        $versionToUninstall = [int]$versionToUninstall
    }
    catch {
        Write-Output "Invalid number entered, uninstall aborted"
        return
    }

    # If the entered number is valid, proceed with the uninstall
    if ($versionToUninstall -ge 1 -and $versionToUninstall -le $versionList.Count) {
        $selectedVersion = $versionList[$versionToUninstall - 1]

        # Winget uninstall XAMPP with the specified version
        Write-Output "Uninstalling XAMPP version $($selectedVersion.Version) ..."
        winget uninstall --id $selectedVersion.ID

        # Remove php path from PATH environment variable
        $xamppPath = "C:\xampp";

        $envPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($envPath -like "*$xamppPath*") {
            Write-Output "Removing PHP path from PATH environment variable..."
            $envPath = $envPath -replace ";$xamppPath\\php", ""
            [Environment]::SetEnvironmentVariable("Path", $envPath, "User")
        }

        # Remove apache path from PATH environment variable
        $apachePath = "C:\xampp\apache\bin";
        $envPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($envPath -like "*$apachePath*") {
            Write-Output "Removing Apache path from PATH environment variable..."
            $envPath = $envPath -replace ";$apachePath", ""
            [Environment]::SetEnvironmentVariable("Path", $envPath, "User")
        }


        Write-Output "Uninstall complete"
    }
    else {
        Write-Output "Invalid number entered, uninstall aborted"
    }
}

# Run the script
& $script
# End PowerShell script
