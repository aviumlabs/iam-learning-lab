Import-Module .\Pkg.psm1

$Directories = [ordered]@{
    "bin" = "bin\";
    "downloads" = "apps\downloads\";
    "backups" = "apps\backups\";
    "secrets" = "apps\secrets\";
    "tomcat" = "apps\tomcat\"; 
}

$OSPackages = [ordered]@{
    "PowerShell-7.5.0-win-x64.msi" = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/PowerShell-7.5.0-win-x64.msi";
    "VSCodeSetup-x64-1.98.0.exe" = "https://update.code.visualstudio.com/1.98.0/win32-x64/stable";
}

$OSPackageHashes = [ordered]@{
    "PowerShell-7.5.0-win-x64.msi" = "6B988B7E236A8E1CF1166D3BE289D3A20AA344499153BDAADD2F9FEDFFC6EDA9";
    "VSCodeSetup-x64-1.98.0.exe" = "1b02ae73047a79955c3a8b09fa01498609f447f2cb20d2362498b3a5d351a7de"
}

$OSPackagesVerified = [ordered]@{
    "PowerShell-7.5.0-win-x64.zip" = $false;
    "VSCodeSetup-x64-1.98.0.exe" = $false;
}

$Packages = [ordered]@{
    "openjdk-21+35_windows-x64_bin.zip" = "https://download.java.net/openjdk/jdk21/ri/openjdk-21+35_windows-x64_bin.zip";
    "apache-tomcat-9.0.100.exe" = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.100/bin/apache-tomcat-9.0.100.exe";
    "tomcat-native-2.0.8-openssl-3.0.14-win32-bin.zip" = "https://dlcdn.apache.org/tomcat/tomcat-connectors/native/2.0.8/binaries/tomcat-native-2.0.8-openssl-3.0.14-win32-bin.zip";
    "postgresql-15.10-1-windows-x64.exe" = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1259343"; 
    "postgresql-42.7.5.jar" = "https://jdbc.postgresql.org/download/postgresql-42.7.5.jar";
}

$PackageHashes = [ordered]@{
    "openjdk-21+35_windows-x64_bin.zip" = "5434faaf029e66e7ce6e75770ca384de476750984a7d2881ef7686894c4b4944";
    "apache-tomcat-9.0.100.exe" = "900955db01438dc2f2c751b97da25a9a49bcd537177dd62ca8e340f0106bb105be12f39d8bec590af2066862deb4683c4756e0155561b4e0dca960d3ae8f24b4";
    "tomcat-native-2.0.8-openssl-3.0.14-win32-bin.zip" = "a4a8816668f14a7461711e25cb9277534981936c9e6f8b00ae55084cb265dc1d89ad07fa508ae2e1f7832236dafafbdd9d76a313c87f34e00ecfdfe75776638a";
    "postgresql-15.10-1-windows-x64.exe" = "CDCD0A767A7AD4AB0C4A5A59DC931D33F8899D172B6E209EBE1BB76796264FF9";
    "postgresql-42.7.5.jar" = "69020B3BD20984543E817393F2E6C01A890EF2E37A77DD11D6D8508181D079AB";
}

$PackagesVerified = [ordered]@{
    "openjdk-21+35_windows-x64_bin.zip" = $false;
    "apache-tomcat-9.0.100.exe" = $false;
    "tomcat-native-2.0.8-openssl-3.0.14-win32-bin.zip" = $false;
    "postgresql-15.10-1-windows-x64.exe" = $false;
    "postgresql-42.7.5.jar" = $false;
}

New-Variable -Name Directories  -Value $Directories -Scope Script -Force
New-Variable -Name OSPackages  -Value $OSPackages -Scope Script -Force
New-Variable -Name OSPackageHashes  -Value $OSPackageHashes -Scope Script -Force
New-Variable -Name OSPackagesVerified  -Value $OSPackagesVerified -Scope Script -Force
New-Variable -Name Packages  -Value $Packages -Scope Script -Force
New-Variable -Name PackageHashes  -Value $PackageHashes -Scope Script -Force
New-Variable -Name PackagesVerified  -Value $PackagesVerified -Scope Script -Force

<#
.SYNOPSIS 
    Internal function to create the specific set of directories.
.DESCRIPTION
    Internal function to create the specific set of directories as 
    specified in this file.
.PARAMETER Path
    Root path.
.EXAMPLE
    Add-Directories -Path "\"
#>
function Add-Directories {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    Write-Host "Creating directories..."
    # Add top level Apps directory
    Add-Directory -Path $Path -Name $Directories["bin"]
    Add-Directory -Path $Path -Name $Directories["downloads"]
    Add-Directory -Path $Path -Name $Directories["backups"]
    Add-Directory -Path $Path -Name $Directories["secrets"]
    Add-Directory -Path $Path -Name $Directories["tomcat"]

}


<#
.SYNOPSIS 
    Creates the directory at the specified path.
.DESCRIPTION
    Creates the directory at the specified path if the path is existing.
.PARAMETER Path
    The root path where the directory will be created. 
.PARAMETER Name
    The name of the directory to create.
.EXAMPLE
    Add-Directory -Path "\" -Name "apps"
#>
function Add-Directory {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name
    )
    $item_path = $Path + $Name
    if (-Not(Test-Path -Path $item_path)) {
        New-Item -Path $Path -Name $Name -ItemType Directory | Out-Null
    } else {
        Write-Host "Skipping path $Path already existing.`n"
    }
}


<#
.SYNOPSIS 
    Internal function to retrieve the full filename.
.DESCRIPTION
    Internal function to retrieve the full filename from Packages dictionary,
    package dictionaries are defined at the top of this script.
.PARAMETER Name
    Name of the package to lookup.
.PARAMETER Pkgs
    The packages dictionary to be download.
.EXAMPLE
    Get-PackageName -Name "PowerShell" -Pkgs <packages_dictionary>
#>
function Get-PackageName {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$Pkgs
    )
    foreach ($key in $Pkgs.Keys) {
        if ( $($key) -Match $Name ) {
            $filename = $($key)
        }
    }

    return $filename
}


<#
.SYNOPSIS 
    Internal function to download a specific set packages.
.DESCRIPTION
    Download the packages passed in the Pk dictionary, package dictionaries 
    are defined at the top of this script.
.PARAMETER Path
    Root path the download directory.
.PARAMETER Pkgs
    The packages dictionary to be download.
.EXAMPLE
    Get-Packages -Path "\" -Pkgs <packages_dictionary>
#>
function Get-Packages {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$Pkgs
    )
    $dl_path = $Path + $Directories["downloads"]
    Set-Location -Path $dl_path

    # Packages is defined at the top of the module
    foreach ($key in $Pkgs.Keys) {
        $download = @{
            FileName = $($key)
            Uri = $($Pkgs[$key])
        }
        $res = Invoke-Download @download
        if ($res) {
            Write-Host "$key download completed."
            $app_path = $dl_path + $key
            Write-Host "Verifying $key integrity..."
            if ($key.Length -eq 64) {
                $ast = Assert-Package -Path $app_path -Name $($key) -Sha 'SHA256'
            } elseif ($key.Length -eq 128) {
                $ast = Assert-Package -Path $app_path -Name $($key) -Sha 'SHA512'
            }
            
            if ($ast) {
                # Verified dictionary
                $pkg_verified = "$PkgsVerified"
                $pkg_verified[$key] = $true
                Write-Host "$key integrity verified."
            } else {
                Write-Host "$key intgretiy verification failed."
            }
        } else {
            Write-Host "$key download failed."
        }
    }

    Set-Location -Path $Path
}


<#
.SYNOPSIS 
    Internal function to retrieve a file's secure hash algorithm digest.
.DESCRIPTION
    Internal function to retrieve the SHA from packages SHA dictionary, 
    defined at the top of this script.
.PARAMETER Name
    Name of the file to lookup.
.EXAMPLE
    Get-PackageSHA -Name "PowerShell" -PkHashes <sha_dictionary>
#>
function Get-PackageSHA {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$PkHashes
    )
    foreach ($key in $PkHashes.Keys) {
        if ( $($key) -match $Name ) {
            $hash = $($key)
        }
    }

    return $hash
}


function Initialize-OpenSSH {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Host "Configuring OpenSSH..."
    # Configure OpenSSH 
    $filename = "sshd_config"
    $config_path = "$env:ProgramData\ssh\$filename"

    # Backup config file
    $bk_path = $Path + $Directories["backups"]
    $date = Get-Date -Format "yyyyddMM"
    Compress-Archive -Path $config_path -DestinationPath ($bk_path + "$date-$filename.zip")

    # Update PubkeyAuthentication
    $matchLine = '#(PubkeyAuthentication yes)'
    ((Get-Content -Path $config_path -Raw) -Replace $matchLine, '$1') | Set-Content -Path $config_path

    # Update PasswordAuthentication
    $matchLine = '#(PasswordAuthentication yes)'
    ((Get-Content -Path $config_path -Raw) -Replace $matchLine, '$1') | Set-Content -Path $config_path

    # Set PowerShell 7 as Default SSH Shell
    $lineToMatch = "Subsystem`tsftp`tsftp-server.exe"
    $pwshell = "$lineToMatch`nSubsystem`tpowershell`tc:/progra~1/powershell/7/pwsh.exe`t-sshs`t-NoLogo"
    ((Get-Content -Path $config_path -Raw) -replace $lineToMatch, $pwshell) | Set-Content -Path $config_path

    # Confirm firewall rules 
    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' is existing."
    }

    # Set Default OpenSSH Shell 
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
    -Value "C:\Progra~1\PowerShell\7\pwsh.exe" -PropertyType String -Force

    Write-Host "OpenSSH configured."
}


<#
.SYNOPSIS 
    Install and configure Active Directory.
.DESCRIPTION
    Install and configure Active Directory based on the parameters passed in.
.PARAMETER ServerName
    Name of the server to install Active Directory Domain Services.
.PARAMETER DomainName
    Name of the Active Directory Domain.
.PARAMETER NetbiosName
    NetBios Name of the Active Directory Domain.
.PARAMETER Pwd
    The secure string of the Safe Mode Administrator password.
.EXAMPLE
    Install-ActiveDirectory -ServerName "devsrv" -DomainName "aviumlabs.test" 
        -NetbiosName "AVIUM" -Pwd <SecureStringPwd>
#>
function Install-ActiveDirectory {
    param (
        [Parameter(Mandatory)]
        [string]$ServerName,
        [Parameter(Mandatory)]
        [string]$DomainName,
        [Parameter(Mandatory)]
        [string]$NetbiosName,
        [Parameter(Mandatory)]
        [Security.SecureString]$Pwd
    )
    Write-Host "Installing Active Directory Domain Services..."

    # Install Active Directory
    Install-WindowsFeature AD-Domain-Services

    Write-Host "Active Domain Services installed."
    Write-Host "Configuring the Active Directory domain $DomainName."
    # Configure Active Directory
    Import-Module ADDSDeployment

    # Set these values to your environment
    $ADArguments = @{
        CreateDNSDelegation           = $false
        DatabasePath                  = "C:\Windows\NTDS"
        DomainName                    = $DomainName
        SafeModeAdministratorPassword = $Pwd
        DomainNetbiosName             = $NetbiosName
        InstallDns                    = $true
        LogPath                       = "C:\Windows\NTDS"
        NoRebootOnCompletion          = $false
        SysvolPath                    = "C:\Windows\SYSVOL"
        Force                         = $true
    }

    Install-ADDSForest @ADArguments
}


<#
.SYNOPSIS 
    Install the prerequisite packages specified at the top of this file.
.DESCRIPTION
    Install the prerequisite packages specified at the top of this file; 
    requires administrative permission.
.PARAMETER Path
    If path is not provided, defaults to "\".
.EXAMPLE
    Install-Packages -Path "\"
#>
function Install-Packages {
    param (
        [string]$Path
    )

    Assert-Environment

    if(-Not($Path)) {
        $Path = "\"
    }
    Write-Host @"
    `n
    This script will download, install and configure the packages required to 
    run SailPoint IdentityIQ 8.x on Windows 10 or higher.`n
    The following directories are created if they do not already exist: 
"@
    foreach ($dir in $Directories.Values) {
        Write-Host "`n`t$dir"
    }
    Write-Host "`n"

    Write-Host @"
    The apps\tomcat directory is the Apache Tomcat runtime instance.`n
    The bin directory is where packages are installed.`n
"@
    Write-Host @"
    The following packages will be downloaded and installed on the system:
"@
    foreach ($key in $Packages.Keys) {
        Write-Host "`n`t$($key)"
    }
    Write-Host "`n"

    # Process: 
    # Create Directories > Download Packages > 
    # Verify Packages > Install Packages > Configure Packages
    Add-Directories -Path $Path
    Get-Packages -Path $Path -Pkgs $Packages 

    Install-OpenJDK -Path $Path
    Install-PostgreSQL -Path $Path
    Install-PowerShell -Path $Path
    Install-Tomcat -Path $Path

}


<#
.SYNOPSIS 
    Internal function to install OpenSSH.
.DESCRIPTION
    Install the Windows OpenSSH capability.
.EXAMPLE
    Install-OpenSSH
#>
function Install-OpenSSH {
    Write-Host "Installing and starting OpenSSH..."

    # Install OpenSSH (Windows Server 2022)
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

    # Starting OpenSSH
    Start-Service sshd

    Write-Host "OpenSSH installed and started."
}


<#
.SYNOPSIS 
    Install the prerequisite packages specified at the top of this file.
.DESCRIPTION
    Install the prerequisite packages specified at the top of this file; 
    requires administrative permission.
.PARAMETER Path
    If path is not provided, defaults to "\".
.EXAMPLE
    Install-OSPackages -Path "\"
#>
function Install-OSPackages {
    param (
        [string]$Path
    )

    Write-Host "Confirming this operating system is supported by this module."
    Assert-Environment

    if(-Not($Path)) {
        $Path = "\"
    } 

    Write-Host @"
    `nThe following packages will be downloaded and installed on this system:
"@
    foreach ($key in $OSPackages.Keys) {
        Write-Host "`n`t$($key)"
    }
    Write-Host "`n"

    # Process: 
    # Create Directories > Download Packages > 
    # Verify Packages > Install Packages > Configure Packages
    Add-Directories -Path $Path
    Get-Packages -Path $Path -Pkgs $OSPackages

    Install-PowerShell -Path $Path
    Install-VSCode -Path $Path
    Install-OpenSSH -Path $Path
    Initialize-OpenSSH -Path $Path

}


function Install-OpenJDK {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install OpenJDK 21.x
    Write-Host "Installing OpenJDK...`n"
    $filename = Get-PackageName -Name "openjdk"
    $dl_path = $Path + $Directories["downloads"]
    $installer = $dl_path + $filename
    $install_path = $Path + $Directories["bin"] + "jdk-21"
    $jdk_bin_path = $install_path + "\bin"
    # Launch installer
    Expand-Archive -Path $installer $install_path | Out-Null

    # Set permanent environment variables
    [Environment]::SetEnvironmentVariable("JDK_HOME", $install_path, "Machine")
    [Environment]::SetEnvironmentVariable("PATH", "$jdk_bin_path;$env:PATH", "Machine")

    Write-Host "OpenJDK installation completed.`n"
}


function Install-PostgreSQL {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install PostgreSQL 15.x
    Write-Host "Installing PostgreSQL...`n"
    $filename = Get-PackageName -Name "postgresql-15.10"
    $installer = $Path + $Directories["downloads"]  + $filename
    $bin_path = $Path + $Directories["bin"] + "postgresql\15"
    $data_path = $Path + $Directories["apps"] + "postgresql\14\data"

    $pwd = New-RandomPassword
    $pwd_filename = ".secret_psql"
    Save-RandomPassword -Path $Path -FileName $pwd_filename -Secret $pwd

    # Launch installer 
    .$installer --mode unattended --prefix $bin_path `
                --datadir $data_path --enable_acledit --superpassword $pwd

    # Set environment variables
    [Environment]::SetEnvironmentVariable("PSQL_HOME", $bin_path, "Machine")
    [Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$bin_path", "Machine")


    # Set firwall rule
    New-NetFirewallRule -Name "PostgreSQL Allow" -Enabled True `
    -DisplayName "PostgreSQL TCP 5432 Inbound Allow" -Direction Inbound `
    -Protocol TCP -LocalPort 5432 -RemoteAddress LocalSubnet -Action Allow `
    -Description "PostgreSQL TCP 5432 Inbound Allow"

    Write-Host "PostgreSQL installation completed.`n"
}


function Install-PowerShell {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install PowerShell 7.5.x
    Write-Host "Installing PowerShell...`n"
    $filename = Get-PackageName -Name "PowerShell"
    $filepath = $Path + $Directories["downloads"] + $filename
    $arguments = "/package $filepath /passive ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 ADD_PATH=1 DISABLE_TELEMETRY=1"

    # Launch installer
    Start-Process msiexec.exe -ArgumentList $arguments -Wait

    Write-Host "PowerShell installation completed.`n"
}


function Install-Tomcat {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Apache Tomcat 9.0.x
    Write-Host "Installing Apache Tomcat...`n"
    $filename = Get-PackageName -Name "apache"
    $apache_tomcat = $filename.split("\.")[0]
    $cat_home = $Path + $Directories["bin"] + $apache_tomcat
    $cat_bin = $cat_home + "\bin;"
    $cat_base = $Path + $Directories["tomcat"]

    $installer = $Path + $Directories["downloads"]  + $filename

    # Launch installer 
    .$installer /S /D=$cat_home

    # Install Tomcat Native
    # Extract and copy files to $cat_bin: tcnative-2.dll, openssl.exe
    $t_native = Get-PackageName -Name "tomcat-native"
    $tn_path = $Path + $Directories["downloads"] + $t_native
    Add-Type -Assembly System.IO.Compression.FileSystem
    $zip_file = [IO.Compression.ZipFile]::OpenRead($tn_path)
    $zip_file.Entries | Where-Object ({$_.Name -eq 'tcnative-2.dll' -and 
                                       $_.Name -eq 'openssl.exe'}) 
                      | foreach {$FileName = $_.Name 
                        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, 
                        "$cat_bin\$FileName", $true)} 
    $zip_file.Dispose()

    # Set permanent environment variables
    [Environment]::SetEnvironmentVariable("CATALINA_HOME", $cat_home, "Machine")
    [Environment]::SetEnvironmentVariable("PATH","$env:PATH;$cat_bin", "Machine")
    [Environment]::SetEnvironmentVariable("CATALINA_BASE", $cat_base, "Machine")
    Write-Host "Apache Tomcat installation completed.`n"
}


function Install-VSCode {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Visual Studio Code 1.98.x
    Write-Host "Installing Visual Studio Code...`n"
    $filename = Get-PackageName -Name "VSCodeSetup" 
    $installer = $Path + $Directories["downloads"] + $filename

    # Launch installer
    .$installer /VERYSILENT /MERGETASKS=!runcode

    Write-Host "Visual Studio Code installation completed.`n"
}


<#
.SYNOPSIS 
    Internal function to download a specific file.
.DESCRIPTION
    Download the file in the Uri to the file specified in FileName.
.PARAMETER FileName
    The name of the file to be saved. 
.PARAMETER Uri
    The uniform resource indicator of the file to be downloaded.
.EXAMPLE
    Invoke-Downloadd -FileName "test.zip" -Uri "https://test.com/downloads/test.zip"
#>
function Invoke-Download {
    param (
        [Parameter(Mandatory)]
        [string]$FileName,
        [Parameter(Mandatory)]
        [string]$Uri
    )
    Write-Host "Downloading $FileName..."
    $res = Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $FileName -PassThru

    return $res
}