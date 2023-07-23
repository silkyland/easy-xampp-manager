# Script to manage vhosts in XAMPP on Windows

# Check and ask for admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $runAsAdmin = Read-Host "To write to the hosts file, this script must be run as administrator. Restart as administrator? (Y/N)"
    if ($runAsAdmin -eq 'Y') {
        # Restart script as administrator
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}

# Declare IniFile type for reading .ini files
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class IniFile {
    [DllImport("kernel32", CharSet = CharSet.Unicode)]
    public static extern int GetPrivateProfileString(
        string section,
        string key,
        string defaultValue,
        StringBuilder retVal,
        int size,
        string filePath);
}
"@

# Function for getting values from .ini files
function Get-IniValue ($filePath, $section, $key) {
    $sb = New-Object System.Text.StringBuilder(260)
    [IniFile]::GetPrivateProfileString($section, $key, "", $sb, $sb.Capacity, $filePath) > $null
    return $sb.ToString()
}

# Get configuration from settings.ini
$settingsPath = "$PSScriptRoot\settings.ini"

if (!(Test-Path -Path $settingsPath)) {
    Write-Host "settings.ini file not found. Exiting."
    
}

$xamppPath = Get-IniValue $settingsPath "XAMPP" "Path"
$ApacheConfPath = Get-IniValue $settingsPath "Apache" "ConfPath"
$VhostConfigPath = Get-IniValue $settingsPath "Apache" "VhostConfigPath"
$certPath = Get-IniValue $settingsPath "Apache" "CertPath"
$certKeyPath = Get-IniValue $settingsPath "Apache" "CertKeyPath"
$hostFilePath = Get-IniValue $settingsPath "System" "HostFilePath"

# debug paths
Write-Host $xamppPath 
Write-Host $ApacheConfPath
Write-Host $VhostConfigPath
Write-Host $certPath
Write-Host $certKeyPath
Write-Host $hostFilePath

# Check if mkcert is installed, if not prompt to install it
if (!(Get-Command mkcert -ErrorAction SilentlyContinue)) {
    Write-Host "mkcert is not installed. It is needed to create SSL certificates for vhosts."
    $installMkcert = Read-Host "Install mkcert now? (Y/N)"
    if ($installMkcert -eq 'Y') {
        Invoke-WebRequest -Uri "https://github.com/FiloSottile/mkcert/releases/download/v1.4.3/mkcert-v1.4.3-windows-amd64.exe" -OutFile mkcert.exe
        .\mkcert.exe -install
    }
    else {
        Write-Host "mkcert must be installed to add vhosts with SSL. Exiting."
        Exit
    }
}

# Check if XAMPP is installed, if not prompt exit
if (!(Test-Path -Path $xamppPath)) {
    Write-Host "XAMPP is not installed. Exiting."
    Exit
}

# Test vhost is currently configured
if (!(Test-Path -Path $VhostConfigPath)) {
    Write-Host "No vhosts configured. Exiting."
    Exit
}

# Test vhost is enabled
if (!(Get-Content -Path $ApacheConfPath | Select-String -Pattern "#Include conf/extra/httpd-vhosts.conf") | Select-String -Pattern "Include conf/extra/httpd-vhosts.conf") {
    # if not enable ask to enable
    $enableVhost = Read-Host "Vhosts are not enabled. Enable now? (Y/N)"
    if ($enableVhost -eq 'Y') {
        # Enable vhosts
        Add-Content -Path $ApacheConfPath -Value "Include conf/extra/httpd-vhosts.conf"
        # Restart httpd service
        Join-Path -Path $xamppPath -ChildPath "apache\bin\httpd.exe"
        & $httpdPath -k restart
    }
    else {
        Write-Host "Vhosts must be enabled to manage vhosts. Exiting."
        Exit
    }
}


function Add-Vhost($vhostName, $rootDir) {  
    
    $vhostConfPath = "$xamppPath\apache\conf\extra\\$vhostName.conf"
    $httpdVhostsConfPath = $VhostConfigPath

    # Create vhost config file
    $vhostConf = @"
<VirtualHost *:80>
    ServerName $vhostName
    DocumentRoot "$rootDir"
    Require all granted
</VirtualHost>

"@

    $addSSL = Read-Host "Do you want to add SSL to this vhost? (Y/n)"

    if ($addSSL -eq 'Y') {
        $vhostConf += @"

<VirtualHost *:443>
    ServerName $vhostName
    DocumentRoot "$rootDir"
    Require all granted

    SSLEngine on
    SSLCertificateFile "$certPath\$vhostName.pem"
    SSLCertificateKeyFile "$certKeyPath\$vhostName-key.pem"
</VirtualHost>
"@
    }

    $vhostConf | Out-File $vhostConfPath -Encoding utf8

    # Generate SSL certificates (assuming mkcert is installed and available in PATH)
    if ($addSSL -eq 'Y') {
        mkcert $vhostName

        # move certificates to correct location
        Move-Item -Path "$vhostName.pem" -Destination "$certPath\$vhostName.pem"
        Move-Item -Path "$vhostName-key.pem" -Destination "$certKeyPath\$vhostName-key.pem"
    }

    # Write entry in hosts file if it doesn't already exist
    Write-Host "Adding entry to hosts file..."

    if (!(Get-Content -Path $hostFilePath | Select-String -Pattern $vhostName)) {
        Add-Content -Path $hostFilePath -Value "`n127.0.0.1 $vhostName"
    }
    
    # Ping test to check hosts was added successfully
    $pingTest = Test-Connection -ComputerName $vhostName -Count 1 -Quiet

    if ($pingTest) {
        Write-Host "Host entry was added successfully."
    }
    else {
        Write-Host "Host entry was not added successfully. Please add it manually."
    }

    # Add entry in httpd-vhosts.conf
    Add-Content -Path $httpdVhostsConfPath -Value "Include extra/$vhostName.conf"

    # Restart httpd service (assuming net command works for restarting httpd)
    c:\xampp\apache\bin\httpd.exe -k restart

    Write-Host "Added vhost for $vhostName"
}

function Remove-Vhost($vhostName) {
    $vhostConfPath = "$xamppPath\apache\conf\extra\\$vhostName.conf"
    $httpdVhostsConfPath = $VhostConfigPath

    # Remove vhost config file
    if (Test-Path -Path $vhostConfPath) {
        Remove-Item -Path $vhostConfPath
    }

    # Remove SSL certificates
    if (Test-Path -Path "$certPath\$vhostName.pem") {
        Remove-Item -Path "$certPath\$vhostName.pem"
    }

    if (Test-Path -Path "$certKeyPath\$vhostName-key.pem") {
        Remove-Item -Path "$certKeyPath\$vhostName-key.pem"
    }
    
    # Remove entry in httpd-vhosts.conf
    if (Test-Path -Path $httpdVhostsConfPath) {
        (Get-Content -Path $httpdVhostsConfPath) | Where-Object { $_ -notmatch "Include extra/$vhostName.conf" } | Set-Content -Path $httpdVhostsConfPath
    }

    # Remove entry in hosts file
    if (Test-Path -Path $hostFilePath) {
        (Get-Content -Path $hostFilePath) | Where-Object { $_ -notmatch "`n127.0.0.1 $vhostName" } | Set-Content -Path $hostFilePath
    }

    # Restart httpd service (assuming net command works for restarting httpd)
    Join-Path -Path $xamppPath -ChildPath "apache\bin\httpd.exe"
    & $httpdPath -k restart

    Write-Host "Removed vhost for $vhostName"
}


# Prompt for vhost name 
$vhost = Read-Host "Enter the name of the vhost (e.g. example.test)"
$rootDir = Read-Host "Enter the root directory for the vhost (e.g. c:\xampp\htdocs\example.test) (Leave blank to use $vhost)"

if ($rootDir -eq '') {
    $rootDir = "$xamppPath\htdocs\$vhost"
}



# Menu to add, remove or update vhost
:menu while ($true) {
    Write-Host "`nVhost Manager`n"
    Write-Host "1. Add vhost"
    Write-Host "2. Remove vhost"
    Write-Host "3. Update vhost"
    Write-Host "4. Exit`n"
  
    $option = Read-Host "Select an option"

    switch ($option) {
        '1' {
            if (Test-Path -Path "$xamppPath\apache\conf\extra\$vhost.conf") {
                Write-Host "`nVhost already exists. Return to menu to update or remove."
                break
            }
            # Call function to add vhost
            Add-Vhost $vhost $rootDir
        }
        '2' {
            # Call function to remove vhost  
            Remove-Vhost $vhost
        }
        '3' {
            # Call function to update vhost
            Update-Vhost $vhost $rootDir
        }
        '4' {
            break menu
        }
        Default {
            Write-Host "Invalid option selected"
        }
    }
}



