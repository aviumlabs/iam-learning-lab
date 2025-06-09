# Aviumlab-Packages.psm1
# Copyright 2024, 2025 Michael Konrad 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Import common utilitiy functions
Import-Module $PSScriptRoot\Aviumlabs-Cutils.psm1

# Import common data sets
Import-Module $PSScriptRoot\Aviumlabs-Cds.psm1

# Update "DomainName", "NetbiosName", "RootDN", "ServerName", "Locality", 
# "Organization", and "Country" to your preferred settings. 
# 
# Do NOT change any other values. 
$ADDomain = [ordered]@{
    "DomainName" = "aviumlabs.test";
    "NetbiosName" = "AVIUMLABS";
    "RootDN" = "DC=aviumlabs,DC=test";
    "ServerName" = "devsrv.aviumlabs.test";
    "Locality" = "Washington";
    "Organization" = "Aviumlabs";
    "Country" = "US";
    "WorkforceOU" = "Workforce";
    "ServiceOU" = "ServiceAccounts";
    "GroupOU" = "Groups";
    "LogonServiceGroup" = "LogonAsService";
    "TomcatUser" = "svc-tomcat";
    "TomcatPass" = "";
    "IiqAdUser" = "svc-iiqad";
    "Environment" = "Development";
}

New-Variable -Name ADDoamin -Value $ADDomain -Scope Script -Force


# =============================================================================
# Public API
# =============================================================================
<#
.SYNOPSIS 
    Install the prerequisite packages specified in the Common Data Structures file.
.DESCRIPTION
    Install the prerequisite packages specified in the Common Data Structures file; 
    requires administrative permission.
.PARAMETER Path
    If path is not provided, defaults to "C:\".
.EXAMPLE
    Install-BasePackages -Path "D:\"
#>
function Install-BasePackages {
    param (
        [string]$Path = "C:\"
    )
    Write-Log -Message "Confirming this operating system is supported by this module."
    Assert-Environment

    Write-Log -Message "The following packages will be downloaded and installed: "
    foreach ($pkg in $BasePackages.Keys) {
        Write-Log -Message "`t$($pkg)"
    }

    Write-Log -Message "Additionally Windows OpenSSH capability and Active Directory will be installed and configured."

    # Process: 
    # Create Directories > Download Packages > 
    # Verify Packages > Install Packages > Configure Packages
    Add-Directories -Path $Path
    Get-Packages -Path $Path -Pkgs $BasePackages

    Install-PowerShell -Path $Path
    Install-OpenSSH -Path $Path
    Initialize-OpenSSH -Path $Path
    Install-ActiveDirectory -Path $Path
}

<#
.SYNOPSIS 
    Install a specific package from the package dictionary.
.DESCRIPTION
    Install a specific package from the package dictionary.; 
    requires administrative permission.
.PARAMETER Path
    Root path of the lab install, defaults to "C:\". 
.PARAMETER PkgName
    The short name of the package to be installed, e.g. "python".
.EXAMPLE
    Install-Package -Path "C:\" -PkgName "python"
#>
function Install-Package {
    param (
        [string]$Path = "C:\",
        [Parameter(Mandatory)]
        [string]$PkgName
    )
    Write-Log -Message "Confirming this operating system is supported by this module."
    Assert-Environment

    $pkg = Get-PackageName -Name $PkgName -Pkgs $Packages
    if ($pkg) {
        Write-Log -Message "Installing package $pkg..."
        Get-Package -Path $Path -Pkgs $Packages -Pkg $pkg
        Install-SPackage -Path $Path -Pkg $pkg
    } else {
        Write-Log -Message "Package $PkgName not found in the package dictionary."
    }
}


<#
.SYNOPSIS 
    Install the prerequisite packages specified in the Common Data Structures file.
.DESCRIPTION
    Install the prerequisite packages specified in the Common Data Structures file; 
    requires administrative permission.
.PARAMETER Path
    If path is not provided, defaults to "C:\". drive letter is required by the 
    PostgreSQL installer.
.EXAMPLE
    Install-Packages -Path "C:\"
#>
function Install-Packages {
    param (
        [string]$Path = "C:\"
    )
    Write-Log -Message "Confirming this operating system is supported by this module."
    Assert-Environment

    Write-Log -Message "The following directories are created if they do not already exist:"
    ForEach ($dir in $Directories.Values) {
        Write-Log -Message "`t$dir"
    }

    Write-Log -Message "The following packages will be downloaded and installed on the system:"
    ForEach ($pkg in $Packages.Keys) {
        Write-Log -Message "`t$($pkg)"
    }

    # Process: 
    # Create Directories > Download Packages > 
    # Verify Packages > Install Packages > Configure Packages
    Add-Directories -Path $Path
    Get-Packages -Path $Path -Pkgs $Packages

    # Install AD Management Tools and initialize baseline OUs
    Initialize-ADManagement
    # Initializes the system service accounts and security groups
    Initialize-ADServiceAccountsGroups -Path $Path
    # Applies the Development Server and updated Default Domain Group Policies
    Import-DevServerGPO -Path $Path
    # Applies the Logon As A Service Group Policy
    # Required for running Apache Tomcat under specified service account
    Import-LogonServiceGPO
    
    <##>
    Install-OpenJDK -Path $Path
    Install-PostgreSQL -Path $Path
    Install-ApacheAnt -Path $Path
    Install-ApacheJMeter -Path $Path
    Install-ApacheTomcat -Path $Path
    Install-VSCode -Path $Path
    Set-ApacheFSPermissions -Path $Path
    Initialize-ApacheTomcat -Path $Path
    Initialize-ApacheTomcatUsers -Path $Path
    Initialize-ApacheManagerHTML -Path $Path
    Set-PermanentEnvVariables -Path $Path
    
}


<#
.SYNOPSIS 
    Update Apache Tomcat.
.DESCRIPTION
    Update Apache Tomcat to the latest version included in the lab.
.PARAMETER Path
    Root path of the lab install, defaults to "C:\".
.EXAMPLE
    Update-ApacheTomcat -Path "C:\"
#>
function Update-ApacheTomcat {
    param (
        [string]$Path = "C:\"
    )
    # - Stop running service
    # - Backup IdentityIQ instance directory
    # - Remove Tomcat instance
    # - Install latest Tomcat 
    # - Copy conf files 
    # - Update server.xml
    # - Test Tomcat
    # - Install Tomcat instance
    # - Start Tomcat instance 
    $instance_name = "apache-"
    $instance_name += hostname
    $instance_name = $instance_name.ToLower()
    $instance_name += $TcInstanceId
    Write-Log -Message "Stopping Apache Tomcat IdentityIQ instance..."
    tomcat9 //SS/$instance_name | Out-Null 

    if ($?) {
        Write-Log -Message "Backing up Apache Tomcat IdentityIQ instance..."
        # Backup current Tomcat instance
        $bk_path = $Path + $Directories["backups"]
        $inst_path = $Path + $Directories["tomcat"]
        $date = Get-FormattedDate
        Compress-Archive -Path $inst_path -DestinationPath "$bk_path$date-$instance_name.zip"

        Write-Log -Message "Removing Apache Tomcat IdentityIQ instance..."
        tomcat9 //DS/$instance_name | Out-Null
        if ($?) {
            Write-Log -Message "Apache Tomcat IdentityIQ instance removed."
            Write-Log -Message "Installing latest Apache Tomcat..."
            Install-ApacheTomcat -Path $Path
            Set-ApacheFSPermissions -Path $Path
            Initialize-ApacheTomcat -Path $Path
            Initialize-ApacheTomcatUsers -Path $Path
            Initialize-ApacheManagerHTML -Path $Path

            # Start the Apache Tomcat IdentityIQ instance
            Write-Log -Message "Starting Apache Tomcat IdentityIQ instance..."
            tomcat9 //ES/$instance_name | Out-Null
            if ($?) {
                Write-Log -Message "Apache Tomcat IdentityIQ instance started successfully."
                Write-Log -Message "Apache Tomcat IdentityIQ instance updated successfully."
            } else {
                Write-Log -Message "Failed to start Apache Tomcat IdentityIQ instance."
            }
        } else {
            Write-Log -Message "Failed to remove Apache Tomcat IdentityIQ instance."
        }
    } else {
        Write-Log -Message "Failed to stop Apache Tomcat IdentityIQ instance, cannot update."
    } 
}


# =============================================================================
# Internal API
# =============================================================================
<#
.SYNOPSIS 
    Internal function to create the specific set of directories.
.DESCRIPTION
    Internal function to create the specific set of directories as 
    specified in this file.
.PARAMETER Path
    Root path.
.EXAMPLE
    Add-Directories -Path "C:\"
#>
function Add-Directories {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    Write-Log -Message "Creating lab directories..."
    # Add the directory structure for this project
    Add-Directory -Path $Path -Name $Directories["bin"]
    Add-Directory -Path $Path -Name $Directories["backups"]
    Add-Directory -Path $Path -Name $Directories["downloads"]
    Add-Directory -Path $Path -Name $Directories["iiqkeys"]
    Add-Directory -Path $Path -Name $Directories["tomcat"]
    Add-Directory -Path $Path -Name $Directories["postgresdata"]
    Write-Log -Message "Lab directories setup completed."
}


<#
.SYNOPSIS 
    Internal function to create a directory at the specified path.
.DESCRIPTION
    Internal function to create a directory at the specified path, if the path 
    is not existing.
.PARAMETER Path
    The root path for the lab install.
.PARAMETER Name
    The name of the directory to create.
.EXAMPLE
    Add-Directory -Path "C:\" -Name "apps"
    Add-Directory -Path "C:\apps\tmp\" -Name "example"
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
        Write-Log -Message "Adding directory $item_path..."
        New-Item -Path $Path -Name $Name -ItemType Directory | Out-Null
    } else {
        Write-Log -Message "Skipping path $item_path already existing."
    }
}


<#
.SYNOPSIS 
    Internal function to create CATALINA_BASE directories.
.DESCRIPTION
    Internal function to create instance specific CATALINA_BASE directories.
    This function is dependent on $env:CATALINA_BASE being defined.
.EXAMPLE
    Add-CatBaseDirectories
#>
function Add-CatBaseDirectories {
    $root = ($env:CATALINA_BASE).Split("\").Get(0)
    $root = $root + "\"
    $base_path = ($env:CATALINA_BASE).Split("C:\").Get(1)

    $tomcat_bin = "$base_path\bin"
    Add-Directory -Path $root -Name $tomcat_bin

    $tomcat_conf = "$base_path\conf"
    Add-Directory -Path $root -Name $tomcat_conf

    $tomcat_lib = "$base_path\lib"
    Add-Directory -Path $root -Name $tomcat_lib

    $tomcat_logs = "$base_path\logs"
    Add-Directory -Path $root -Name $tomcat_logs

    $tomcat_webapps = "$base_path\webapps"
    Add-Directory -Path $root -Name $tomcat_webapps

    $tomcat_work = "$base_path\work"
    Add-Directory -Path $root -Name $tomcat_work
}


<#
.SYNOPSIS 
    Internal function to add a member to a security group.
.DESCRIPTION
    Internal function to add a member to a security group. 
.EXAMPLE
    Add-MemberToSecurityGroup -Member $Member -SecurityGroup = $SecurityGroup
    Add-MemberToSecurityGroup -Member "CN=svc-tomcat,OU=ServiceAccounts,DC=aviumlabs,DC=test" -SecurityGroup "CN=LogonAsService,OU=Groups,DC=aviumlabs,DC=test"
#>
function Add-MemberToSecurityGroup {
    param (
        [Parameter(Mandatory)]
        [string]$Member,
        [Parameter(Mandatory)]
        [string]$SecurityGroup
    )
    Write-Log -Message "Adding member $Member to $SecurityGroup..."
    Add-ADGroupMember -Identity $SecurityGroup -Members $Member | Out-Null

    if ($?) {
        Write-Log -Message "Member $Member has been added to $SecurityGroup."
    } else {
        Write-Log -Message "Failed to add member $Member to $SecurityGroup."
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
.PARAMETER Alg
    The secure hash algorithm to use for verification.
.EXAMPLE
    Assert-Integrity -PkgPath "C:\test.zip" -Hash "ab3ed4..." -Alg "SHA256"
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
    Verifies if Tomcat Native has already been installed.
.DESCRIPTION
    Verifies if Tomcat Native has already been installed.
.PARAMETER Path
    The root path of the lab install, defaults to "C:\".
.EXAMPLE
    Assert-TomcatNative -Path "C:\"
#>
function Assert-TomcatNative {
    param (
        [string]$Path = "C:\"
    )
    $apache_tomcat = [string]$pkg.Split("-windows-x64.zip")
    $apache_tomcat = $apache_tomcat.Trim()
    $cat_home = $Path + $Directories["bin"] + $apache_tomcat
    $cat_bin = $cat_home + "\bin"

    if (Test-Path -Path "$cat_bin\openssl.exe" -And Test-Path -Path "$cat_bin\tcnative-2.dll") {
        Write-Log -Message "Apache Tomcat Native is already installed."
        return $true
    }
    
    return $false
}


<#
.SYNOPSIS 
    Internal function to backup a group policy.
.DESCRIPTION
    Internal function to backup a group policy.
.PARAMETER Path
    The root path of the lab installation.
.PARAMETER GpoName
    The name of the group policy to backup.
.EXAMPLE
    Backup-GroupPolicy -Path "C:\" -GpoName "Default Domain Policy"
#>
function Backup-GroupPolicy {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$GpoName
    )
    # Export a GPO
    $bk_path = $Path + $Directories["backups"]
    Backup-Gpo -Name $GpoName -Path $bk_path -Comment $GpoName
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
        [int]$Num
    )
    $Num = $Num + 1
    $Num = $Num - ($Num % 2)

    return $Num
}


<#
.SYNOPSIS 
    Internal function to download a specific package.
.DESCRIPTION
    Internal function to download and verify a specific package.
.PARAMETER Path
    Root path of the lab install.
.PARAMETER Pkg
    The package to download.
.PARAMETER Pkgs
    Packages data set.
.EXAMPLE
    Get-Package -Path $Path -Pkg $Pkg -Pkgs $Pkgs
#>
function Get-Package {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Pkg,
        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$Pkgs
    )
    $dl_path = $Path + $Directories["downloads"]
    Set-Location -Path $dl_path

    $download = @{
        FileName = $Pkg
        Uri = $($Pkgs[$Pkg]['endpoint'])
    }

    # check if package is already existing, if not download
    $res = Invoke-Download @download
    
    if ($res) {
        Write-Log -Message "$Pkg download completed."
        Write-Log -Message "Verifying $Pkg integrity..." 
        $pkg_path = $dl_path + $Pkg
        $pkg_sha = $($Pkgs[$Pkg]['vhash'])
        $pkg_alg = $($Pkgs[$Pkg]['halg'])
        $ast = Assert-Integrity -PkgPath $pkg_path -Hash $pkg_sha -Alg $pkg_alg

        if ($ast) {
            # Update verified
            $Pkgs[$Pkg]['verified'] = $true
            Write-Log -Message "$Pkg integrity verified."
        } else {
            Write-Log -Message "$Pkg integrity verification failed."
            Write-Log -Message "Re-attempting download..."
            Get-Package -Path $Path -Pkg $Pkg -Pkgs $Pkgs
        }
    } else {
        Write-Log -Message "$Pkg download failed."
        Write-Log -Message "Re-attempting download..."
        Get-Package -Path $Path -Pkg $Pkg -Pkgs $Pkgs
    }
}


<#
.SYNOPSIS 
    Internal function to download a specific set of packages.
.DESCRIPTION
    Download the packages passed in the Pkgs dictionary; package dictionaries 
    are defined in the Aviumlabs-Cds.psm1 module.
.PARAMETER Path
    Root path of the lab installation.
.PARAMETER Pkgs
    The packages dictionary to be download.
.EXAMPLE
    Get-Packages -Path "C:\" -Pkgs $BasePackages
    Get-Packages -Path "C:\" -Pkgs $Packages
#>
function Get-Packages {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [System.Collections.Hashtable]$Pkgs
    )
    $dl_path = $Path + $Directories["downloads"]
    # Packages are defined at the top of the module
    ForEach ($pkg in $Pkgs.Keys) {
        # Special case for ant-contrib, automated download not working
        if ($pkg -eq "ant-contrib-1.0b3-bin.zip") {
            $ant_contrib_path = $($Pkgs[$pkg]['endpoint'])
            Copy-Item -Path $ant_contrib_path -Destination $dl_path
            $pkg_path = $dl_path + $pkg
            $pkg_sha = $($Pkgs[$pkg]['vhash'])
            $pkg_alg = $($Pkgs[$pkg]['halg'])
            $ast = Assert-Integrity -PkgPath $pkg_path -Hash $pkg_sha -Alg $pkg_alg
            if ($ast) {
                $Pkgs[$pkg]['verified'] = $true
                Write-Log -Message "$pkg integrity verified."
            }
        } else {
            Get-Package -Path $Path -Pkg $pkg -Pkgs $Pkgs
        } 
    }

    Set-Location -Path $Path
}
    

<#
.SYNOPSIS 
    Internal function to import Development Server group policy.
.DESCRIPTION
    Internal function to import Development Server group policy. 
    Removes the requirement to press CTRL-ALT-DEL to login and lock 
    screen timeout - NOT suitable for production.
    This function is also overloaded to update the migration table.
.PARAMETER Path
    Root path of the lab installation.
.EXAMPLE
    Import-DevServerGPO -Path "C:\"
#>
function Import-DevServerGPO {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
    if ($domain) {
        # Update migration table with current domain
        $mig_table_path = "$PSScriptRoot\GPO\testdomain.migtable"
        $update_mig_path = "$PSScriptRoot\GPO\newdomain.migtable"
        $match_term = "testdomain.test"
        ((Get-Content -Path $mig_table_path -Raw) -Replace $match_term, $domain) `
        | Set-Content -Path $update_mig_path

        Write-Log -Message "Importing Development Server group policy..."
        # Import Development Server GPO
        $gpo_path = "$PSScriptRoot\GPO\DevelopmentServer"
        $policy_name = "Development Server Policy"
        Import-GPO -BackupGpoName $policy_name -TargetName $policy_name `
        -Path $gpo_path -Domain $domain -MigrationTable $update_mig_path `
        -CreateIfNeeded | Out-Null

        # Confirm the command executed successfully
        if ($?) {
            Write-Log -Message "Succesfully imported Development Server group policy."
            Write-Log -Message "Linking Development Server group policy to domain..."
            # Link the GPO to the top level domain; for ease of use as a development 
            # environment
            $domain_dn = $ADDomain["RootDN"]
            Get-GPO $policy_name | New-GPLink -Target $domain_dn -LinkEnabled Yes | Out-Null

            if ($?) {
                Write-Log -Message "Development Server group policy has been linked to the domain."
            } else {
                Write-Log -Message "Failed to link the Development Server group policy."
            }
        } else {
            Write-Log -Message "Failed to import Development Server group policy."
        }
    } else {
        Write-Log -Message "Failed to import group policy, unable to get AD domain."
    }
}


<#
.SYNOPSIS 
    Internal function to import logon as a service group policy.
.DESCRIPTION
    Internal function to import logon as a service group policy. Dependent 
    on the security group LogonAsService existing in the domain. This security 
    group and the Apache Tomcat service account are automatically created 
    prior to running this function. 
.EXAMPLE
    Import-LogonServiceGPO
#>
function Import-LogonServiceGPO {
    $domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
    if ($domain) {
        Write-Log -Message "Importing Logon As A Service group policy..."
        # Import GPO
        $gpo_path = "$PSScriptRoot\GPO\LogonAsService"
        $policy_name = "Logon As A Service Policy"
        $mig_table_path = "$PSScriptRoot\GPO\newdomain.migtable"

        Import-GPO -BackupGpoName $policy_name -TargetName $policy_name `
        -Path $gpo_path -Domain $domain -MigrationTable $mig_table_path `
        -CreateIfNeeded | Out-Null
        
        if ($?) {
            Write-Log -Message "Succesfully imported Logon As A Service group policy."
            Write-Log -Message "Linking Logon As A Service group policy to domain..."
            # Link the GPO to the top level domain; for ease of use as a development 
            # environment
            $domain_dn = $ADDomain["RootDN"]
            Get-GPO $policy_name | New-GPLink -Target $domain_dn -LinkEnabled Yes | Out-Null

            if ($?) {
                Write-Log -Message "Logon As A Service group policy has been linked to the domain."
            } else {
                Write-Log -Message "Failed to link the Logon As A Service group policy."
            }
        } else {
            Write-Log -Message "Failed to import Logon As A Service group policy."
        }
    } else {
        Write-Log -Message "Failed to import Logon As A Service, unable to get AD domain."
    }
}


<#
.SYNOPSIS 
    Internal function to initialize Active Directory Management Tools.
.DESCRIPTION
    Internal function to initialize Active Directory Management Tools. Creates 
    the Organizational Units defined in the ADDomain dictionary at the top of 
    this script.
.PARAMETER Path
    Root path the download directory.
.PARAMETER Pkgs
    The packages dictionary to be download.
.EXAMPLE
    Initialize-ADManagement
#>
function Initialize-ADManagement {
    Write-Log -Message "Installing Active Directory Management Tools..."
    # Get-WindowsFeature | ? Name -like 'RSAT*'
    Install-WindowsFeature RSAT-ADDS-Tools | Out-Null
    if ($?) {
        Write-Log -Message "Active Directory Management Tools installed."
    } else {
        Write-Log -Message "Failed to install Active Directory Management Tools."
    }
    
    # Setup AD Structure
    Import-Module ActiveDirectory

    # Setup Workforce OU
    $workforce_ou = $ADDomain["WorkforceOU"] 
    New-ADOrganizationalUnit $workforce_ou -Path $ADDomain["RootDN"]

    # Setup Service Accounts OU
    $svc_ou = $ADDomain["ServiceOU"]
    New-ADOrganizationalUnit $svc_ou -Path $ADDomain["RootDN"]

    # Setup Groups OU
    $grp_ou = $ADDomain["GroupOU"]
    New-ADOrganizationalUnit $grp_ou -Path $ADDomain["RootDN"]
}


<#
.SYNOPSIS 
    Internal function to initialize AD service accounts and security groups.
.DESCRIPTION
    Internal function to initialize AD service accounts and security groups. Creates 
    the service accounts and security groups defined in the ADDomain dictionary at the 
    top of this script. Saves the randomly generated passwords to the `secrets`
    directory.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Initialize-ADServiceAccountsGroups -Path $Path
    Initialize-ADServiceAccountsGroups -Path "C:\"
#>
function Initialize-ADServiceAccountsGroups {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Initializing system service accounts in AD..."
    $svc_pass = New-RandomPassword
    $svc_pass += '-+'
    $svc_filename = $SecretFiles["ADSafeModeFile"]
    Save-RandomPassword -Path $Path -Name $svc_filename -Secret $svc_pass
    
    # Create the svc-iiqad service account
    $AccountName = $ADDomain["IiqAdUser"]
    $AccountPassword = ConvertTo-SecureString "$svc_pass" -AsPlainText -Force
    $Description = "IdentityIQ AD service account"
    New-ADServiceAccount -AccountName $AccountName -AccountPassword $AccountPassword -Description $Description

    # Add IIQ AD service account to Account Operators security group
    $Member = Get-ADUser $ADDomain["IiqAdUser"]
    $SecurityGroup = "CN=Account Operators,CN=Builtin," + $ADDomain["RootDN"]
    Add-MemberToSecurityGroup -Member $Member -SecurityGroup $SecurityGroup

    $svc_pass = New-RandomPassword
    $svc_pass += '-+'
    $svc_filename = $SecretFiles["TomcatSvcFile"]
    Save-RandomPassword -Path $Path -Name $svc_filename -Secret $svc_pass
    # Save password to dictionary for Apache Tomcat initialization
    $ADDomain["TomcatPass"] = $svc_pass

    # Create the svc-tomcat service account
    $AccountName = $ADDomain["TomcatUser"]
    $AccountPassword = ConvertTo-SecureString "$svc_pass" -AsPlainText -Force
    $Description = "Apache Tomcat service account"
    New-ADServiceAccount -AccountName $AccountName -AccountPassword $AccountPassword -Description $Description

    # Create the LogonAsService security group
    $GroupName = $ADDomain["LogonServiceGroup"]
    $Description = "Logon As a Service security group."
    New-ADSecurityGroup -GroupName $GroupName -Description $Description | Out-Null

    # Add Apache Tomcat service account to Logon As a Service security group
    $Member = Get-ADUser $ADDomain["TomcatUser"]
    $SecurityGroup = Get-ADGroup $ADDomain["LogonServiceGroup"]
    Add-MemberToSecurityGroup -Member $Member -SecurityGroup $SecurityGroup

    Write-Log -Message "Initialization of AD service accounts is completed."
}


<#
.SYNOPSIS 
    Internal function to configure an Apache Tomcat instance.
.DESCRIPTION
    Configures an Apache Tomact instance base on the configuration in this 
    script.
.PARAMETER Path
    Root path of the lab installation.
.PARAMETER InstanceId
    The name of the instance to configure, defaults to <hostname>-a.
.EXAMPLE
    Initialize-ApacheTomcat -Path "C:\" 
    Initialize-ApacheTomcat -Path "C:\" -InstanceId "devsrv-b"
#>
function Initialize-ApacheTomcat {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$InstanceId
    )
    if (-Not $InstanceId) {
        $instance_name = hostname
        $instance_name = $instance_name.ToLower()
        $instance_name += $TcInstanceId
    } else {
        $instance_name = $InstanceId
    }
    $env:TC_INSTANCE = $instance_name
    Write-Log -Message "Configuring Apache Tomcat..."
    Add-CatBaseDirectories
    # Harden Tomcat
    # Backup and remove the following directories from tomcat\webapps 
    #   * docs
    #   * ROOT
    Write-Log -Message "Backing up Apache Tomcat webapps..."
    $src_path = "$env:CATALINA_HOME\webapps"
    $date = Get-FormattedDate
    $bk_path = $Path + $Directories["backups"] + "$date-webapps.zip"

    Compress-Archive -Path $src_path -DestinationPath $bk_path | Out-Null
    Remove-Item "$src_path\docs" -Recurse -Force
    Remove-Item "$src_path\examples" -Recurse -Force
    Remove-Item "$src_path\ROOT" -Recurse -Force
    Write-Log -Message "Apache Tomcat webapss backup completed."

    # Configure CATALINA_BASE
    Write-Log -Message "Configure CATALINA_BASE..."
    Copy-Item -Path "$env:CATALINA_HOME\bin\tomcat-juli.jar" -Destination "$env:CATALINA_BASE\bin"
    Copy-Item -Path "$env:CATALINA_HOME\conf\server.xml" -Destination "$env:CATALINA_BASE\conf"
    Copy-Item -Path "$env:CATALINA_HOME\conf\web.xml" -Destination "$env:CATALINA_BASE\conf"
    Copy-Item -Path "$env:CATALINA_HOME\conf\tomcat-users.xml" -Destination "$env:CATALINA_BASE\conf"
    Copy-Item -Path "$env:CATALINA_HOME\conf\logging.properties" -Destination "$env:CATALINA_BASE\conf"
    Write-Log -Message "CATALINA_BASE configuration completed."

    # Tomcat TLS Certificate
    Write-Log -Message "Generating Tomcat keystore..."
    $key_alias = $ADDomain["ServerName"]
    $locality = $ADDomain["Locality"]
    $org = $ADDomain["Organization"]
    $country = $ADDomain["Country"]
    $dname = "CN=$key_alias,L=$locality,O=$org,C=$country"
    $keystore_path = "$env:CATALINA_BASE\conf\tomcat.jks"
    $keystore_pass = New-RandomPassword
    $keystore_filename = $SecretFiles["KeyStoreFile"]
    Save-RandomPassword -Path $Path -Name $keystore_filename -Secret $keystore_pass

    # Generate the keystore and private/public key pair for TLS communication
    keytool -genkeypair -keyalg EC -groupname secp384r1 -alias $key_alias -dname $dname `
    -validity 180 -keystore $keystore_path -storepass $keystore_pass
    Write-Log -Message "Tomcat keystore $keystore_path generated."

    Write-Log  -Message "Opening inbound Apache Tomcat TLS port 8443..."
    # Open the Apache Tomcat inbound TLS port 8443
    New-NetFirewallRule -Name "Tomcat TLS" -Enabled True `
    -DisplayName "Tomcat TLS port 8443 inbound allow" -Direction Inbound `
    -Protocol TCP -LocalPort 8443 -RemoteAddress LocalSubnet -Action Allow `
    -Description "Tomcat Transport Layer Security Allow on Port 8443" | Out-Null
    Write-Log -Message "Apache Tomcat port 8443 opened."

    Write-Log -Message "Backing up Apache Tomcat CATALINA_BASE\conf..."
    $src_path = "$env:CATALINA_BASE\conf\*"
    $date = Get-FormattedDate
    $bk_path = $Path + $Directories["backups"] + "$date-cat-base-conf.zip"

    Compress-Archive -Path $src_path -DestinationPath $bk_path | Out-Null
    Write-Log -Message "Apache Tomcat CATALINA_BASE\conf backup completed."

    Write-Log -Message "Configuring Apache Tomcat TLS listener..."
    $server_xml_path = "$env:CATALINA_BASE\conf\server.xml"
    $line_to_match = '<Service name="Catalina">'
    $connector = "$line_to_match`n`n  <Connector port=""8443"" maxThreads=""200"" scheme=""https""
    `tsecure=""true"" SSLEnabled=""true""
    `tkeystoreFile=""$keystore_path""
    `tkeystorePass=""$keystore_pass""
    `tkeyAlias=""$key_alias""
    `tsslEnabledProtocols=""TLSv1.2+TLSv1.3""
    `tclientAuth=""false"" sslProtocol=""TLS""
    `tURIEncoding=""UTF-8"" />`n"

    # Update server.xml
    ((Get-Content -path $server_xml_path -Raw) -Replace $line_to_match, $connector) `
    | Set-Content -Path $server_xml_path
    Write-Log -Message "Apache Tomcat TLS listener configured."

    Write-Log -Message "Configuring Apache Tomcat default encoding - UTF-8..."
    # Update Default Encoding to UTF-8
    $match_term = '<Connector port="8080" (.*\s+){4}'
    $append_term = '$&URIEncoding="UTF-8"'

    # Update server.xml
    ((Get-Content -Path $server_xml_path -Raw) -Replace $match_term, $append_term) `
    | Set-Content -Path $server_xml_path
    Write-Log -Message "Apache Tomcat UTF-8 encoding configured."

    Write-Log -Message "Configuring Apache Tomcat Engine settings..."
    $server_name = hostname
    $server_name = $server_name.ToLower()
    # Update defaultHost to hostname
    
    $match_term = '(<Engine name="Catalina" defaultHost=")localhost">'
    ((Get-Content -Path $server_xml_path -Raw) -Replace $match_term, `
    ('$1' + $server_name + '"' + " jvmRoute=""$instance_name"">")) `
    | Set-Content -Path $server_xml_path

    # Update Host to hostname
    $match_term = '(Host name=")localhost"'
    ((Get-Content -Path $server_xml_path -Raw) -Replace $match_term, ('$1' + $server_name + '"')) `
    | Set-Content -Path $server_xml_path

    $match_term = '(prefix=")localhost_access_log'
    ((Get-Content -Path $server_xml_path -Raw) -Replace $match_term, ('$1' + "$instance_name-access-log")) `
    | Set-Content -Path $server_xml_path
    Write-Log -Message "Apache Tomcat Engine settings completed."

    Write-Log -Message "Configuring Apache Tomcat logging.properites..."
    $logging_prop_path = "$env:CATALINA_BASE\conf\logging.properties"

    $match_term = 'localhost'
    ((Get-Content -Path $logging_prop_path -Raw) -Replace $match_term, $instance_name) `
    | Set-Content -Path $logging_prop_path

    $match_term = '(1catalina.org.apache.juli.AsyncFileHandler.prefix = )catalina.'
    ((Get-Content -Path $logging_prop_path -Raw) -Replace $match_term, ('$1' + $instance_name +'-catalina.')) `
    | Set-Content -Path $logging_prop_path

    $match_term = '(3manager.org.apache.juli.AsyncFileHandler.prefix = )manager.'
    ((Get-Content -Path $logging_prop_path -Raw) -Replace $match_term, ('$1' + $instance_name +'-manager.')) `
    | Set-Content -Path $logging_prop_path

    $match_term = '(4host-manager.org.apache.juli.AsyncFileHandler.prefix = )host-manager.'
    ((Get-Content -Path $logging_prop_path -Raw) -Replace $match_term, ('$1' + $instance_name +'-host-manager.')) `
    | Set-Content -Path $logging_prop_path
    Write-Log -Message "Apache Tomcat logging.properties configuration completed."

    Write-Log -Message "Configuring Apache Tomcat ROOT redirect..."
    # Create ROOT Context redirect
    $context_xml_path = "$env:CATALINA_BASE\conf\context.xml"
    $context_xml = "<Context path=""/"" docBase=""/identityiq""/>"
    Set-Content -Path $context_xml_path -Value $context_xml
    Write-Log -Message "Apache Tomcat ROOT redirect configured."

    # Install Tomcat Service
    Write-Log -Message "Installing Apache Tomcat Windows service..."
    $svc_installer = "$env:CATALINA_HOME\bin\service.bat"
    $svc_name = "apache-$instance_name"
    .$svc_installer install $svc_name | Out-Null
    Write-Log -Message "Apache Tomcat Windows service installed."

    # Get the amount of physical memory
    $ram_info = (systeminfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
    $total_ram, $sz_label = $ram_info.Split()
    $total_ram = [int]$total_ram
    if (($sz_label -eq 'MB') -or ($sz_label -eq 'GB')) {
        if ($total_ram -gt 8000) {
            $jvm_max = Get-ClosestMultiple -Num ($total_ram * 0.6022)
            $jvm_min = Get-ClosestMultiple -Num ($total_ram * 0.1020)
        } 
    } else {
        $jvm_max = 512
        $jvm_min = 256
    }

    # Create temp softlink to the logs directory, 
    $temp_path = "$env:CATALINA_BASE\temp"
    $logs_path = "$env:CATALINA_BASE\logs"
    cmd /c mklink /D $temp_path $logs_path

    $svc_user = $ADDomain["NetbiosName"] + "\" + $ADDomain["TomcatUser"]
    $std_out_filename = $instance_name + "-iiq-stdout.log"
    $std_err_filename = $instance_name + "-iiq-stderr.log"

    Write-Log "Updating Apache Tomcat Windows service..."
    # Update Tomcat Service
    tomcat9 //US//$svc_name --Description "Apache Tomcat IdentityIQ Instance" `
    --JvmMs $jvm_min --JvmMx $jvm_max ++JvmOptions9 --add-exports=java.naming/com.sun.jndi.ldap=ALL-UNNAMED `
    --LogPrefix "$instance_name-common-daemons" `
    --ServiceUser $svc_user `
    --ServicePassword $ADDomain["TomcatPass"] `
    --StdOutput $std_out_filename `
    --StdError $std_err_filename | Out-Null
    Write-Log -Message "Apache Tomcat Windows service update completed."

    # Start Tomcat Service to create Engine directory
    tomcat9 //ES//$svc_name | Out-Null
    if ($?) {
        Write-Log -Message "Apache Tomcat instance started."
    }
    tomcat9 //SS/$svc_name | Out-Null
    if ($?) {
        Write-Log -Message "Apache Tomcat instance stopped."
    }

    # Test Tomcat configuration
    Write-Log -Message "Testing Apache Tomcat configuration..."
    $config_log = $Path + $Directories["backups"] + "$date-tomcat-configtest.log"
    Write-Log "Configtest log saved to $config_log"
    $tester = "$env:CATALINA_HOME\bin\configtest.bat" 
    .$tester > $config_log 2>&1
    Write-Log "Apache Tomcat config test report generated."

    Write-Log "Adding Apache Tomcat manager application..."
    $mgr_base_path = "$env:CATALINA_BASE\conf\Catalina\"
    Add-Directory -Path $mgr_base_path -Name $server_name

    $manager_xml_path = $mgr_base_path + "$server_name\manager.xml"
    $manager_xml_content = @"
    <Context privileged="true" antiResourceLocking="false"
             docBase="`${catalina.home}/webapps/manager">
      <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                       sameSiteCookies="strict" />
      <Valve className="org.apache.catalina.valves.RemoteAddrValve"
             allow="127\.\d+\.\d+\.\d+|192\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" />
      <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
    </Context>
"@
    Set-Content -Path $manager_xml_path -Value $manager_xml_content
    Write-Log "Apache Tomcat manager application added."

    Write-Log -Message "Logging Tomcat version..."
    $log_version = $Path + $Directories["backups"] + "$date-tomcat-version.log"
    version.bat | Out-File $log_version
    Write-Log -Message "Tomcat version logged to $log_version."

    Write-Log -Message "Setting $svc_name Windows service to start automatically..."
    Set-Service -Name $svc_name -StartupType Automatic | Out-Null
    Write-Log -Message "$svc_name Windows service set to start automatically."
}


<#
.SYNOPSIS 
    Internal function to customize Apache Tomcat manager GUI.
.DESCRIPTION
    Internal function to customize Apache Tomcat manager GUI, to show company 
    and environment, i.e., Development, Staging, Production as set in the 
    ADDomain["Enviornment"] setting. 
.PARAMETER Path
    Root path of the lab installation.
.EXAMPLE
    Initialize-ApacheManagerHTML -Path "C:\" 
#>
function Initialize-ApacheManagerHTML {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Backup originial web.xml file
    Write-Log -Message "Backing up Apache Tomcat manager web.xml..."
    $manager_web_xml_path = "$env:CATALINA_HOME\webapps\manager\WEB-INF\web.xml"
    $date = Get-FormattedDate
    $bk_path = $Path + $Directories["backups"] + "manager-web-xml.zip"

    Compress-Archive -Path $manager_web_xml_path -DestinationPath $bk_path | Out-Null
    Write-Log -Message "Apache Tomcat manager web.xml backup completed."

    # Set a sub title for Tomcat Manager application
    # Parameter is set in the $env:CATALINA_HOME\webapps\manager\WEB-INF\web.xml
    #<!-- Uncomment this to set a sub-title for the manager web application main
    #     page. It must be XML escaped, valid HTML.
    #<init-param>
    #  <param-name>htmlSubTitle</param-name>
    #  <param-value>Sub-Title</param-value>
    #</init-param>
    #-->
    $company_name = $ADDomain["Organization"]
    $iiq_env = $ADDomain["Environment"]
    $subtitle = "$company_name &lt;br&gt;&lt;i style=&apos;color:GoldenRod&apos;&gt;$iiq_env&lt;/i&gt;"

    # Set the manager application sub-title value
    $match_term = '([\s]*<param-value>)Sub-Title(</param-value>)'
    ((Get-Content -Path $manager_web_xml_path -Raw) -Replace $match_term, `
    ('$1' + $subtitle + '$2')) | Set-Content -Path $manager_web_xml_path

    # Remove xml comment tags
    $match_content = "(<!-- Uncomment this to set a sub-title[\s\S]*?)(<init-param>[\s\S\n]*?<param-name>htmlSubTitle</param-name>[\s\S\n.,]*?)-->"
    ((Get-Content -Path $manager_web_xml_path -Raw) -Replace $match_content, ('$1' + "-->`n" + '    $2')) `
    | Set-Content -Path $manager_web_xml_path
}


<#
.SYNOPSIS 
    Internal function to initialize Apache Tomcat OOTB users.
.DESCRIPTION
    Internal function to configure Apache Tomcat users for controlling 
    access to the Manager application. Passwords are generated anad stored in 
    the secrets directory.
.PARAMETER Path
    Root path of the lab installation.
.EXAMPLE
    Initialize-ApacheTomcatUsers -Path "C:\" 
#>
function Initialize-ApacheTomcatUsers {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
     # Backup originial web.xml file
     Write-Log -Message "Backing up Apache Tomcat tomcat-users.xml..."
     $tomcat_users_xml_path = "$env:CATALINA_BASE\conf\tomcat-users.xml"
     $date = Get-FormattedDate
     $bk_path = $Path + $Directories["backups"] + "tomcat-users-xml.zip"
 
     Compress-Archive -Path $tomcat_users_xml_path -DestinationPath $bk_path | Out-Null
     Write-Log -Message "Apache Tomcat tomcat-users.xml backup completed."
    # The OOTB Tomcat users are defined in conf/tomcat-users.xml
    # Usernames are defined at the top of this script in the TomcatUsers 
    # dictionary.
    #<!--
      #<user username="admin" password="<must-be-changed>" roles="manager-gui"/>
      #<user username="robot" password="<must-be-changed>" roles="manager-script"/>
    #-->

    $manager_id = $TomcatUsers["Manager"]
    $rpa_id = $TomcatUsers["RpaUser"]
    $jmx_id = $TomcatUsers["JmxUser"]

    $manager_pass = New-RandomPassword
    $mgr_pass_filename = $SecretFiles["TomcatManagerFile"]
    Save-RandomPassword -Path $Path -Name $mgr_pass_filename -Secret $manager_pass

    $rpa_pass = New-RandomPassword
    $rpa_pass_filename = $SecretFiles["TomcatRpaFile"]
    Save-RandomPassword -Path $Path -Name $rpa_pass_filename -Secret $rpa_pass

    $jmx_pass = New-RandomPassword
    $jmx_pass_filename = $SecretFiles["TomcatJmxFile"]
    Save-RandomPassword -Path $Path -Name $jmx_pass_filename -Secret $jmx_pass

    # Append the JMX user credentials and role to the standard users
    $match_robot = '<user username="robot".*/>'
    $append_term = "$&`n  <user username=""$jmx_id"" password=""$jmx_pass"" roles=""manager-jmx""/>"
    ((Get-Content -Path $tomcat_users_xml_path -Raw) -Replace $match_robot, $append_term) `
    | Set-Content -Path $tomcat_users_xml_path

    # Initialize the manager-gui role
    $match_admin = '(<user username=")admin" (password=")<must-be-changed>" (roles="manager-gui"/>)'
    ((Get-Content -Path $tomcat_users_xml_path -Raw) -Replace $match_admin, `
    ('$1' + $manager_id + '"' + ' $2' + "$manager_pass" + '"' + ' $3')) `
    | Set-Content -Path $tomcat_users_xml_path

    # Initialize the manager-script role
    $match_robot = '(<user username=")robot" (password=")<must-be-changed>" (roles="manager-script"/>)'
    ((Get-Content -Path $tomcat_users_xml_path -Raw) -Replace $match_robot, `
    ('$1' + $rpa_id + '"' + ' $2' + "$rpa_pass" + '"' + ' $3')) `
    | Set-Content -Path $tomcat_users_xml_path
    
    # Remove xml comment tags
    $match_content = "<!--([\n\s]*?<user username=""$manager_id""[\s\S\n]*?)-->"
    ((Get-Content -Path $tomcat_users_xml_path -Raw) -Replace $match_content, '$1') `
    | Set-Content -Path $tomcat_users_xml_path
} 


<#
.SYNOPSIS 
    Internal function to add the Windows OpenSSH capability. 
.DESCRIPTION
    Internal function to add and configure the Windows OpenSSH capability. 
    Sets the default remote shell to PowerShell 7.5.0.
.PARAMETER Path
    If path is not provided, defaults to "C:\".
.EXAMPLE
    Initialize-OpenSSH -Path "D:\"
#>
function Initialize-OpenSSH {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Configuring OpenSSH..."
    # Configure OpenSSH 
    $filename = "sshd_config"
    $config_path = "$env:ProgramData\ssh\$filename"

    # Backup config file
    $bk_path = $Path + $Directories["backups"]
    $date = Get-FormattedDate
    Compress-Archive -Path $config_path -DestinationPath ($bk_path + "$date-$filename.zip")

    # Update PubkeyAuthentication
    $match_line = '#(PubkeyAuthentication yes)'
    ((Get-Content -Path $config_path -Raw) -Replace $match_line, '$1') | Set-Content -Path $config_path

    # Update PasswordAuthentication
    $match_line = '#(PasswordAuthentication yes)'
    ((Get-Content -Path $config_path -Raw) -Replace $match_line, '$1') | Set-Content -Path $config_path

    # Set PowerShell 7 as Default SSH Shell
    $line_to_match = "Subsystem`tsftp`tsftp-server.exe"
    $pwshell = "$line_to_match`nSubsystem`tpowershell`tc:/progra~1/powershell/7/pwsh.exe`t-sshs`t-NoLogo"
    ((Get-Content -Path $config_path -Raw) -replace $line_to_match, $pwshell) | Set-Content -Path $config_path

    # Confirm firewall rules 
    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        Write-Log -Message "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Log -Message "Firewall rule 'OpenSSH-Server-In-TCP' is existing."
    }

    # Set Default OpenSSH Shell 
    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell `
    -Value "C:\Progra~1\PowerShell\7\pwsh.exe" -PropertyType String -Force

    Write-Log -Message "OpenSSH configured."
}


<#
.SYNOPSIS 
    Internal function to install and configure Active Directory.
.DESCRIPTION
    Install and configure Active Directory based on the parameters defined 
    at the top of this script or the parameters passed in. A random password
    is generated for the `Safe Mode Administrator Password` and save to the 
    the secrets directory.
.PARAMETER Path
    The root installation path, defaults to "C:\"
.PARAMETER ServerName
    Name of the server to install Active Directory Domain Services.
.PARAMETER DomainName
    Name of the Active Directory Domain.
.PARAMETER NetbiosName
    NetBios Name of the Active Directory Domain.
.EXAMPLE
    Install-ActiveDirectory -Path "D:\" -DomainName "aviumlabs.test" 
        -NetbiosName "AVIUMLABS"
    Install-ActiveDirectory -Path "D:\"
#>
function Install-ActiveDirectory {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$DomainName,
        [string]$NetbiosName
    )
    Write-Log -Message "Installing Active Directory Domain Services..."

    # Install Active Directory
    Install-WindowsFeature AD-Domain-Services

    if (-Not $DomainName) {
        $DomainName = $ADDomain["DomainName"] 
    }

    if (-Not $NetbiosName) {
        $NetbiosName = $ADDomain["NetbiosName"]
    }

    Write-Log -Message "Active Domain Services installed."
    Write-Log -Message "Configuring the Active Directory domain $DomainName."
    # Configure Active Directory
    Import-Module ADDSDeployment

    $pass = New-RandomPassword
    # Active Directory password policy requires uppercase, lowercase, numbers, 
    # and special characters
    $pass = $pass + '-+'
    $pass_filename = $SecretFiles["ADSafeModeFile"]
    Save-RandomPassword -Path $Path -Name $pass_filename -Secret $pass

    $pass = ConvertTo-SecureString $pass -AsPlainText -Force 

    # Set these values to your environment
    $ADArguments = @{
        CreateDNSDelegation           = $false
        DatabasePath                  = "C:\Windows\NTDS"
        DomainName                    = $DomainName
        SafeModeAdministratorPassword = $pass
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
    Internal function to install Apache Ant. 
.DESCRIPTION
    Internal function to install Apache Ant. The Apache Ant version to 
    be installed is defined at the top of this script.
.PARAMETER Path
    Root path of the installation, defaults to "C:\".
.EXAMPLE
    Install-ApacheAnt -Path "D:\"
#>
function Install-ApacheAnt {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Apache Ant 1.10.x
    Write-Log -Message "Installing Apache Ant..."
    $pkg = Get-PackageName -Name "apache-ant" -Pkgs $Packages
    if ($Packages[$pkg]['verified']) {
        $apache_ant = [string]$pkg.Split("-bin.zip")
        $apache_ant = $apache_ant.Trim()
        $dl_path = $Path + $Directories["downloads"]
        $installer = $dl_path + $pkg
        $install_path = $Path + $Directories["bin"]
        $ant_bin_path = $install_path + "$apache_ant\bin"
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        # Set session environment variables
        $env:ANT_HOME = "$install_path\$apache_ant"
        $env:PATH = "$env:PATH;$ant_bin_path"

        # Install Ant Contrib
        # Extract and copy file to $env:ANT_HOME\lib: ant-contrib-1.0b3.jar
        $ant_contrib = Get-PackageName -Name "ant-contrib" -Pkgs $Packages
        if ($Packages[$ant_contrib]['verified']) {
            Write-Log -Message "Copy Ant Contrib jar to Apache Ant lib directory."
            $ant_contrib_path = $Path + $Directories['downloads'] + $ant_contrib
            $ant_lib_path = "$env:ANT_HOME\lib"
            Add-Type -Assembly System.IO.Compression.FileSystem
            $zip_file = [IO.Compression.ZipFile]::OpenRead($ant_contrib_path)
            $zip_file.Entries | Where-Object ({$_.Name -like 'ant-contrib-1.0b3.jar'}) | foreach {
                                                $FileName = $_.Name 
                                                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, 
                                                "$ant_lib_path\$FileName", $true)} 
            $zip_file.Dispose()
            Write-Log -Message "Ant Contrib file copy completed."
        } else {
            Write-Log -Message "Ant Contrib not copied, package failed verification."
        }

        Write-Log -Message "Apache Ant installation completed."
    } else {
        Write-Log -Message "Apache Ant not installed, package failed verification."
    }
}


<#
.SYNOPSIS 
    Internal function to install Apache JMeter. 
.DESCRIPTION
    Internal function to install Apache JMeter. The Apache JMeter version to 
    be installed is defined at the top of this script.
.PARAMETER Path
    Root path of the installation, defaults to "C:\".
.EXAMPLE
    Install-ApacheJMeter -Path "D:\"
#>
function Install-ApacheJMeter {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Apache JMeter 5.6.x
    Write-Log -Message "Installing Apache JMeter..."
    $pkg = Get-PackageName -Name "apache-jmeter" -Pkgs $Packages
    if ($Packages[$pkg]['verified']) {
        $apache_jmeter = [string]$pkg.Split(".zip")
        $apache_jmeter = $apache_jmeter.Trim()
        $dl_path = $Path + $Directories["downloads"]
        $installer = $dl_path + $pkg
        $install_path = $Path + $Directories["bin"]
        $apache_jmeter_bin_path = $install_path + "$apache_jmeter\bin"
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        # Set session environment variables
        $env:JMETER_HOME = "$install_path$apache_jmeter"
        $env:PATH = "$env:PATH;$apache_jmeter_bin_path"
        Write-Log -Message "Apache JMeter installation completed."
    } else {
        Write-Log -Message "Apache JMeter not installed, package failed verification."
    }
}


<#
.SYNOPSIS 
    Internal function to install Apache Tomcat. 
.DESCRIPTION
    Internal function to install Apache Tomcat. The Apache Tomcat version to 
    be installed is defined at the top of this script.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Install-ApacheTomcat -Path "D:\"
#>
function Install-ApacheTomcat {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Apache Tomcat 9.0.x
    Write-Log -Message "Installing Apache Tomcat..."
    $pkg = Get-PackageName -Name "apache-tomcat" -Pkgs $Packages
    $server_name = hostname
    $server_name = $server_name.ToLower()
    if ($Packages[$pkg]['verified']) {
        $apache_tomcat = [string]$pkg.Split("-windows-x64.zip")
        $apache_tomcat = $apache_tomcat.Trim()
        $cat_home = $Path + $Directories["bin"] + $apache_tomcat
        $cat_bin = $cat_home + "\bin"
        $cat_base = $Path + $Directories["tomcat"] + "\$server_name$TcInstanceId"
        $install_path = $Path + $Directories["bin"]
        $installer = $Path + $Directories["downloads"] + $pkg
        Expand-Archive -Path $installer $install_path | Out-Null
        # Launch installer
        #.$installer /S /D=$cat_home | Out-Null

        # Install Tomcat Native
        # Extract and copy files to $cat_bin: tcnative-2.dll, openssl.exe
        if (!Assert-TomcatNative) {
            $t_native = Get-PackageName -Name "tomcat-native" -Pkgs $Packages
            if ($Packages[$t_native]['verified']) {
                Write-Log -Message "Copy Tomcat Native files to Apache Tomcat bin directory."
                $tn_path = $Path + $Directories["downloads"] + $t_native
                Add-Type -Assembly System.IO.Compression.FileSystem
                $zip_file = [IO.Compression.ZipFile]::OpenRead($tn_path)
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($zip_file.Entries[1], "$cat_bin\openssl.exe", $true)
                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($zip_file.Entries[4], "$cat_bin\tcnative-2.dll", $true)
                $zip_file.Dispose()
                Write-Log -Message "Tomcat Native file copy completed."
            } else {
                Write-Log -Message "Tomcat Native not copied, package failed verification."
            }
        } else {
            Write-Log -Message "Tomcat Native already installed, skipping copy."
        }

        # Set session environment variables
        $env:CATALINA_HOME = $cat_home
        $env:PATH = "$env:PATH;$cat_bin"
        $env:CATALINA_BASE = $cat_base
        Write-Log -Message "Apache Tomcat installation completed."
    } else {
        Write-Log -Message "Apache Tomcat not installed, package failed verification."
    }
}


<#
.SYNOPSIS 
    Internal function to install OpenJDK.
.DESCRIPTION
    Install OpenJDK 21.x.
.PARAMETER Path
    The root path of the application installation.
.EXAMPLE
    Install-OpenJDK
#>
function Install-OpenJDK {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install OpenJDK 21.x
    Write-Log -Message "Installing OpenJDK..."
    $pkg = Get-PackageName -Name "openjdk" -Pkgs $Packages
    if ($Packages[$pkg]['verified']) {
        $dl_path = $Path + $Directories["downloads"]
        $installer = $dl_path + $pkg
        $install_path = $Path + $Directories["bin"]
        # openjdk-21.0.2_windows-x64_bin.zip
        $res = $pkg -Match '[0-9]{2}.[0-9]{1}.[0-9]{1}'
        $jdk_version = $Matches[0]
        $jdk_bin_path = $install_path + "jdk-$jdk_version\bin"
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        # Set session environment variables
        $env:JAVA_HOME = $install_path + "jdk-$jdk_version"
        $env:PATH = "$jdk_bin_path;$env:PATH"

        Write-Log -Message "OpenJDK installation completed."
    } else {
        Write-Log -Message "OpenJDK not installed, package failed verification."
    }
}


<#
.SYNOPSIS 
    Internal function to install the Windows OpenSSH capability.
.DESCRIPTION
    Install the Windows OpenSSH capability.
.EXAMPLE
    Install-OpenSSH
#>
function Install-OpenSSH {
    Write-Log -Message "Installing and starting OpenSSH..."

    # Install OpenSSH (Windows Server 2022)
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

    # Starting OpenSSH
    Start-Service sshd

    Write-Log -Message "OpenSSH installed and started."
}


function Install-PostgreSQL {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install PostgreSQL 15.x
    $pkg = Get-PackageName -Name "postgresql-15" -Pkgs $Packages
    if ($Packages[$pkg]['verified']) {
        $installer = $Path + $Directories["downloads"] + $pkg
        $bin_path = $Path + $Directories["bin"] + "postgresql\15"
        $data_path = $Path + $Directories["postgresdata"]

        $r_pass = New-RandomPassword
        $pass_filename = $SecretFiles["PostgresFile"]
        Save-RandomPassword -Path $Path -Name $pass_filename -Secret $r_pass

        # Update servername and postgres password in .pgpass file
        $server_name = hostname
        $pgpass_path = "$PSScriptRoot" + "\.pgpass"
        $dest_pgpass_path = $Path + $Directories["secrets"] 
        Copy-Item -Path $pgpass_path -Destination $dest_pgpass_path

        $pgpass_path = $dest_pgpass_path + ".pgpass"

        $match_term = 'devsrv'
        ((Get-Content -Path $pgpass_path -Raw) -Replace $match_term, $server_name) `
        | Set-Content -Path $pgpass_path

        $match_term = '<password>'
        ((Get-Content -Path $pgpass_path -Raw) -Replace $match_term, $r_pass) `
        | Set-Content -Path $pgpass_path

        # Launch installer
        Invoke-Command -ScriptBlock { 
            Write-Progress -Activity "Installing PostgreSQL, long process, be patient...";
            .$installer --mode unattended --prefix $bin_path --datadir $data_path --enable_acledit 1 --superpassword $r_pass
        } | Out-Null

        # Set session environment variables
        $env:PGDATA = $data_path
        $env:PSQL_HOME = $bin_path
        $env:PATH = "$env:PATH;$bin_path"

        # C:\apps\postgresql\15\data\pg_hba.conf

        # Set firwall rule
        New-NetFirewallRule -Name "PostgreSQL Allow" -Enabled True `
        -DisplayName "PostgreSQL TCP 5432 Inbound Allow" -Direction Inbound `
        -Protocol TCP -LocalPort 5432 -RemoteAddress LocalSubnet -Action Allow `
        -Description "PostgreSQL TCP 5432 Inbound Allow" | Out-Null
        Write-Log -Message "PostgreSQL installation completed."
    } else {
        Write-Log -Message "PostgreSQL not installed, package failed verification."
    }
}


function Install-PowerShell {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install PowerShell 7.5.x
    Write-Log -Message "Installing PowerShell..."
    $pkg = Get-PackageName -Name "PowerShell" -Pkgs $BasePackages
    if ($BasePackages[$pkg]['verified']) {
        $pkg_path = $Path + $Directories["downloads"] + $pkg
        $args = "/package $pkg_path /passive ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 ADD_PATH=1 DISABLE_TELEMETRY=1"

        # Launch installer
        Start-Process msiexec.exe -ArgumentList $args -Wait 

        Write-Log -Message "PowerShell installation completed."
    } else {
        Write-Log -Message "PowerShell not installed, package failed verification."
    }
}


function Install-Python {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Python 3.13.x
    Write-Log -Message "Installing Python..."
    $pkg = Get-PackageName -Name "python" -Pkgs $Packages
    if ($Packages[$pkg]['verified']) {
        $installer = $Path + $Directories["downloads"] + $pkg

        # Launch installer
        Invoke-Command -ScriptBlock {   
            Write-Progress -Activity "Installing Python...";
            .$installer /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
        } | Out-Null
        
        if ($?) {
            Write-Log -Message "Python install completed."
        } else {
            Write-Log -Message "Python install failed."
        }
        
    } else {
        Write-Log -Message "Python not installed, package failed verification."
    }
}


function Install-SPackage {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Pkg
    )
    # Install a specific package
    if ($Pkg.Contains("python")) {
        Install-Python -Path $Path
    } elseif ($Pkg.Contains("vscode")) {
        Install-VSCode -Path $Path
    } elseif ($Pkg.Contains("ant")) {
        Install-ApacheAnt -Path $Path
    } elseif ($Pkg.Contains("jmeter")) {
        Install-ApacheJMeter -Path $Path
    } elseif ($Pkg.Contains("tomcat")) {
        Install-ApacheTomcat -Path $Path
    } elseif ($Pkg.Contains("openjdk")) {
        Install-OpenJDK -Path $Path
    } elseif ($Pkg.Contains("openssh")) {
        Install-OpenSSH
    } elseif ($Pkg.Contains("postgresql")) {
        Install-PostgreSQL -Path $Path
    } elseif ($Pkg.Conains("powershell")) {
        Install-PowerShell -Path $Path
    } else {
        Write-Log -Message "Package not recognized: $Pkg"
    }    
}


function Install-VSCode {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Visual Studio Code 1.99.x
    # VSCODE_HOME = 'C:\Program Files\Microsoft VS Code'
    $vscode_bin = "C:\Program Files\Microsoft VS Code\bin\code"
    if (-Not (Test-Path -Path $vscode_bin)) {
        Write-Log -Message "Installing Visual Studio Code..."
        $pkg = Get-PackageName -Name "VSCodeSetup" -Pkgs $Packages          
        if ($Packages[$pkg]['verified']) {
            $installer = $Path + $Directories["downloads"] + $pkg

            # Launch installer
            .$installer /VERYSILENT /MERGETASKS=!runcode

            Write-Log -Message "Visual Studio Code install completed."
        } else {
            Write-Log -Message "Visual Studio Code not installed, package failed verification."
        }
    } else {
        Write-Log -Message "Visual Studio Code already installed, not updating."
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
    Write-Log -Message "Downloading $FileName..."
    $res = Invoke-WebRequest -Uri $Uri -OutFile $FileName -PassThru

    return $res
}


<#
.SYNOPSIS 
    Internal function to create a new AD security group.
.DESCRIPTION
    Internal function to create a new AD security group, by default 
    it creates the Logon As a Service security group. The security 
    group is created in the Groups OU. Defaults to creating the 
    LogonAsService security group.
.PARAMETER Path
    The root installation path. 
.PARAMETER GroupName
    Name of the security group to create.
.PARAMETER Description
    The purpose of the security group. 
.EXAMPLE
    New-ADSecurityGroup -GroupName $GroupName -Description $Description
    New-ADSecurityGroup -GroupName "LogonAsService" -Description "Logon as a service security group"
#>
function New-ADSecurityGroup {
    param (
        [string]$GroupName,
        [string]$Description
    )
    $sec_grp_ou = "OU=" + $ADDomain["GroupOU"] + "," + $ADDomain["RootDN"]
    $display_name = $GroupName
    $GrpParams = @{
        Description = $Description
        DisplayName = $display_name
        GroupCategory = "Security"
        GroupScope = "Global"
        Name = $GroupName
        Path = $sec_grp_ou
        SamAccountName = $GroupName
    }

    Write-Log -Message "Creating new security group $GroupName..."
    New-ADGroup @GrpParams | Out-Null
    if ($?) {
        Write-Log -Message "Security group $GroupName created."
    } else {
        Write-Log -Message "Failed to create security group $GroupName."
    } 
}


<#
.SYNOPSIS 
    Internal function to create a new AD service account.
.DESCRIPTION
    Internal function to create a new AD service account. 
.PARAMETER AccountName
    The SamAccountName of the service account to create.
.PARAMETER AccountPassword
    The `SecureString` password of the service account to create.
.PARAMETER Description
    The purpose of the service account. 
.EXAMPLE
    New-ADServiceAccount -AccountName $AccountName -AccountPassword $AccountPassword -Description $Description
    New-ADServiceAccount -AccountName "svc-httpd" -AccountPassword $AccountPassword -Description "Apache HTTPD service account$?"
#>
function New-ADServiceAccount {
    param (
        [Parameter(Mandatory)]
        [string]$AccountName,
        [Parameter(Mandatory)]
        $AccountPassword,
        [Parameter(Mandatory)]
        [string]$Description
    )
    Import-Module ActiveDirectory
    $sa_ou = "OU=" + $ADDomain["ServiceOU"] + "," + $ADDomain["RootDN"]

    $SvcParams = @{
        AccountPassword = $AccountPassword
        AllowReversiblePasswordEncryption = $false
        CannotChangePassword = $true
        Description = $Description
        Enabled = $true
        Name = $AccountName
        PasswordNeverExpires = $true
        Path = $sa_ou
        SamAccountName = $AccountName
    }
    Write-Log -Message "Adding new service account...$AccountName"
    New-ADUser @SvcParams | Out-Null
    if ($?) {
        Write-Log -Message "New service account...$AccountName, created in $sa_ou."
    } else {
        Write-Log -Message "Failed to create service account - $AccountName in $sa_ou."
    }
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
    #skip the letter l
    $alpha_list = [char]97..[char]109 + [char]111..[char]122 + [char]65..[char]90
    $char_list = $alpha_list + [char]48..[char]57 + [char]43 + [char]45

    # Always start password with alpha character
    $pass = [char](Get-Random -InputObject $alpha_list)
    $pass += -Join ((Get-Random -InputObject $char_list -Count ($PwLength - 1)) | ForEach-Object {[char]$_})
    
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


function Set-ApacheFSPermissions {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Setting Apache Tomcat directories permissions..."
    $owner =  $ADDomain["TomcatUser"]
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($owner, 
    "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")

    $tc_pkg_name = Get-PackageName -Name "apache-tomcat" -Pkgs $Packages
    $tc_pkg_name = $tc_pkg_name.Split("-windows-x64.zip")
    $tc_pkg_name = $tc_pkg_name.Trim()

    $tc_bin_path = $Path + $Directories["bin"] + $tc_pkg_name
    $tc_inst_path = $Path + $Directories["tomcat"]
    
    $acl = Get-Acl -Path $tc_bin_path
    $acl.SetOwner([System.Security.Principal.NTAccount]$owner)
    $acl.AddAccessRule($rule)
    Set-Acl -Path $tc_bin_path -AclObject $acl

    $acl = Get-Acl -Path $tc_inst_path
    $acl.SetOwner([System.Security.Principal.NTAccount]$owner)
    $acl.AddAccessRule($rule)
    Set-Acl -Path $tc_inst_path -AclObject $acl
    
    Write-Log -Message "Completed setting permissions of Apache Tomcat directories."
}


function Set-PermanentEnvVariables {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Setting permanent environment variables..."
    $bin_path = $Path + $Directories["bin"]
    
    # Set Apache Ant permanent environment variables
    $ant_bin_path = "$env:ANT_HOME\bin"
    [Environment]::SetEnvironmentVariable("ANT_HOME", $env:ANT_HOME, "Machine")
    [Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$ant_bin_path", "Machine")

    # Set Apache JMeter permanent environment variables
    [Environment]::SetEnvironmentVariable("JMETER_HOME", $env:JMETER_HOME, "Machine")
    [Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$env:JMETER_HOME\bin", "Machine")

    # Set Apache Tomcat permanent environment variables
    $cat_bin_path = "$env:CATALINA_HOME\bin"
    [Environment]::SetEnvironmentVariable("CATALINA_HOME", $env:CATALINA_HOME, "Machine")
    [Environment]::SetEnvironmentVariable("PATH","$env:PATH;$cat_bin_path", "Machine")
    [Environment]::SetEnvironmentVariable("CATALINA_BASE", $env:CATALINA_BASE, "Machine")

    # Set OpenJDK permanent environment variables
    $jdk_bin_path = "$env:JAVA_HOME\bin"
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $env:JAVA_HOME, "Machine")
    [Environment]::SetEnvironmentVariable("PATH", "$jdk_bin_path;$env:PATH", "Machine")

    # Set PostgreSQL permanent environment variables
    $psql_home = $bin_path + "postgresql\15"
    $psql_bin_path = $bin_path + "postgresql\15\bin"
    [Environment]::SetEnvironmentVariable("PGDATA", $env:PGDATA, "Machine")
    [Environment]::SetEnvironmentVariable("PSQL_HOME", $psql_home, "Machine")
    [Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$psql_bin_path", "Machine")

    # Set Tomcat Instance permanent environment variable
    [Environment]::SetEnvironmentVariable("TC_INSTANCE", $env:TC_INSTANCE, "Machine")

    Write-Log -Message "Permanent environment variables set."
}