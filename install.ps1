# Start PowerShell script
$script = {
    # Winget search for XAMPP
    Write-Output "Searching for XAMPP..."
    $searchResult = winget search XAMPP | Out-String

    # Parse versions and IDs from the search result
    $versionList = $searchResult -split "`n" | Select-Object -Skip 3 | Where-Object { $_ -match 'ApacheFriends' } | ForEach-Object {
        $splitLine = $_ -split '\s+', 4
        [PSCustomObject]@{
            'Name'    = $splitLine[0]
            'Version' = $splitLine[1]
            'ID'      = $splitLine[2]
        }
    }

    # Print the search results with corresponding numbers
    Write-Output "Please select the version you want to install:"
    for ($i = 0; $i -lt $versionList.Count; $i++) {
        Write-Output ("{0}. Name: {1}, ID: {2}, Version: {3}" -f ($i + 1), $versionList[$i].Name, $versionList[$i].ID, $versionList[$i].Version)
    }

    # Select XAMPP version to install
    $versionToInstall = Read-Host -Prompt 'Enter the number of the version you want to install (from the list above)'

    # Convert input to integer
    try {
        $versionToInstall = [int]$versionToInstall
    }
    catch {
        Write-Output "Invalid number entered, installation aborted"
        return
    }

    # If the entered number is valid, proceed with the installation
    if ($versionToInstall -ge 1 -and $versionToInstall -le $versionList.Count) {
        $selectedVersion = $versionList[$versionToInstall - 1]

        # Winget install XAMPP with the specified version
        Write-Output "Installing XAMPP version $($selectedVersion.Version) ..."
        winget install --id $selectedVersion.ID

        # Add php path to PATH environment variable
        $xamppPath = "C:\xampp";

        $envPath = [Environment]::GetEnvironmentVariable("Path", "User") 
        if ($envPath -notlike "*$xamppPath*") {
            Write-Output "Adding PHP path to PATH environment variable..."
            $envPath += ";$xamppPath\php"
            [Environment]::SetEnvironmentVariable("Path", $envPath, "User")
        }

        # Add apache path to PATH environment variable
        $apachePath = "C:\xampp\apache\bin";
        $envPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($envPath -notlike "*$apachePath*") {
            Write-Output "Adding Apache path to PATH environment variable..."
            $envPath += ";$apachePath"
            [Environment]::SetEnvironmentVariable("Path", $envPath, "User")
        }


        Write-Output "Installation complete"
    }
    else {
        Write-Output "Invalid number entered, installation aborted"
    }
}

# Run the script
& $script
# End PowerShell script
