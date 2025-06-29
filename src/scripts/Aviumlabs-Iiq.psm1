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
    Function to build IdentityIQ extract.
.DESCRIPTION
    Function to build IdentityIQ extract.
    The Path parameter must be the same path as used when installing
    packages.
.PARAMETER Path
    Root path of the lab install, defaults to "C:\"
.EXAMPLE
    Build-IdentityIq
#>
function Build-IdentityIq {

    Initialize-IiqExtract
}


<#
.SYNOPSIS 
    Function to re-deploy IdentityIQ.
.DESCRIPTION
    Function to re-deploy IdentityIQ.
    The Path parameter must be the same path as used when installing
    packages.
.PARAMETER Path
    Root path of the lab install, defaults to "C:\"
.EXAMPLE
    Deploy-IdentityIq
    Deploy-IdentityIq -Path "D:\"
#>
function Deploy-IdentityIq {
    param (
        [string]$Path = "C:\"
    )
    Write-Log -Message "Confirming the operating system is supported by this module."
    Assert-Environment

    Write-Log -Message "Building and deploying IdentityIQ..."
    Initialize-IiqWar
    Backup-IiqWar -Path $Path -WarPath $IiqWarPath
    Uninstall-IdentityIq -Path $Path
    New-IiqDeployment -Path $Path
    Initialize-Iiq -Path $Path -InitFileName "sp.init-custom.xml"
    Confirm-IiqIsRunning -Path $Path
}


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
    Backup-IiqWar -Path $Path -WarPath $IiqWarPath
    Initialize-IiqDatabase -Path $Path
    New-IiqDeployment -Path $Path
    Initialize-Iiq -Path $Path
    Confirm-IiqIsRunning -Path $Path
    Add-IiqSymlinks -Path $Path
}


<#
.SYNOPSIS 
    Function to install IdentityIQ extended schema.
.DESCRIPTION
    Function to install IdentityIQ extended schema.
    The Path parameter must be the same path as used when installing
    packages.
.PARAMETER Path
    Root path of the lab install, defaults to "C:\"
.EXAMPLE
    Install-IiqExtendedSchema
    Install-IiqExtendedSchema -Path "D:\"
#>
function Install-IiqExtendedSchema {
    param (
        [string]$Path = "C:\"
    )

    $iiq_wi_path = "$env:CATALINA_BASE\webapps\identityiq\WEB-INF"
    $env:CLASSPATH = "$iiq_wi_path\classes;$iiq_wi_path\lib\identityiq.jar"

    $iiq_bat = "$iiq_wi_path\bin\iiq.bat"

    Write-Log -Message "Adding extended attributes..."
    .$iiq_bat extendedSchema 

    Write-Log -Message "Backing up IdentityIQ databases..."
    Backup-IiqDbs -Path $Path
    # add_identityiq_extensions.postgresql
    # location: $env:CATALINA_BASE\webapps\identityiq\WEB-INF\database\add_identityiq_extensions.postgresql
    $extend_iiq_db_path = "$iiq_wi_path\database\add_identityiq_extensions.postgresql"
    $postgres_url = Get-PostgresUrl -Path $Path -Schema "identityiq"
    Initialize-DatabaseTables -Url $postgres_url -FilePath $extend_iiq_db_path
}


<#
.SYNOPSIS 
    Function to undeploy IdentityIQ.
.DESCRIPTION
    Function to undeploy IdentityIQ. 
    The Path parameter must be the same path as used when installing
    IdentityIQ.
.PARAMETER Path
    Root path of the lab install, defaults to "C:\"
.EXAMPLE
    Uninstall-IdentityIq
    Uninstall-IdentityIq -Path "D:\"
#>
function Uninstall-IdentityIq {
    param (
        [string]$Path = "C:\"
    )
    Write-Log -Message "Confirming the operating system is supported by this module."
    Assert-Environment

    Backup-IiqDbs -Path $Path

    Stop-IdentityIq -Path $Path

    # https://{host}:{port}/manager/text/undeploy?path=/identityiq
    $tomcat_url = Get-TomcatBaseUrl
    $tomcat_url += "undeploy?path=/identityiq"
    $TomcatUrl = ConvertTo-EncodedUrl -Url $tomcat_url 
    $Cred = Get-TomcatCredential -Path $Path

    Invoke-Command -ScriptBlock { 
        Write-Progress -Activity "Undeploying IdentityIQ...";
        $res = Invoke-WebRequest -SkipCertificateCheck -Uri $TomcatUrl `
            -Authentication Basic -Credential $Cred
    } | Out-Null

    if ($?) {
        Write-Log -Message "IdentityIQ web application undeployed successfully."
        if (Test-Path -Path "$env:CATALINA_BASE\webapps\identityiq") {
            Stop-ApacheTomcat
            Remove-Directory -Path "$env:CATALINA_BASE\webapps\identityiq"
            if (Test-Path -Path "$env:CATAlINA_BASE\webapps\identityiq.war") {
                Remove-Item -Path "$env:CATALINA_BASE\webapps\identityiq.war" -Force
            }
            Start-ApacheTomcat
        }
    } else {
        Write-Log -Message "Failed to undeploy IdentityIQ web application."
    }
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
    Internal function to backup IdentityIQ databases.
.DESCRIPTION
    Internal function to backup IdentityIQ databases.
    The Path parameter must be the same path as used when installing
    packages.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Backup-IiqDbs -Path "C:\"
#>
function Backup-IiqDbs {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Backup and date databases identityiq, identityiqPlugin, identityiqah
    $date = Get-FormattedDate
    $iiq_bk_path = $Path + $Directories["backups"] + "$date-iiqdb.pg_dump"
    $iiqplug_bk_path = $Path + $Directories["backups"] + "$date-iiqplugindb.pg_dump"
    $iiqah_bk_path = $Path + $Directories["backups"] + "$date-iiqahdb.pg_dump"

    Write-Log -Message "Backup IdentityIQ databases..."
    # TODO: user and password file for pg_dump
    # Set pgpassfile environment variable, required for automating export
    $pgpass_path = $Path + $Directories["secrets"] + ".pgpass"
    $env:PGPASSFILE = $pgpass_path
    pg_dump --host devsrv --port 5432 --dbname identityiq --username identityiq > $iiq_bk_path | Out-Null
    pg_dump --host devsrv --port 5432 --dbname identityiqPlugin --username identityiqPlugin > $iiqplug_bk_path | Out-Null
    pg_dump --host devsrv --port 5432 --dbname identityiqah --username identityiqah > $iiqah_bk_path | Out-Null

    Write-Log -Message "IdentityIQ databases backup completed."
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
    Backup-IiqWar -Path "C:\" -WarPath $WarPath
#>
function Backup-IiqWar {
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
        Start-IdentityIq -Path $Path
    } else {
        Write-Log -Message "IdentityIQ is already running."
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
        $response = Invoke-WebRequest -SkipCertificateCheck -Uri $TomcatUrl `
            -Authentication Basic -Credential $Cred
    } | Out-Null

    if ($response) {
        Write-Log -Message "Response status code...$($response.StatusCode)"
        Write-Log -Message "Response content...$($response.Content)"
    } else {
        Write-Log -Message "Response is null, deployment may have failed."
    }
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
    ForEach ($line in $Response) {
        if ($line -Match $match_running) {
            return $true
        }
    }

    return $false
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
        [string]$Path,
        [string]$Schema = "postgres"
    )
    Write-Log -Message "Getting PostgreSQL connection URL..."
    try {
        $db_pass = Get-Secret -Path $Path -SecretFile $SecretFiles["PostgresFile"]
        $server_name = hostname
        $server_name = $server_name.ToLower()
        return "postgresql://postgres:$db_pass@$server_name" + ":5432/$Schema"
    } catch {
        $exception_name = $Error[0].Exception.GetType().FullName
        Write-Log -Message "Exception...$exception_name"
        Write-Error $Error[0]
        Exit 1
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
        return Get-PSCredential -Secret $rpa_pass -Username $rpa_user
    } catch {
        $exception_name = $Error[0].Exception.GetType().FullName
        Write-Log -Message "Exception...$exception_name"
        Write-Error $Error[0]
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
    # Set pgpassfile environment variable, required for automating import
    $pgpass_path = $Path + $Directories["secrets"] + ".pgpass"
    $env:PGPASSFILE = $pgpass_path
    Invoke-Command -ScriptBlock {
        Write-Progress -Activity "Loading database tables...";
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
        [string]$Path,
        [string]$InitFileName = "init.xml"
    )
    $iiq_wi_path = "$env:CATALINA_BASE\webapps\identityiq\WEB-INF"
    $env:CLASSPATH = "$iiq_wi_path\classes;$iiq_wi_path\lib\identityiq.jar"

    # IdentityIQ initialization files to be imported
    # init.xml includes init-lcm, init-ai, init-cam, init-pam, and sp.init-custom
    $iiq_xml_path = "$iiq_wi_path\config\$InitFileName"

    # Create the file for automating import
    $bk_path = $Path + $Directories["backups"]
    $import_inits_path = "$bk_path\import-inits.txt"

    if (-Not (Test-Path -Path $import_inits_path)) {
        Add-Content -Path $import_inits_path -Value $iiq_xml_path
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
    Set-Location $SsbHome
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
        Write-Progress -Activity "Building IdentityIQ extract...";
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
    
    Set-Location "$env:USERPROFILE"
}


<#
.SYNOPSIS 
    Internal function to perform a new deployment of IdentityIQ.
.DESCRIPTION
    Internal function to perform a new deployment of IdentityIQ.
.PARAMETER Path
    Root path of the lab install.
.PARAMETER InstanceId
    The identifier of a specific Tomcat instance, defaults to $TcInstanceId.
    $TcInstanceId is defined in the Aviumlabs-Cds.psm1 script.
.EXAMPLE
    New-IiqDeployment -Path "C:\" -InstanceId "-b"
#>
function New-IiqDeployment {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$InstanceId = $TcInstanceId
    )
    # General command syntax
    # http://{host}:{port}/manager/text/{command}?{parameters}
    $tomcat_url = Get-TomcatBaseUrl
    $tomcat_url += "deploy?path=/identityiq&war=file:$IiqWarPath"
    $enc_tc_url = ConvertTo-EncodedUrl -Url $tomcat_url

    # Ensure Tomcat is running    
    if (Assert-TomcatIsRunning -InstanceId $InstanceId) {
        Write-Log -Message "Apache Tomcat is running, proceeding with deployment."
    } else {
        Write-Log -Message "Apache Tomcat is not running, starting it now..."
        Start-ApacheTomcat -InstanceId $InstanceId
    }

    $cred = Get-TomcatCredential -Path $Path
    Deploy-Iiq -TomcatUrl $enc_tc_url -Cred $cred
}


<#
.SYNOPSIS 
    Internal function to start the IdentityIQ instance.
.DESCRIPTION
    Internal function to start the IdentityIQ instance.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Start-IdentityIq -Path "C:\"
#>
function Start-IdentityIq {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    $Cred = Get-TomcatCredential -Path $Path
    # Start a web application
    # http://{host}:{port}/manager/text/start?path=/examples
    $tomcat_url = Get-TomcatBaseUrl
    $tomcat_url += "start?path=/identityiq"
    $TomcatUrl = ConvertTo-EncodedUrl -Url $tomcat_url 
    Invoke-Command -ScriptBlock { 
        Write-Progress -Activity "Starting IdentityIQ...";
        $response = Invoke-WebRequest -SkipCertificateCheck -Uri $TomcatUrl `
            -Authentication Basic -Credential $Cred
    } | Out-Null
    
    if ($response) {
        Write-Log -Message "Response status code...$($response.StatusCode)"
        Write-Log -Message "Response content...$($response.Content)"
    } else {
        Write-Log -Message "Response is null, IdentityIQ may not be running."
    }
}


<#
.SYNOPSIS 
    Internal function to stop the Apache Tomcat IdentityIQ instance.
.DESCRIPTION
    Internal function to stop the Apache Tomcat IdentityIQ instance.
.PARAMETER Path
    Root path of the lab install.
.EXAMPLE
    Stop-IdentityIq -Path "C:\"
#>
function Stop-IdentityIq {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    # https://{host}:{port}/manager/text/stop?path=/identityiq
    $tomcat_url = Get-TomcatBaseUrl
    $tomcat_url += "stop?path=/identityiq"
    $TomcatUrl = ConvertTo-EncodedUrl -Url $tomcat_url
    $Cred = Get-TomcatCredential -Path $Path
    if (Assert-IiqIsRunning -Path $Path) {
        Invoke-Command -ScriptBlock { 
            Write-Progress -Activity "Stopping IdentityIQ...";
            $response = Invoke-WebRequest -SkipCertificateCheck -Uri $TomcatUrl `
                -Authentication Basic -Credential $Cred
        }

        if ($response) {
            Write-Log -Message "Response status code...$($response.StatusCode)"
            Write-Log -Message "Response content...$($response.Content)"
        } else {
            Write-Log -Message "Response is null, IdentityIQ may not be stopped."
        }
    } 
    else {
        Write-Log -Message "IdentityIQ is not running, nothing to stop."
    }
}