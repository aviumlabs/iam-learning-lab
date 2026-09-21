# Aviumlabs-Deptools.psm1
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

$LogFile = "$env:USERPROFILE\Documents\deptools.log"

# =============================================================================
# Public API
# =============================================================================
<#
.SYNOPSIS 
    Install the Development Tools specified at the top of this file.
.DESCRIPTION
    Install the Development Tools specified at the top of this file; 
    administrator permissions not required.
.PARAMETER Path
    If path is not provided, defaults to $env:USERPROFILE.
.EXAMPLE
    Install-DevTools
#>
function Install-DevTools {
    param (
        [string]$Path = $env:USERPROFILE
    )

    Assert-Environment

    Write-Log -Message @"
    The following development tools will be downloaded and installed
    under the user's context and does not require administrator permissions.
"@
    ForEach ($key in $Packages.Keys) {
        Write-Log -Message "`t$($key)"
    }
    Write-Log -Message @"
    The development tools will be installed in $Path\Apps\bin.`n
    Environment variables will be set for each of the tools and 
    the PATH environment variable will be updated.`n
"@

    Add-Directories -Path $Path
    Get-Packages -Path $Path

    Install-Brave -Path $Path
    Install-PowerShell -Path $Path 
    Install-PortableGit -Path $Path
    Install-GitHubCLI -Path $Path
    Install-OpenJDK -Path $Path
    Install-ApacheJMeter -Path $Path
    Install-ApacheAnt -Path $Path
    Install-ApacheMaven -Path $Path
    Install-Python -Path $Path
    Install-VSCode -Path $Path
}


function Uninstall-DevTools {
    param (
        [string]$Path = $env:USERPROFILE
    )
    Write-Log -Message "Uninstalling DevTools..."
    # Remove Environment Variables
    Remove-Item Env:GIT_HOME
    Remove-Item Env:PWSHELL_HOME

    Uninstall-VisualStudioCode -Path $Path

    # Delete bin and Downloads Directories
    $bin_path =  $Path + $Directories["bin"]
    $dl_path = $Path + $Directories["downloads"]
    Remove-Directory -Path $bin_path
    Remove-Directory -Path $dl_path
    Write-Log -Message "DevTools uninstall completed."
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
    Add-Directories
#>
function Add-Directories {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Creating DevTools directories..."
    Add-Directory -Path $Path -Name $Directories["backups"]
    Add-Directory -Path $Path -Name $Directories["bin"]
    Add-Directory -Path $Path -Name $Directories["downloads"] 
    Write-Log -Message "DevTools directories setup completed."

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
    Add-Directory -Name "$env:USERPROFILE\directory"
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
                Write-Log -Message "Operating system supported."
            } else {
                Throw "Operating system not supported."
            }
        }
    } catch {
        $exception_name = $Error[0].Exception.GetType().FullName
        Write-Log -Message "Exception name...$exception_name"
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
.PARAMETER Alg
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


function Get-FormattedDate {
    param (
        [string]$Format = "yyyyMMddHHmm"
    )
    return Get-Date -Format $Format
}


<#
.SYNOPSIS 
    Internal function to retrieve the full filename.
.DESCRIPTION
    Internal function to retrieve the full filename from DevTools dictionary.
.PARAMETER Name
    Name of the tool to lookup.
.EXAMPLE
    Get-PackageName -Name "PowerShell"
#>
function Get-PackageName {
    param (
        [Parameter(Mandatory)]
        [string]$Name
    )
    ForEach ($key in $Packages.Keys) {
        if ( $($key) -Match $Name ) {
            return $($key)
        }
    }
}


<#
.SYNOPSIS 
    Internal function to download a specific package.
.DESCRIPTION
    Internal function to download and verify a specific package.
.PARAMETER Path
    Root path of the DevTools install.
.PARAMETER Pkg
    The package to download.
.EXAMPLE
    Get-Package -Path $env:USERPROFILE -Pkg $Pkg
#>
function Get-Package {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Pkg
    )
    $dl_path = $Path + $Directories["downloads"]
    Set-Location -Path $dl_path

    $download = @{
        FileName = $Pkg
        Uri = $($Packages[$Pkg]['endpoint'])
    }

    $res = Invoke-Download @download

    if ($res) {
        Write-Log -Message "$Pkg download completed."
        Write-Log -Message "Verifying $Pkg integrity..."
        $pkg_path = $dl_path + $Pkg
        $pkg_sha = $($Packages[$Pkg]['vhash'])
        $pkg_alg = $($Packages[$Pkg]['halg'])
        $ast = Assert-Integrity -PkgPath $pkg_path -Hash $pkg_sha -Alg $pkg_alg

        if ($ast) {
            $Packages[$Pkg]['verified'] = $true
            Write-Log -Message "$Pkg integrity verified."
        } else {
            Write-Log -Message "$Pkg integrity verification failed."
            Write-Log -Message "Re-attempting download..."
            Get-Package -Path $Path -Pkg $Pkg
        }
    } else {
        Write-Log -Message "$Pkg download failed."
        Write-Log -Message "Re-attempting download..."
        Get-Package -Path $Path -Pkg $Pkg
    }
}


<#
.SYNOPSIS 
    Internal function to download the set of packages defined at the top of 
    this script.
.DESCRIPTION
    Internal function to download the set of packages defined at the top of 
    this script.
.PARAMETER Path
    Root path of the DevTools install.
.EXAMPLE
    Get-Packages -Path $env:USERPROFILE
#>
function Get-Packages {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    ForEach ($pkg in $Packages.Keys) {
        Get-Package -Path $Path -Pkg $pkg
    }

    Set-Location -Path $Path
}


function Install-ApacheAnt {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Apache Ant 1.10.x
    Write-Log -Message "Installing Apache Ant..."
    $pkg = Get-PackageName -Name "apache-ant"
    if ($Packages[$pkg]['verified']) {
        $apache_ant = $pkg -Split("-bin.zip")
        $apache_ant = $apache_ant.Trim()
        $installer = $Path + $Directories["downloads"] + $pkg
        $install_path = $Path + $Directories["bin"]
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        $env:ANT_HOME = "$install_path$apache_ant"
        # Set permanent User environment variables
        [Environment]::SetEnvironmentVariable("ANT_HOME", $env:ANT_HOME , "User")
        [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:ANT_HOME\bin", "User")
        Write-Log -Message "Apache Ant install completed."
    } else {
        Write-Log -Message "Apache Ant not installed, package failed integrity verification."
    }
}


function Install-ApacheJMeter {
   param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Apache JMeter 5.6.x
    Write-Log -Message "Installing Apache JMeter..."
    $pkg = Get-PackageName -Name "apache-jmeter"
    if ($Packages[$pkg]['verified']) {
        $apache_jmeter = $pkg -Split(".zip")
        $apache_jmeter = $apache_jmeter.Trim()
        $installer = $Path + $Directories["downloads"] + $pkg
        $install_path = $Path + $Directories["bin"]
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        $env:JMETER_HOME = "$install_path$apache_jmeter"
        # Set permanent User environment variables
        [Environment]::SetEnvironmentVariable("JMETER_HOME", $env:JMETER_HOME , "User")
        [Environment]::SetEnvironmentVariable("JMETER_BIN", "$env:JMETER_HOME\bin\" , "User")
        [Environment]::SetEnvironmentVariable("PATH",$env:PATH + ";$env:JMETER_HOME\bin", "User")
        Write-Log -Message "Apache JMeter install completed."
    } else {
        Write-Log -Message "Apache JMeter not installed, package failed integrity verification."
    }
}


function Install-ApacheMaven {
   param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Apache Maven 3.9.x
    Write-Log -Message "Installing Apache Maven..."
    $pkg = Get-PackageName -Name "apache-maven"
    if ($Packages[$pkg]['verified']) {
        $apache_maven = $pkg -Split("-bin.zip")
        $apache_maven = $apache_maven.Trim()
        $installer = $Path + $Directories["downloads"] + $pkg
        $install_path = $Path + $Directories["bin"]
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        $env:MVN_HOME = "$install_path$apache_maven"
        # Set permanent User environment variables
        [Environment]::SetEnvironmentVariable("MVN_HOME", $env:MVN_HOME , "User")
        [Environment]::SetEnvironmentVariable("PATH",$env:PATH + ";$env:MVN_HOME\bin", "User")
        Write-Log -Message "Apache Maven install completed."
    } else {
        Write-Log -Message "Apache Maven not installed, package failed integrity verification."
    }
}


function Install-Brave {
   param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Brave Browser 1.78.x
    # brave-v1.78.102-win32-x64.zip
    Write-Log -Message "Installing Brave Browser..."
    $pkg = Get-PackageName -Name "brave"
    if ($Packages[$pkg]['verified']) {
        $apache_jmeter = $pkg -Split(".zip")
        $apache_jmeter = $apache_jmeter.Trim()
        $installer = $Path + $Directories["downloads"] + $pkg
        $install_path = $Path + $Directories["bin"] + "brave"
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        $env:BRAVE_HOME = $install_path
        # Set permanent User environment variables
        [Environment]::SetEnvironmentVariable("BRAVE_HOME", $env:BRAVE_HOME , "User")
        [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:BRAVE_HOME", "User")
        Write-Log -Message "Brave Browser install completed."
    } else {
        Write-Log -Message "Brave Browser not installed, package failed integrity verification."
    }
}


function Install-GitHubCLI {
   param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install GitHub Command Line Interface
    Write-Log -Message "Installing GitHub CLI..."
    $pkg = Get-PackageName -Name "gh"
    if ($Packages[$pkg]['verified']) {
        $gh_parts = $pkg -Split("_")
        $gh_version = $gh_parts[1]
        $installer = $Path + $Directories["downloads"] + $pkg
        $install_path = $Path + $Directories["bin"] + "gh-$gh_version"
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        $env:GH_HOME=$install_path
        # Set permanent User environment variables
        [Environment]::SetEnvironmentVariable("GH_HOME", $env:GH_HOME, "User")
        [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:GH_HOME\bin", "User")

        Write-Log -Message "GitHub CLI install completed."
    } else {
        Write-Log -Message "GitHub CLI not installed, package failed integrity verification."
    }
}

function Install-OpenJDK {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install OpenJDK 21.0.2
    Write-Log -Message "Installing OpenJDK...`n"
    $pkg = Get-PackageName -Name "openjdk"
    if ($Packages[$pkg]['verified']) {
        $installer = $Path + $Directories["downloads"] + $pkg
        $install_path = $Path + $Directories["bin"]
        $res = $pkg -Match '[0-9]{2}.[0-9]{1}.[0-9]{1}'
        if ($res) {
            $jdk_version = $Matches[0]
            $jdk_path = $install_path + "jdk-$jdk_version"
            # Launch installer
            Expand-Archive -Path $installer $install_path | Out-Null

            $env:JAVA_HOME = $jdk_path
            # Set permanent User environment variables
            [Environment]::SetEnvironmentVariable("JAVA_HOME", $env:JAVA_HOME, "User")
            [Environment]::SetEnvironmentVariable("PATH", "$env:JAVA_HOME\bin;" + $env:PATH, "User")

            Write-Log -Message "OpenJDK install completed."
        } else {
            Write-Log -Message "OpenJDK install failed, unable to identify OpenJDK version."
        }
    } else {
        Write-Log -Message "OpenJDK not installed, package failed integrity verification."
    }
}


function Install-PortableGit {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install PortableGit 2.47.x
    Write-Log "Installing PortableGit..."
    $pkg = Get-PackageName -Name "PortableGit"
    if ($Packages[$pkg]['verified']) {
        $git_parts = $pkg -Split "-"
        $git_version = $git_parts[1]
        $git_version = $git_version.Trim()
        $installer = $Path + $Directories["Downloads"] + $pkg
        $install_path = $Path + $Directories["bin"] + "git-$git_version"
        # Launch installer 
        .$installer -o"$install_path" -y | Out-Null

        $env:GIT_HOME = $install_path
        # Set permanent User environment variables
        [Environment]::SetEnvironmentVariable("GIT_HOME", $env:GIT_HOME, "User")
        [Environment]::SetEnvironmentVariable("GIT_ADDONS", "$env:GIT_HOME\usr\bin", "User")
        [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:GIT_HOME\bin", "User")
        Write-Log -Message "PortableGit install completed."
    } else {
        Write-Log -Message "PortableGit not installed, package failed integrity verification."
    }
}


function Install-PostgreSQL {

    # Set session variables
    $env:POSTGRES_HOME = "$env:USERPROFILE\Apps\bin\postgresql\15"
    $env:PGDATA = "$env:USERPROFILE\Apps\data\postgresql\15\data"

    # Set permanent User environment variables
    [Environment]::SetEnvironmentVariable("POSTGRES_HOME", $env:POSTGRES_HOME , "User")
    [Environment]::SetEnvironmentVariable("PGDATA", $env:PGDATA , "User")
    [Environment]::SetEnvironmentVariable("PATH", "$env:PATH;$env:POSTGRES_HOME\bin", "User")

    # Initialize PostgreSQL:  
    initdb -D $env:PGDATA -U postgres
}


function Install-PowerShell {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install PowerShell 7.5.x
    Write-Log -Message "Installing PowerShell..."
    $pkg = Get-PackageName -Name "PowerShell"
    if ($Packages[$pkg]['verified']) {
        $installer = $Path + $Directories["downloads"] + $pkg
        $install_path = $Path + $Directories["bin"] + "powershell-7.5.1"
        # Launch installer
        Expand-Archive -Path $installer $install_path | Out-Null

        $env:PWSHELL_HOME = $install_path
        # Set permanent User environment variables
        [Environment]::SetEnvironmentVariable("PWSHELL_HOME", $env:PWSHELL_HOME, "User")
        [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:PWSHELL_HOME", "User")

        # Create PowerShell profile and set default working directory to Development
        $local_profile = $install_path + "\Microsoft.PowerShell_profile.ps1"
        New-Item -Path $local_profile -Type File -Force
        $development_path = $Path + $Directories["development"]
        $location = "Set-Location $development_path"
        Add-Content -Path $local_profile $location
        Write-Log -Message "PowerShell install completed."
    } else {
        Write-Log -Message "PowerShell not installed, package failed integrity verification."
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
            .$installer /quiet Include_test=0
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


function Install-VSCode {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Install Visual Studio Code 1.x
    # VSCODE_HOME = 'C:\Program Files\Microsoft VS Code'
    $vscode_bin = "C:\Program Files\Microsoft VS Code"
    if (-Not(Test-Path -Path $vscode_bin)) {
        Write-Log -Message "Installing Visual Studio Code..."
        $pkg = Get-PackageName -Name "VSCodeUserSetup"
        if ($Packages[$pkg]['verified']) {
            $installer = $Path + $Directories["downloads"] + $pkg
            $install_path = $Path + $Directories["bin"] + "vscode"
            # Launch installer
            .$installer /SP- /SILENT /NORESTART /DIR="$install_path" | Out-Null

            $env:VSCODE_HOME = $install_path
            # Set permanent User environment variables
            [Environment]::SetEnvironmentVariable("VSCODE_HOME", $env:VSCODE_HOME, "User")
            [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";$env:VSCODE_HOME", "User")
            Write-Log -Message "Visual Studio Code installation completed."
        } else {
            Write-Log -Message "Visual Studio Code not installed, package failed integrity verification."
        }
    } else {
        Write-Log -Message "Visual Studio Code already installed, not updating."
    }
}


<#
.SYNOPSIS 
    Download the specified file.
.DESCRIPTION
    Download the file in the Uri to the file specified in FileName.
.PARAMETER FileName
    The name of the file to be saved. 
.PARAMETER Uri
    The uniform resource indicator of the file to be downloaded.
.EXAMPLE
    Invoke-Download -FileName "test.zip" -Uri "https://test.com/downloads/test.zip"
#>
function Invoke-Download {
    param (
        [Parameter(Mandatory)]
        [string]$FileName,
        [Parameter(Mandatory)]
        [string]$Uri
    )
    Write-Log -Message "Downloading $FileName..."
    if (!(Test-Path -Path $FileName)) {
        $res = Invoke-WebRequest -Uri $Uri -OutFile $FileName -PassThru
    } else {
        $res = $true
        Write-Log -Message "Package is existing."
    }
    
    return $res
}


<#
.SYNOPSIS 
    Internal function to remove the specified directory.
.DESCRIPTION
    Internal function to recursively remove the specified directory 
    without confirmation. If the path is not provided, $env:USERPROFILE 
    is assumed. 
.PARAMETER Path
    Full directory path.
.EXAMPLE
    Remove-Directory -Path $env:USERPROFILE\Apps\bin
#>
function Remove-Directory {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if ( Test-Path -Path $Path ) {
        Remove-Item -Path $Path -Recurse -Force
    }
}


function Uninstall-VisualStudioCode {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # Uninstall Visual Studio Code 1.x
    $uninstaller = $Path + $Directories["bin"] + "\vscode\unins000.exe"
    
    # Launch uninstaller
    if ( Test-Path -Path $uninstaller ) {
        .$uninstaller /SILENT | Out-Null
        Write-Log -Message "Visual Studio Code uninstall completed."
    } else {
        Write-Log -Message "Visual Studio Code uninstall not found."
    }
}


<#
.SYNOPSIS
    Internal function to write a message to the log file defined 
    at the top of this script and to standard out.
.DESCRIPTION
    Internal function to write a message to the log file defined 
    at the top of this script and to standard out.
.PARAMETER Message
    The message to be written to the log and to standard out.
.EXAMPLE
    Write-Log -Message $Message
    Write-Log -Message "Please capture this message in the log file."
#>
function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )
    $date = Get-FormattedDate
    $server = hostname 
    $entry = "$date - $server - $Message"
    $entry | Add-Content -Path $LogFile
    Write-Host "$entry`n"
}