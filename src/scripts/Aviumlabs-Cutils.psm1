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

$LogFile = "C:\Users\$env:USERNAME\Documents\aviumlabs-iam-lab-install.log"

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
        [string]$Format
    )
    if (-Not $Format) {
        $Format = "yyyyMMddHHmm"
    }
    return $date = Get-Date -Format $Format
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
    foreach ($pkg in $Pkgs.Keys) {
        if ( $($pkg) -Match $Name ) {
            $filename = $($pkg)
        }
    }

    return $filename
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