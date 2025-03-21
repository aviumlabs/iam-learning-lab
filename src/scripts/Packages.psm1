# Copyright 2025 Michael Konrad - All Rights Reserved
# The Packages module creates the directory structure, installs and configures 
# the packages listed here. Additional the Packages module installs and  
# configures the Windows OpenSSH Capability and Windows Active Directory.

$ADDomain = [ordered]@{
    "DomainName" = "aviumlabs.test";
    "NetbiosName" = "AVIUMLABS";
    "ServerName" = "devsrv.aviumlabs.test";
    "Locality" = "Washington";
    "Organization" = "Aviumlabs";
    "Country" = "US";
}

$Directories = [ordered]@{
    "bin" = "bin\";
    "backups" = "apps\backups\";
    "downloads" = "apps\downloads\";
    "iiqkeys" = "apps\secrets\iiqkeys\";
    "secrets" = "apps\secrets\";
    "tomcat" = "apps\tomcat";
    "tomcat-bin" = "apps\tomcat\bin";
    "tomcat-conf" = "apps\tomcat\conf\";
    "tomcat-lib" = "apps\tomcat\lib\";
    "tomcat-logs" = "apps\tomcat\logs";
    "tomcat-webapps" = "apps\tomcat\webapps\";
    "tomcat-work" = "apps\tomcat\work\";
}

$BasePackages = [ordered]@{
    "PowerShell-7.5.0-win-x64.msi" = @{ 
        endpoint = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/PowerShell-7.5.0-win-x64.msi";
        sha = "6B988B7E236A8E1CF1166D3BE289D3A20AA344499153BDAADD2F9FEDFFC6EDA9";
        verified = $false;
    }
    "VSCodeSetup-x64-1.98.0.exe" = @{ 
        endpoint = "https://update.code.visualstudio.com/1.98.0/win32-x64/stable";
        sha = "1b02ae73047a79955c3a8b09fa01498609f447f2cb20d2362498b3a5d351a7de";
        verified = $false;
    }
}

$Packages = [ordered]@{
    "apache-tomcat-9.0.102.exe" = @{
        endpoint = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.102/bin/apache-tomcat-9.0.102.exe";
        sha = "8ddf5b5d41ec83b02a7bd74e9ccd36c99a56b6ba8a0f35e89d6bdc360c760ca7c56c64f93f7279d5ea9b1ec891c51e358f3d9de579571517bea4220c1778abc0";
        verified = $false;
    }
    "openjdk-21+35_windows-x64_bin.zip" = @{
        endpoint = "https://download.java.net/openjdk/jdk21/ri/openjdk-21+35_windows-x64_bin.zip";
        sha = "5434faaf029e66e7ce6e75770ca384de476750984a7d2881ef7686894c4b4944";
        verified = $false;
    }
    "postgresql-15.10-1-windows-x64.exe" = @{
        endpoint = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1259343";
        sha = "CDCD0A767A7AD4AB0C4A5A59DC931D33F8899D172B6E209EBE1BB76796264FF9";
        verified = $false;
    }
    "postgresql-42.7.5.jar" = @{
        endpoint = "https://jdbc.postgresql.org/download/postgresql-42.7.5.jar";
        sha = "69020B3BD20984543E817393F2E6C01A890EF2E37A77DD11D6D8508181D079AB";
        verified = $false;
    }
    "tomcat-native-2.0.8-openssl-3.0.14-win32-bin.zip" = @{
        endpoint = "https://dlcdn.apache.org/tomcat/tomcat-connectors/native/2.0.8/binaries/tomcat-native-2.0.8-openssl-3.0.14-win32-bin.zip";
        sha = "a4a8816668f14a7461711e25cb9277534981936c9e6f8b00ae55084cb265dc1d89ad07fa508ae2e1f7832236dafafbdd9d76a313c87f34e00ecfdfe75776638a";
        verified = $false;
    }
}

New-Variable -Name ADDoamin -Value $ADDomain -Scope Script -Force
New-Variable -Name Directories -Value $Directories -Scope Script -Force
New-Variable -Name BasePackages -Value $BasePackages -Scope Script -Force
New-Variable -Name Packages -Value $Packages -Scope Script -Force


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
    # Add the directory structure for this project
    Add-Directory -Path $Path -Name $Directories["bin"]
    Add-Directory -Path $Path -Name $Directories["backups"]
    Add-Directory -Path $Path -Name $Directories["downloads"]
    Add-Directory -Path $Path -Name $Directories["iiqkeys"]
    Add-Directory -Path $Path -Name $Directories["tomcat"]
    Add-Directory -Path $Path -Name $Directories["tomcat-bin"]
    Add-Directory -Path $Path -Name $Directories["tomcat-conf"]
    Add-Directory -Path $Path -Name $Directories["tomcat-lib"]
    Add-Directory -Path $Path -Name $Directories["tomcat-logs"]
    Add-Directory -Path $Path -Name $Directories["tomcat-webapps"]
    Add-Directory -Path $Path -Name $Directories["tomcat-work"]
    Write-Host "Directory setup completed."
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
        Write-Host "Adding directory $item_path."
        New-Item -Path $Path -Name $Name -ItemType Directory | Out-Null
    } else {
        Write-Host "Skipping path $item_path already existing.`n"
    }
}


<#
.SYNOPSIS 
    Internal function to confirm Windows operating system and version.
.DESCRIPTION
    Internal function to confirm environment, terminates script if the 
    environment is not supported.
.EXAMPLE
    Assert-Environment
#>
function Assert-Environment {
    try {
        $os = (Get-CimInstance -ClassName CIM_OperatingSystem).Caption
        if ( $os -match "Windows") {
            $os_version = [Environment]::OSVersion.Version.Major
            if ( $os_version -ge 10 ) {
                return $true
            } else {
                Throw "Operating system version not supported."
            }
        }
    } catch {
        $exception_name = $Error[0].Exception.GetType().FullName
        Write-Host "Exception name...$exception_name"
        Write-Error $Error[0]
    }
}


<#
.SYNOPSIS 
    Verifies the integrity a file based on its secure hash checksum.
.DESCRIPTION
    Verifies the integrity a file based on its secure hash checksum.
.PARAMETER PkgPath
    The full path of the package to be verified. 
.PARAMETER Hash
    The verification hash.
.PARAMETER Algorithm
    The secure hash algorithm to use for verification.
.EXAMPLE
    Assert-Integrity -PkgPath "test.zip" -Hash "ab3ed4..." -Alg "SHA256"
#>
function Assert-Integrity {
    param (
        [Parameter(Mandatory)]
        [string]$PkgPath,
        [Parameter(Mandatory)]
        [string]$Hash,
        [Parameter(Mandatory)]
        [string]$Alg
    )

    $dl_hash = Get-FileHash -Path $PkgPath -Algorithm $Alg

    return $dl_hash.Hash -eq $Hash
}


<#
.SYNOPSIS 
    Internal function to get closest multiple for the power 2.
.DESCRIPTION
    Internal function to get closest multiple for the power 2, to set
    JVM memory requirements.
.PARAMETER Num
    The current total amount of Random Access Memory
.EXAMPLE
    Get-ClosestMultiple -Num $total_ram
#>
function Get-ClosestMultiple {
    param (
        [Parameter(Mandatory)]
        [string]$Num
    )
    $Num =  $Num + 1
    $Num = $Num - ($Num % 2)

    return $Num
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
    Get-PackageName -Name "PowerShell" -Pkgs $BasePackages
    Get-PackageName -Name "OpenJDK" -Pkgs $Packages
#>
function Get-PackageName {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$Pkgs
    )
    foreach ($pkg in $Pkgs.Keys) {
        if ( $($pkg) -Match $Name ) {
            $filename = $($pkg)
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
    Get-Packages -Path "\" -Pkgs $BasePackages
    Get-Packages -Path "\" -Pkgs $Packages
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

    # Packages are defined at the top of the module
    foreach ($pkg in $Pkgs.Keys) {
        $download = @{
            FileName = $($pkg)
            Uri = $($Pkgs[$pkg]['endpoint'])
        }
        # check if package is already existing, if not download
        $pkg_path = $dl_path + $pkg
        if (-Not (Test-Path -Path $pkg_path)) {
            $res = Invoke-Download @download
            if ($res) {
                Write-Host "$pkg download completed."
                Write-Host "Verifying $pkg integrity..." 
                $pkg_sha = $Pkgs[$pkg]['sha']
                if ($pkg_sha.Length -eq 64) {
                    $ast = Assert-Integrity -PkgPath $pkg_path -Hash $pkg_sha -Alg 'SHA256'
                } elseif ($pkg_sha.Length -eq 128) {
                    $ast = Assert-Integrity -PkgPath $pkg_path -Hash $pkg_sha -Alg 'SHA512'
                }
                
                if ($ast) {
                    # Update verified dictionary
                    $Pkgs[$pkg]['verified'] = $true
                    Write-Host "$pkg integrity verified."
                } else {
                    Write-Host "$pkg intgretiy verification failed."
                }
            } else {
                Write-Host "$pkg download failed."
            }
        } else {
            Write-Host "Skipping $pkg already existing."
        }  
    }

    Set-Location -Path $Path
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

    if (-Not(Test-Path -Path $config_path)) {
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
            New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
        } else {
            Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' is existing."
        }

        # Set Default OpenSSH Shell 
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
        -Value "C:\Progra~1\PowerShell\7\pwsh.exe" -PropertyType String -Force

        Write-Host "OpenSSH configured."
    } else {
        Write-Host "OpenSSH already configured, not modifying."
    }
}


function Initialize-Tomcat {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Host "Configuring Apache Tomcat..."
    # Harden Tomcat
    # Backup and remove the following directories from tomcat\webapps 
    #   * docs
    #   * ROOT
    Write-Host "Backing up Apache Tomcat webapps..."
    $src_path = "$env:CATALINA_HOME\webapps"
    $date = Get-Date -Format "yyyyddMMHHmm"
    $bk_path = $Path + $Directories["backups"] + "$date-webapps.zip"

    Compress-Archive -Path $src_path -DestinationPath $bk_path | Out-Null
    Remove-Item "$src_path\docs" -Recurse -Force
    Remove-Item "$src_path\ROOT" -Recurse -Force
    Write-Host "Apache Tomcat webapss backup completed."

    # Configure CATALINA_BASE
    Write-Host "Configure CATALINA_BASE..."
    Copy-Item -Path "$env:CATALINA_HOME\bin\tomcat-juli.jar" -Destination "$env:CATALINA_BASE\bin"
    Copy-Item -Path "$env:CATALINA_HOME\conf\server.xml" -Destination "$env:CATALINA_BASE\conf"
    Copy-Item -Path "$env:CATALINA_HOME\conf\web.xml" -Destination "$env:CATALINA_BASE\conf"
    Copy-Item -Path "$env:CATALINA_HOME\conf\tomcat-users.xml" -Destination "$env:CATALINA_BASE\conf"
    Copy-Item -Path "$env:CATALINA_HOME\conf\logging.properties" -Destination "$env:CATALINA_BASE\conf"
    Write-Host "CATALINA_BASE configuration completed."

    # Tomcat TLS Certificate
    Write-Host "Generating Tomcat keystore..."
    $key_alias = $ADDomain["ServerName"]
    $locality = $ADDomain["Locality"]
    $org = $ADDomain["Organization"]
    $country = $ADDomain["Country"]
    $dname = "CN=$key_alias,L=$locality,O=$org,C=$country"
    $keystore_path = "$env:CATALINA_BASE\conf\tomcat.jks"
    $keystore_pass = New-RandomPassword
    $keystore_filename = ".secret_keystore"
    Save-RandomPassword -Path $Path -Name $keystore_filename -Secret $keystore_pass

    # Generate the keystore and private/public key pair for TLS communication
    keytool -genkeypair -keyalg EC -groupname secp384r1 -alias $key_alias -dname $dname `
    -validity 180 -keystore $keystore_path -storepass $keystore_pass
    Write-Host "Tomcat keystore $keystore_path generated."

    Write-Host "Opening inbound Apache Tomcat TLS port 8443..."
    # Open the Apache Tomcat inbound TLS port 8443
    New-NetFirewallRule -Name "Tomcat TLS" -Enabled True `
    -DisplayName "Tomcat TLS port 8443 inbound allow" -Direction Inbound `
    -Protocol TCP -LocalPort 8443 -RemoteAddress LocalSubnet -Action Allow `
    -Description "Tomcat Transport Layer Security Allow on Port 8443" | Out-Null
    Write-Host "Apache Tomcat port 8443 opened."

    Write-Host "Configuring Apache Tomcat TLS listener..."
    $server_xml_file = "$env:CATALINA_BASE\conf\server.xml"
    $line_to_match = '<Service name="Catalina">'
    $connector = "$line_to_match`n`n  <Connector port=""8443"" maxThreads=""200"" scheme=""https""`n`t
    secure=""true"" SSLEnabled=""true""`n`t
    keystoreFile=""$keystore_path""`n`t
    keystorePass=""$keystore_pass""`n`t
    keyAlias=""$key_alias""`n`t
    sslEnabledProtocols=""TLSv1.2+TLSv1.3""`n`t
    clientAuth=""false"" sslProtocol=""TLS""`n`t
    URIEncoding=""UTF-8"" />`n"

    # Update server.xml
    ((Get-Content -path $server_xml_file -Raw) -replace $line_to_match, $connector) `
    | Set-Content -Path $server_xml_file
    Write-Host "Apache Tomcat TLS listener configured."

    Write-Host "Configuring Apache Tomcat default encoding - UTF-8..."
    # Update Default Encoding to UTF-8
    $match_term = '<Connector port="8080" (.*\s+){4}'
    $append_term = '$&URIEncoding="UTF-8"'

    # Update server.xml
    ((Get-Content -Path $server_xml_file -Raw) -replace $match_term, $append_term) `
    | Set-Content -Path $server_xml_file
    Write-Host "Apache Tomcat UTF-8 encoding configured."

    Write-Host "Configuring Apache Tomcat ROOT redirect..."
    # Create ROOT Context redirect
    $context_xml_path = "$env:CATALINA_BASE\conf\context.xml"
    $context_xml = "<Context path=""/"" docBase=""${catalina.base}/webapps/identityiq""/>"
    Set-Content -Path $context_xml_path -Value $context_xml
    Write-Host "Apache Tomcat ROOT redirect configured."

    # Test Tomcat configuration
    Write-Host "Testing Apache Tomcat configuration..."
    $config_log = $Path + $Directories["backups"] + "$date-tomcat-configtest.log"
    Write-Host "Configtest log will be saved to $config_log"
    $tester = "$env:CATALINA_HOME\bin\configtest.bat"
    .$tester | Out-File -FilePath $config_log
    Write-Host "Apache Tomcat config test report generated."

    # Install Tomcat Service
    Write-Host "Installing Apache Tomcat Windows service..."
    $svc_installer = "$env:CATALINA_HOME\bin\service.bat"
    .$svc_installer install IdentityIQ | Out-Null
    Write-Host "Apache Tomcat Windows service installed."

    # Get the amount of physical memory
    $ram_info = (systeminfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
    $total_ram, $sz_label = $ram_info.Split()
    $total_ram = [int]$total_ram
    if (($sz_label -eq 'MB') -or ($sz_label -eq 'GB')) {
        if ($total_ram -gt 10000) {
            $jvm_max = Get-ClosestMultiple -Num ($total_ram * 0.6022)
            $jvm_min = Get-ClosestMultiple -Num ($total_ram * 0.1020)
        } 
    } else {
        $jvm_max = 512
        $jvm_min = 256
    }

    # Create temp softlink to the logs directory, 
    $temp_path = $Path + $Directories["tomcat"] + "\temp"
    $logs_path = $Path + $Directories["tomcat-logs"]
    cmd /c mklink /D $temp_path $logs_path

    Write-Host "Updating Apache Tomcat Windows service..."
    # Update Tomcat Service
    tomcat9 //US//IdentityIQ --Description "Apache Tomcat IdentityIQ Server" `
    --JvmMs $jvm_min --JvmMx $jvm_max ++JvmOptions9 `
    --add-exports=java.naming/com.sun.jndi.ldap=ALL-UNNAMED | Out-Null
    Write-Host "Apache Tomcat Windows service update completed."

    Write-Host "Logging Tomcat version..."
    $log_version = $Path + $Directories["backups"] + "$date-tomcat-version.log"
    version.bat | Out-File $log_version
    Write-Host "Tomcat version logged to $log_version."
}



<#
.SYNOPSIS 
    Install and configure Active Directory.
.DESCRIPTION
    Install and configure Active Directory based on the parameters defined 
    at the top of this script or the parameters passed in. A random password
    is generated for the `Safe Mode Administrator Password` and save to the 
    .\.secret_ad_safe_mode in the secrets directory.
.PARAMETER Path
    The root installation path, typically "\"
.PARAMETER ServerName
    Name of the server to install Active Directory Domain Services.
.PARAMETER DomainName
    Name of the Active Directory Domain.
.PARAMETER NetbiosName
    NetBios Name of the Active Directory Domain.
.EXAMPLE
    Install-ActiveDirectory -Path "\" -DomainName "aviumlabs.test" 
        -NetbiosName "AVIUMLABS"
    Install-ActiveDirectory -Path "\"
#>
function Install-ActiveDirectory {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$DomainName,
        [string]$NetbiosName
    )
    Write-Host "Installing Active Directory Domain Services..."

    # Install Active Directory
    Install-WindowsFeature AD-Domain-Services

    if (-Not $DomainName) {
        $DomainName = $ADDomain["DomainName"] 
    }

    if (-Not $NetbiosName) {
        $NetbiosName = $ADDomain["NetbiosName"]
    }

    Write-Host "Active Domain Services installed."
    Write-Host "Configuring the Active Directory domain $DomainName."
    # Configure Active Directory
    Import-Module ADDSDeployment

    $pwd = New-RandomPassword
    # Active Directory password policy requires uppercase, lowercase, numbers, 
    # and special characters
    $pwd = $pwd + '-+'
    $pwd_filename = ".secret_ad_safe_mode"
    Save-RandomPassword -Path $Path -Name $pwd_filename -Secret $pwd

    $pwd = ConvertTo-SecureString $pwd -AsPlainText -Force 

    # Set these values to your environment
    $ADArguments = @{
        CreateDNSDelegation           = $false
        DatabasePath                  = "C:\Windows\NTDS"
        DomainName                    = $DomainName
        SafeModeAdministratorPassword = $pwd
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
    Install-BasePackages -Path "\"
#>
function Install-BasePackages {
    param (
        [string]$Path
    )
    Write-Host "Confirming this operating system is supported by this module."
    Assert-Environment

    if(-Not($Path)) {
        $Path = "C:\"
    } 

    Write-Host @"
    `nThese packages will be downloaded and installed on this system as well
    as the Windows OpenSSH capability and Active Directory.
"@
    foreach ($pkg in $BasePackages.Keys) {
        Write-Host "`n`t$($pkg)"
    }

    Write-Host "`n"
    # Process: 
    # Create Directories > Download Packages > 
    # Verify Packages > Install Packages > Configure Packages
    Add-Directories -Path $Path
    Get-Packages -Path $Path -Pkgs $BasePackages

    Install-PowerShell -Path $Path
    Install-VSCode -Path $Path
    Install-OpenSSH -Path $Path
    Initialize-OpenSSH -Path $Path
    Install-ActiveDirectory -Path $Path
}


<#
.SYNOPSIS 
    Install the prerequisite packages specified at the top of this file.
.DESCRIPTION
    Install the prerequisite packages specified at the top of this file; 
    requires administrative permission.
.PARAMETER Path
    If path is not provided, defaults to "C:\". "C:"" is required by the 
    PostgreSQL installer.
.EXAMPLE
    Install-Packages -Path "C:\"
#>
function Install-Packages {
    param (
        [string]$Path
    )
    Write-Host "Confirming this operating system is supported by this module."
    Assert-Environment

    if(-Not($Path)) {
        $Path = "C:\"
    }

    Write-Host @"
    `nThis script will download, install and configure the packages required to 
    run SailPoint IdentityIQ 8.x on Windows 10 or higher.`n
    The following directories are created if they do not already exist: 
"@
    foreach ($dir in $Directories.Values) {
        Write-Host "`n`t$dir"
    }

    Write-Host @"
    `nThe following packages will be downloaded and installed on the system:
"@
    foreach ($pkg in $Packages.Keys) {
        Write-Host "`n`t$($pkg)"
    }
    Write-Host "`n"

    # Process: 
    # Create Directories > Download Packages > 
    # Verify Packages > Install Packages > Configure Packages
    Add-Directories -Path $Path
    Get-Packages -Path $Path -Pkgs $Packages

    Install-OpenJDK -Path $Path
    Install-PostgreSQL -Path $Path
    Install-Tomcat -Path $Path
    Initialize-Tomcat -Path $Path
    Set-PermanentEnvVariables -Path $Path
}


<#
.SYNOPSIS 
    Internal function to install OpenJDK.
.DESCRIPTION
    Install OpenJDK 21.x.
.PARAMETER Path
    The root path of the application installation.
.EXAMPLE
    Install-OpenSSH
#>
function Install-OpenJDK {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install OpenJDK 21.x
    Write-Host "Installing OpenJDK...`n"
    $pkg = Get-PackageName -Name "openjdk" -Pkgs $Packages
    if ($Packages[$pkg]['verified']) {
        $dl_path = $Path + $Directories["downloads"]
        $installer = $dl_path + $pkg
        $install_path = $Path + $Directories["bin"]
        $jdk_bin_path = $install_path + "jdk-21\bin"
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        # Set session environment variables
        $env:JAVA_HOME = $install_path + "jdk-21"
        $env:PATH = "$jdk_bin_path;$env:PATH"

        Write-Host "OpenJDK installation completed.`n"
    } else {
        Write-Host "OpenJDK not installed, package failed verification."
    }
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


function Install-PostgreSQL {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install PostgreSQL 15.x
    Write-Host "Installing PostgreSQL...`n"
    $pkg = Get-PackageName -Name "postgresql-15.10" -Pkgs $Packages
    if ($Packages[$pkg]['verified']) {
        $installer = $Path + $Directories["downloads"] + $pkg
        $bin_path = $Path + $Directories["bin"] + "postgresql\15"
        $data_path = $Path + $Directories["apps"] + "postgresql\15\data"

        $r_pwd = New-RandomPassword
        $pwd_filename = ".secret_psql"
        Save-RandomPassword -Path $Path -Name $pwd_filename -Secret $r_pwd

        # Launch installer
        .$installer --mode unattended --prefix $bin_path --datadir $data_path --enable_acledit 1 --superpassword $r_pwd | Out-Null

        # Set session environment variables
        $env:PSQL_HOME = $bin_path
        $env:PATH = "$env:PATH;$bin_path"

        # Set firwall rule
        New-NetFirewallRule -Name "PostgreSQL Allow" -Enabled True `
        -DisplayName "PostgreSQL TCP 5432 Inbound Allow" -Direction Inbound `
        -Protocol TCP -LocalPort 5432 -RemoteAddress LocalSubnet -Action Allow `
        -Description "PostgreSQL TCP 5432 Inbound Allow" | Out-Null

        Write-Host "PostgreSQL installation completed.`n"
    } else {
        Write-Host "PostgreSQL not installed, package failed verification."
    }
}


function Install-PowerShell {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install PowerShell 7.5.x
    Write-Host "Installing PowerShell...`n"
    $pkg = Get-PackageName -Name "PowerShell" -Pkgs $BasePackages
    if ($BasePackages[$pkg]['verified']) {
        $pkg_path = $Path + $Directories["downloads"] + $pkg
        $args = "/package $pkg_path /passive ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 ADD_PATH=1 DISABLE_TELEMETRY=1"

        # Launch installer
        Start-Process msiexec.exe -ArgumentList $args -Wait

        Write-Host "PowerShell installation completed.`n"
    } else {
        Write-Host "PowerShell not installed, package failed verification."
    }
}


function Install-Tomcat {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Apache Tomcat 9.0.x
    Write-Host "Installing Apache Tomcat...`n"
    $pkg = Get-PackageName -Name "apache-tomcat" -Pkgs $Packages
    if ($Packages[$pkg]['verified']) {
        $apache_tomcat = [string]$pkg.Split(".exe")
        $apache_tomcat = $apache_tomcat.Trim()
        $cat_home = $Path + $Directories["bin"] + $apache_tomcat
        $cat_bin = $cat_home + "\bin;"
        $cat_base = $Path + $Directories["tomcat"]

        $installer = $Path + $Directories["downloads"] + $pkg

        # Launch installer
        .$installer /S /D=$cat_home | Out-Null

        # Install Tomcat Native
        # Extract and copy files to $cat_bin: tcnative-2.dll, openssl.exe
        $t_native = Get-PackageName -Name "tomcat-native" -Pkgs $Packages
        if ($Packages[$t_native]['verified']) {
            Write-Host "Copy Tomcat Native files to Apache Tomcat bin directory."
            $tn_path = $Path + $Directories["downloads"] + $t_native
            Add-Type -Assembly System.IO.Compression.FileSystem
            $zip_file = [IO.Compression.ZipFile]::OpenRead($tn_path)
            $zip_file.Entries | Where-Object ({$_.Name -eq 'tcnative-2.dll' -and 
                                            $_.Name -eq 'openssl.exe'}) | foreach {
                                                $FileName = $_.Name 
                                                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, 
                                                "$cat_bin\$FileName", $true)} 
            $zip_file.Dispose()
            Write-Host "Tomcat Native file copy completed."
        } else {
            Write-Host "Tomcat Native not copied, package failed verification."
        }

        # Set session environment variables
        $env:CATALINA_HOME = $cat_home
        $env:PATH = "$env:PATH;$cat_bin"
        $env:CATALINA_BASE = $cat_base
        Write-Host "Apache Tomcat installation completed.`n"
    } else {
        Write-Host "Apache Tomcat not installed, package failed verification."
    }
}


function Install-VSCode {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Visual Studio Code 1.98.x
    # VSCODE_HOME = 'C:\Program Files\Microsoft VS Code'
    $vscode_bin = "C:\Program Files\Microsoft VS Code\bin\code"
    if (-Not (Test-Path -Path $vscode_bin)) {
        Write-Host "Installing Visual Studio Code...`n"
        $pkg = Get-PackageName -Name "VSCodeSetup" -Pkgs $BasePackages          
        if ($BasePackages[$pkg]['verified']) {
            $installer = $Path + $Directories["downloads"] + $pkg

            # Launch installer
            .$installer /VERYSILENT /MERGETASKS=!runcode

            Write-Host "Visual Studio Code installation completed.`n"
        } else {
            Write-Host "Visual Studio Code not installed, package failed verification."
        }
    } else {
        Write-Host "Visual Studio Code already installed, not updating."
    }
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


<#
.SYNOPSIS 
    Internal function to generate a new random password.
.DESCRIPTION
    Internal function to generate a new random password. This random password 
    generator does not support special characters.
.PARAMETER PwLength
    The lenth of password to genrate, defaults to 14.
.EXAMPLE
    New-RandomPassword -PwLength 20
#>
function New-RandomPassword {
    param (
        [int]$PwLength = 14
    )
    # Char 97 - 122 'a-z'
    # Char 65 - 90 'A-Z'
    # Char 48 - 57 '0-9'
    # Char 45 '-'
    # Char 43 '+'
    $char_list = [char]97..[char]122 + [char]65..[char]90 + [char]48..[char]57 `
    + [char]43 + [char]45

    $pass = -Join ((Get-Random -InputObject $char_list -Count $PwLength) | ForEach-Object {[char]$_})
    
    return $pass
}


<#
.SYNOPSIS 
    Internal function to save a generated random password to file.
.DESCRIPTION
    Internal function to save a generated random password to file.
.PARAMETER Path
    The root path of apps\secrets.
.PARAMETER Name
    The name of the file to save the gnerated randome password. The password 
    file will be saved to the apps\secrets directory.
.PARAMETER Secret
    The random generated password to be saved to the file.
.EXAMPLE
    Save-RandomPassword -Path "\" -Name ".secret_psql" -Secret $Secret
    Save-RandomPassword -Path "\" -Name ".secret_ad_safe_mode" -Secret $Secret
#>
function Save-RandomPassword {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Secret
    )

    $secrets_path = $Path + $Directories["secrets"] + $Name

    Out-File -FilePath $secrets_path -InputObject $Secret 

}


function Set-PermanentEnvVariables {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    $bin_path = $Path + $Directories["bin"]

    Write-Host "Setting permanent environment variables..."
    # Set JDK permanent environment variables
    $jdk_path = $bin_path + "jdk-21"
    $jdk_bin_path = $jdk_path + "\bin"
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdk_path, "Machine")
    [Environment]::SetEnvironmentVariable("PATH", "$jdk_bin_path;$env:PATH", "Machine")


    # Set PostgreSQL permanent environment variables
    $psql_bin_path = $Path + $Directories["bin"] + "\postgresql\15"
    [Environment]::SetEnvironmentVariable("PSQL_HOME", $psql_bin_path, "Machine")
    [Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$bin_path", "Machine")

    # Set Tomcat permanent environment variables
    $apache_tomcat = [string](Get-PackageName -Name "apache-tomcat" -Pkgs $Packages).Split(".exe")
    $apache_tomcat = $apache_tomcat.Trim()
    $cat_home = $bin_path + "$apache_tomcat"
    $cat_base = $Path + $Directories["tomcat"]
    [Environment]::SetEnvironmentVariable("CATALINA_HOME", $cat_home, "Machine")
    [Environment]::SetEnvironmentVariable("PATH","$env:PATH;$cat_bin", "Machine")
    [Environment]::SetEnvironmentVariable("CATALINA_BASE", $cat_base, "Machine")
    Write-Host "Permanent environment variables set."
}