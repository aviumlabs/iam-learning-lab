# Aviumlabs-Cutils.psm1
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

$LogFile = "$env:USERPROFILE\Documents\aviumlabs-iam-lab-install.log"

# Import common data sets
Import-Module $PSScriptRoot\Aviumlabs-Cds.psm1

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
        Write-Log -Message "Exception...$exception_name"
        Write-Error $Error[0]
    }
}


<#
.SYNOPSIS 
    Internal function to determine if an Apache Tomcat service is running.
.DESCRIPTION
    Internal function to determine if an Apache Tomcat service is running.
.PARAMETER InstanceId
    The identifier of a specific Tomcat instance, defaults to $TcInstanceId.
    $TcInstanceId is defined in the Aviumlabs-Cds.psm1 script.
.EXAMPLE
    Assert-TomcatIsRunning -InstanceId "-b"
#>
function Assert-TomcatIsRunning {
    param (
        [string]$InstanceId = $TcInstanceId
    )
    $svc_name = Get-TomcatServiceName -InstanceId $InstanceId
    $apache_svc = Get-Service $svc_name
    if ($apache_svc.Status -eq "Running") {
        return $true
    }

    return $false
}


<#
.SYNOPSIS 
    Internal function to get an encoded URL.
.DESCRIPTION
    Internal function to get an encoded URL.
.PARAMETER Url
    The URL to be encoded
.EXAMPLE
    ConvertTo-EncodedUrl -Url $Url
    ConvertTo-EncodedUrl -Url "https://example.com/who?id=xyz"
#>
function ConvertTo-EncodedUrl {
    param (
        [Parameter(Mandatory)]
        [string]$Url
    )
    $uri = New-Object System.Uri($Url)
    return $uri.AbsoluteUri
}


<#
.SYNOPSIS 
    Internal function to get a formatted date.
.DESCRIPTION
    Internal function to get a formatted date.
.PARAMETER Format
    The format of the date, defaults to "yyyyMMddHHmm"
.EXAMPLE
    Get-FormattedDate
    Get-FormattedDate -Format "yyyyMMdd"
#>
function Get-FormattedDate {
    param (
        [string]$Format = "yyyyMMddHHmm"
    )
    return Get-Date -Format $Format
}


<#
.SYNOPSIS 
    Internal function to retrieve the package filename.
.DESCRIPTION
    Internal function to retrieve the package filename from Packages dictionary,
    package dictionaries are defined at the top of this script.
.PARAMETER Name
    Name of the package to lookup.
.PARAMETER Pkgs
    The packages dictionary containing the package to be looked up.
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
    ForEach ($pkg in $Pkgs.Keys) {
        if ( $($pkg) -Match $Name ) {
            return $($pkg)
        }
    }
}


<#
.SYNOPSIS 
    Internal function to get a PSCredential.
.DESCRIPTION
    Internal function to get a PSCredential.
.PARAMETER Secret
    The password of the account.
.PARAMETER Username
    The username of the account.
.EXAMPLE
    Get-PSCredential -Secret $Secret -Username $Username
#>
function Get-PSCredential {
    param (
        [Parameter(Mandatory)]
        [string]$Secret,
        [Parameter(Mandatory)]
        [string]$Username
    )
    $s_pass = ConvertTo-SecureString $Secret -AsPlainText -Force
    $credential_params = @{
        TypeName = 'System.Management.Automation.PSCredential'
        ArgumentList = $Username, $s_pass
    }

    return New-Object @credential_params
}


<#
.SYNOPSIS 
    Internal function to get a secret generated during the packages install.
.DESCRIPTION
    Internal function to get a secret generated during the packages install. 
    If the secret is not found in the secrets path an exception is thrown.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Get-Secret -Path "C:\" -SecretFile $SecretFile
#>
function Get-Secret {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$SecretFile
    )
    $secret_path = $Path + $Directories["secrets"] + $SecretFile
    if (Test-Path -Path $secret_path) {
        return Get-Content -Path $secret_path
    } else {
        Throw [System.IO.FileNotFoundException]"Secret not found."
    }
}


<#
.SYNOPSIS 
    Internal function to get the Apache Tomcat instance name.
.DESCRIPTION
    Internal function to get the Apache Tomcat instance name.
.PARAMETER InstanceId
    The specific instance ID of the Tomcat instance, defaults to $TcInstanceId.
    $TcInstanceId is defined in the Aviumlabs-Cds.psm1 script.
.EXAMPLE
    Get-TomcatInstanceName
    Get-TomcatInstanceName -InstanceId "-b"
#>
function Get-TomcatInstanceName {
    param (
        [string]$InstanceId = $TcInstanceId
    )
    $inst_name = hostname
    $inst_name = $inst_name.ToLower()
    $inst_name += $InstanceId

    return $inst_name
}


<#
.SYNOPSIS 
    Internal function to get the Apache Tomcat service name.
.DESCRIPTION
    Internal function to get the Apache Tomcat service name.
.PARAMETER InstanceId
    The specific instance ID of the Tomcat instance, defaults to $TcInstanceId.
    $TcInstanceId is defined in the Aviumlabs-Cds.psm1 script.
.EXAMPLE
    Get-TomcatServiceName
    Get-TomcatServiceName -InstanceId "-b"
#>
function Get-TomcatServiceName {
    param (
        [string]$InstanceId = $TcInstanceId
    )
    $svc_name = "apache-"
    $svc_name += hostname
    $svc_name = $svc_name.ToLower()
    $svc_name += $InstanceId

    return $svc_name
}


<#
.SYNOPSIS 
    Internal function to start Apache Tomcat instance.
.DESCRIPTION
    Internal function to start Apache Tomcat instance.
.PARAMETER InstanceId
    The identifier of a specific Tomcat instance, defaults to $TcInstanceId.
    $TcInstanceId is defined in the Aviumlabs-Cds.psm1 script.
.EXAMPLE
    Start-ApacheTomcat
    Start-ApacheTomcat -InstanceId "-b"
#>
function Start-ApacheTomcat {
    param (
        [string]$InstanceId = $TcInstanceId
    )
    $svc_name = Get-TomcatServiceName -InstanceId $InstanceId
    Write-Log -Message "Starting Apache Tomcat instance..."
    tomcat9 //ES/$svc_name | Out-Null

    if ($?) {
        Write-Log -Message "Apache Tomcat instance started successfully."
    } else {
        Write-Log -Message "Failed to start Apache Tomcat instance."
    }
}


<#
.SYNOPSIS 
    Internal function to stop Apache Tomcat instance.
.DESCRIPTION
    Internal function to stop Apache Tomcat instance.
.PARAMETER InstanceId
    The identifier of a specific Tomcat instance, defaults to $TcInstanceId.
    $TcInstanceId is defined in the Aviumlabs-Cds.psm1 script.
.EXAMPLE
    Stop-ApacheTomcat
    Stop-ApacheTomcat -InstanceId "-b"
#>
function Stop-ApacheTomcat {
    param (
        [string]$InstanceId = $TcInstanceId
    )
    $svc_name = Get-TomcatServiceName -InstanceId $InstanceId
    Write-Log -Message "Stopping Apache Tomcat instance..."
    tomcat9 //SS/$svc_name | Out-Null

    if ($?) {
        Write-Log -Message "Apache Tomcat instance stopped successfully."
    } else {
        Write-Log -Message "Failed to stop Apache Tomcat instance."
    }
}


<#
.SYNOPSIS 
    Internal function to remove a directory.
.DESCRIPTION
    Internal function to remove a directory.
.PARAMETER Path
    The path of the directory to be removed.
    If the directory does not exist, a message is logged.
.EXAMPLE
    Remove-Directory -Path "$env:CATALINA_BASE\webapps\identityiq"
#>
function Remove-Directory {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    if (Test-Path -Path $Path) {
        Write-Log -Message "Removing directory...$Path"
        Remove-Item -Path $Path -Recurse -Force
    } else {
        Write-Log -Message "Directory does not exist...$Path"
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