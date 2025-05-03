# Aviumlabs-Iiq.psm1
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

# IdentityIQ Build Environment
$env:SPTARGET = "sandbox"

# Standard Services Build directory
$abs_path = Resolve-Path "$PSScriptRoot\..\ssb"
$SsbHome = $abs_path.Path

# IdentityIQ Web Archive Path
$IiqWarPath = "$SsbHome\build\deploy\identityiq.war"

# Import common utilitiy functions
Import-Module $PSScriptRoot\Aviumlabs-Cutils.psm1

# Import common data sets functions
Import-Module $PSScriptRoot\Aviumlabs-Cds.psm1

# =============================================================================
# Public API
# =============================================================================
<#
.SYNOPSIS 
    Function to get the current timeout and sessions for IdentityIQ.
.DESCRIPTION
    Function to get the current timeout and sessions for IdentityIQ. 
    The Path parameter must be the same path as used when installing
    packages.
.PARAMETER Path
    Root path of the lab install, defaults to "C:\"
.EXAMPLE
    Get-IdentityIqSessions
    Get-IdentityIqSessions -Path "D:\"
#>
function Get-IdentityIqSessions {
    param (
        [string]$Path = "C:\"
    )
    # https://{host}:{port}/manager/text/sessions?path=/identityiq
    $tomcat_url = Get-TomcatBaseUrl
    $tomcat_url += "sessions?path=/identityiq"

    $TomcatUrl = ConvertTo-EncodedUrl -Url $tomcat_url 
    $Cred = Get-TomcatCredential -Path $Path
    Invoke-WebRequest -SkipCertificateCheck -Uri $TomcatUrl `
               -Authentication Basic -Credential $Cred
}


<#
.SYNOPSIS 
    Function to run an initial IdentityIQ deployment.
.DESCRIPTION
    Function to run an initial IdentityIQ deployment. 
    The Path parameter must be the same path as used when installing
    packages.
.PARAMETER Path
    Root path of the lab install, defaults to "C:\"
.EXAMPLE
    Install-IdentityIq
    Install-IdentityIq -Path "D:\"
#>
function Install-IdentityIq {
    param (
        [string]$Path = "C:\"
    )
    Write-Log -Message "Confirming the operating system is supported by this module."
    Assert-Environment

    Write-Log -Message "Building, deploying, and initializing IdentityIQ..."
    Initialize-IiqWar
    Backup-IdentityIQWar -Path $Path -WarPath $IiqWarPath
    Initialize-IiqDatabase -Path $Path
    New-IiqDeployment -Path $Path
    Initialize-Iiq -Path $Path
    Confirm-IiqIsRunning -Path $Path
    Add-IiqSymlinks -Path $Path
}


# =============================================================================
# Internal API
# =============================================================================
<#
.SYNOPSIS 
    Internal function to create IdentityIQ symlinks on the Desktop.
.DESCRIPTION
    Internal function to create IdentityIQ symlinks on the Desktop.
    The Path parameter must be the same path as used when installing
    packages.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Add-IiqSymlinks -Path "C:\"
#>
function Add-IiqSymlinks {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Adding IdentityIQ symlinks to the Desktop..."
    $desktop_path = $Path + "Users\$env:USERNAME\Desktop\"
    $desktop_logs_path = $desktop_path + "logs"
    $desktop_conf_path = $desktop_path + "conf"
    $desktop_iiq_path = $desktop_path + "identityiq"

    $iiq_logs_path = "$env:CATALINA_BASE\logs"
    $iiq_conf_path = "$env:CATALINA_BASE\conf"
    $iiq_iiq_path = "$env:CATALINA_BASE\webapps\identityiq"

    # destination source
    cmd /c mklink /D $desktop_logs_path $iiq_logs_path
    cmd /c mklink /D $desktop_conf_path $iiq_conf_path
    cmd /c mklink /D $desktop_iiq_path $iiq_iiq_path
    Write-Log -Message "IdentityIQ symlinks added to the Desktop."
}


<#
.SYNOPSIS 
    Internal function to determine if IdentityIQ is running.
.DESCRIPTION
    Internal function to determine if IdentityIQ is running.
    The Path parameter must be the same path as used when installing
    packages.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Assert-IiqIsRunning -Path "C:\"
#>
function Assert-IiqIsRunning {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    $response = Get-TomcatWebapps -Path $Path
    return Get-IiqStatus -Response $response
}


<#
.SYNOPSIS 
    Internal function to backup and write sha256 of the IdentityIQ war.
.DESCRIPTION
    Internal function to backup and write sha256 of the IdentityIQ war.
.PARAMETER Path
    Root path of the lab install.
.PARAMETER WarPath
    The path to the web archive to be backed up.
.EXAMPLE
    New-IiqDeployment
#>
function Backup-IdentityIQWar {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$WarPath
    )
    Write-Log -Message "Archiving IdentityIQ war..."

    # Backup and date build
    $date = Get-FormattedDate
    $war_zip = "identityiq.zip"
    $zip_bk_path = $Path + $Directories["backups"] + "$date-$war_zip"

    Compress-Archive -Path $WarPath -DestinationPath $zip_bk_path | Out-Null

    $zip_hash = Get-FileHash -Path $zip_bk_path -Algorithm "SHA256"
    $sha_content = $zip_hash.Hash + " $date-$war_zip"
    $sha_path = $zip_bk_path + ".sha256"
    Set-Content -Path $sha_path -Value $sha_content
    Write-Log -Message "IdentityIQ war archived  to $zip_bk_path."
}


<#
.SYNOPSIS 
    Internal function to confirm IdentityIQ is running.
.DESCRIPTION
    Internal function to confirm IdentityIQ is running and if 
    not to start it.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Confirm-IiqIsRunning -Path "C:\"
#>
function Confirm-IiqIsRunning {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Ensuring IdentityIQ is ruuning..."
    if (-Not (Assert-IiqIsRunning -Path $Path)) {
        # Start a web application
        # http://{host}:{port}/manager/text/start?path=/examples
        $tomcat_url = Get-TomcatBaseUrl
        $tomcat_url += "start?path=/identityiq"
        $TomcatUrl = ConvertTo-EncodedUrl -Url $tomcat_url 
        $Cred = Get-TomcatCredential -Path $Path
        $response = Invoke-WebRequest -SkipCertificateCheck -Uri $TomcatUrl `
               -Authentication Basic -Credential $Cred
        
        Write-Log -Message "IdentityIQ web application status..."
        Write-Log -Message $repsonse
    } else {
        Write-Log -Message "IdentityIQ is running."
    }
}


<#
.SYNOPSIS 
    Internal function to deploy IdentityIQ web archive (war).
.DESCRIPTION
    Internal function to deploy IdentityIQ to Apache Tomcat.
.PARAMETER TomcatUrl
    The Apache Tomcat text URL for deploying webapps.
.PARAMETER Cred
    The credential for connecting to Apache Tomcat.
.EXAMPLE
    Deploy-Iiq -TomcatUrl $TomcatUrl -Cred $Cred
#>
function Deploy-Iiq {
    param (
        [Parameter(Mandatory)]
        [System.Uri]$TomcatUrl,
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Cred
    )
    Write-Log -Message "Deploying IdentityIQ web archive..."
    Invoke-Command -ScriptBlock {
        Write-Progress -Activity "Deploying IdentityIQ web archive...";
        $res = Invoke-WebRequest -SkipCertificateCheck -Uri $TomcatUrl `
               -Authentication Basic -Credential $Cred
    } | Out-Null

    Write-Log -Message "IdentityIQ Tomcat deployment status...$res"
}


function Get-IiqStatus {
    param (
        [Parameter(Mandatory)]
        $Response
    )
    #OK - Listed applications for virtual host [devsrv]
    #/identityiq:running:2:identityiq
    #/manager:running:0:C:/bin/apache-tomcat-9.0.104/webapps/manager
    $match_running = '/identityiq:running:.*'
    Write-Host "Tomcat webapps`n"
    $status = $false
    ForEach ($line in $Response) {
        if ($line -Match $match_running) {
            $status = $true
        }
    }

    return $status
}


<#
.SYNOPSIS 
    Internal function to get the PostgreSQL credential embedded in a 
    PostgreSQL URL.
.DESCRIPTION
    Internal function to get the PostgreSQL credential embedded in a 
    PostgreSQL URL. 
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Get-PostgresUrl -Path "C:\"
#>
function Get-PostgresUrl {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Getting PostgreSQL connection URL..."
    try {
        $db_pass = Get-Secret -Path $Path -SecretFile $SecretFiles["PostgresFile"]
        $server_name = hostname
        $server_name = $server_name.ToLower()
        return "postgresql://postgres:$db_pass@$server_name" + ":5432/postgres"
    } catch {
        $exception_name = $Error[0].Exception.GetType().FullName
        Write-Log -Message "Exception...$exception_name"
        Write-Error $Error[0]
        Exit 1
    } 
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
    Internal function to get the Tomcat `text` URL.
.DESCRIPTION
    Internal function to get the Tomcat `text` URL.
.EXAMPLE
    Get-TomcatBaseUrl
#>
function Get-TomcatBaseUrl {
    $server_name = hostname
    $server_name = $server_name.ToLower()
    $tomcat_url = "https://$server_name"
    $tomcat_url += ":8443/manager/text/"

    return $tomcat_url
}


<#
.SYNOPSIS 
    Internal function to get the Apache Tomcat rpa credential.
.DESCRIPTION
    Internal function to get the Apache Tomcat rpa credential.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Get-TomcatCredential -Path "C:\" 
#>
function Get-TomcatCredential {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    try {
        $rpa_pass = Get-Secret -Path $Path -SecretFile $SecretFiles["TomcatRpaFile"]
        $rpa_user = $TomcatUsers["RpaUser"]
        return Get-PSCredential -Secret $rpa_pass -Username $TomcatUsers["RpaUser"]
    } catch {
        $exception_name = $Error[0].Exception.GetType().FullName
        Write-Log -Message "Exception...$exception_name"
        Write-Error $Error[0]
        Exit 1
    } 
}


<#
.SYNOPSIS 
    Internal function to get the list of currently deployed 
    applications on Tomcat.
.DESCRIPTION
    Internal function to get the list of currently deployed 
    applications on Tomcat.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Get-TomcatWebapps -Path "C:\"
#>
function Get-TomcatWebapps {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # List currently deployed applications
    # http://{host}:{port}/manager/text/list
    $tomcat_url = Get-TomcatBaseUrl
    $tomcat_url += "list"

    $TomcatUrl = ConvertTo-EncodedUrl -Url $tomcat_url 
    $Cred = Get-TomcatCredential -Path $Path
    $response = Invoke-WebRequest -SkipCertificateCheck -Uri $TomcatUrl `
               -Authentication Basic -Credential $Cred
    return $response
}


<#
.SYNOPSIS 
    Internal function to load database tables from a PostgreSQL sql 
    script.
.DESCRIPTION
    Internal function to load database tables from a PostgreSQL sql 
    script.
.PARAMETER Url
    The PostgreSQL connection URL with embedded credentials.
.PARAMETER Path
    The path of the PostgreSQL sql script.
.EXAMPLE
    Initialize-DatabaseTables -Url $Url -FilePath $FilePath
#>
function Initialize-DatabaseTables {
    param (
        [Parameter(Mandatory)]
        [string]$Url,
        [Parameter(Mandatory)]
        [string]$FilePath
    )
    Write-Log -Message "Loading database tables..."
    Invoke-Command -ScriptBlock {
        Write-Progress -Activity "Loading database tables..."
        psql -f $FilePath $Url | Out-Null
    }
    Write-Log -Message "Database tables loaded."
}


<#
.SYNOPSIS 
    Internal function to import the IdentityIQ initialization files.
.DESCRIPTION
    Internal function to import the IdentityIQ initialization files.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Initialize-Iiq -Path "C:\"
#>
function Initialize-Iiq {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    $iiq_wi_path = "$env:CATALINA_BASE\webapps\identityiq\WEB-INF"
    $env:CLASSPATH = "$iiq_wi_path\classes;$iiq_wi_path\lib\identityiq.jar"

    # IdentityIQ initialization files to be imported
    $iiq_xml_path = "$iiq_wi_path\config\init.xml"
    $iiq_lcm_path = "$iiq_wi_path\config\init-lcm.xml"
    $iiq_ai_path = "$iiq_wi_path\config\init-ai.xml"
    $iiq_cam_path = "$iiq_wi_path\config\init-cam.xml"
    $iiq_pam_path = "$iiq_wi_path\config\init-pam.xml"

    # Create the file for automating import
    $bk_path = $Path + $Directories["backups"]
    $import_inits_path = "$bk_path\import-inits.txt"

    if (-Not (Test-Path -Path $import_inits_path)) {
        Add-Content -Path $import_inits_path -Value $iiq_xml_path
        Add-Content -Path $import_inits_path -Value $iiq_lcm_path
        Add-Content -Path $import_inits_path -Value $iiq_ai_path
        Add-Content -Path $import_inits_path -Value $iiq_cam_path
        Add-Content -Path $import_inits_path -Value $iiq_pam_path
    }

    $iiq_bat = "$iiq_wi_path\bin\iiq.bat"

    if (Test-Path -Path $iiq_bat) {
        Write-Log -Message "Initializing IdentityIQ services..."
        .$iiq_bat console -f $import_inits_path | Out-Null

        if ($?) {
            Write-Log -Message "IdentityIQ services initialization completed."
        } else {
            Write-Log -Message "IdentityIQ services initialization failed."
        } 
    } else {
        Write-Log -Message "IdentityIQ web application not found."
    }
    
}


<#
.SYNOPSIS 
    Internal function to load IdentityIQ tables.
.DESCRIPTION
    Internal function to load IdentityIQ tables.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Initialize-IiqDatabase -Path "C:\"
#>
function Initialize-IiqDatabase {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    Write-Log -Message "Initializing IdentityIQ databases..."
    $postgres_url = Get-PostgresUrl -Path $Path
    # $SsbHome is defined at the top of this script
    $db_path = "$SsbHome\build\extract\WEB-INF\database"
    $create_iiq_db_path = "$db_path\create_identityiq_tables-8.4.postgresql"
    $update_iiq_db_path = "$db_path\upgrade_identityiq_tables-8.4p2.postgresql"

    # Set pgpassfile environment variable, required for automating import
    $pgpass_path = $Path + $Directories["secrets"] + ".pgpass"
    $env:PGPASSFILE = $pgpass_path

    Initialize-DatabaseTables -Url $postgres_url -FilePath $create_iiq_db_path
    if ($?) {
        Write-Log -Message  "IdentityIQ databases initialization completed."
    } else {
        Write-Log -Message  "IdentityIQ databases initialization failed."
    }

    Initialize-DatabaseTables -Url $postgres_url -FilePath $update_iiq_db_path
    if ($?) {
        Write-Log -Message  "IdentityIQ databases upgrade completed."
    } else {
        Write-Log -Message  "IdentityIQ databases upgrade failed."
    }
}


<#
.SYNOPSIS 
    Internal function to build an IdentityIQ extract.
.DESCRIPTION
    Internal function to build an IdentityIQ extract. Building an extract
    can be a long running processes (i.e., 30 minutes).
.EXAMPLE
    Initialize-IiqExtract 
#>
function Initialize-IiqExtract {
    $build = "$SsbHome\build.bat"
    # Run build clean prior to running build extract if build extract is 
    # already existing
    if (Test-Path -Path "$SsbHome\build\extract") {
        Invoke-Command -ScriptBlock { 
            Write-Progress -Activity "Running build clean...";
            .$build clean 
        } | Out-Null
    }
    
    # Build the IdentityIQ extract
    Invoke-Command -ScriptBlock { 
        Write-Progress -Activity "Building IdentityIQ extract..."
        .$build 
    } | Out-Null
}


<#
.SYNOPSIS 
    Internal function to build an IdentityIQ web archive (war).
.DESCRIPTION
    Internal function to build an IdentityIQ web archive (war).
.EXAMPLE
    Initialize-IiqWar
#>
function Initialize-IiqWar {
    $build = "$SsbHome\build.bat"
    Set-Location $SsbHome
    Write-Log -Message "Building IdentityIQ war, this is a long running process, be patient..."
    # Run build clean prior to running build war if build extract is 
    # already existing
    if (Test-Path -Path "$SsbHome\build\extract") {
        Invoke-Command -ScriptBlock { 
            Write-Progress -Activity "Running build clean...";
            .$build clean 
        } | Out-Null
    }    
    
    # Build the IdentityIQ war
    Invoke-Command -ScriptBlock { 
        Write-Progress -Activity "Building IdentityIQ web archive...";
        .$build war
    } | Out-Null

    if ($?) {
        Write-Log -Message "IdentityIQ war build completed."
    } else {
        Write-Log -Message "IdentityIQ war build failed."
    }
    
    Set-Location "C:\Users\$env:USERNAME"
}


<#
.SYNOPSIS 
    Internal function to perform a new deployment of IdentityIQ.
.DESCRIPTION
    Internal function to perform a new deployment of IdentityIQ.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    New-IiqDeployment -Path "C:\"
#>
function New-IiqDeployment {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # General command syntax
    # http://{host}:{port}/manager/text/{command}?{parameters}
    $tomcat_url = Get-TomcatBaseUrl
    $tomcat_url += "deploy?path=/identityiq&war=file:$IiqWarPath"
    $enc_tc_url = ConvertTo-EncodedUrl -Url $tomcat_url

    # Ensure Tomcat is running    
    $svc_name = "apache-$env:TC_INSTANCE"
    $iiq_svc = Get-Service $svc_name
    if (-Not ($iiq_svc.Status -eq "Running")) {
        tomcat9 //ES//$svc_name | Out-Null
    }

    $cred = Get-TomcatCredential -Path $Path
    Deploy-Iiq -TomcatUrl $enc_tc_url -Cred $cred
}