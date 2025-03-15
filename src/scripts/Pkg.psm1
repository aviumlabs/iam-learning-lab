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
.PARAMETER FileName
    The name of the file to be verified. 
.PARAMETER Hash
    The verification secure hash.
.PARAMETER Algorithm
    The secure hash algorithm to use for verification.
.EXAMPLE
    Assert-Integrity -FilePath "test.zip" -Hash "ab3ed4..." -Algorithm SHA256
#>
function Assert-Integrity {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath,
        [Parameter(Mandatory)]
        [string]$Hash,
        [Parameter(Mandatory)]
        [string]$Algorithm
    )

    $dlhash = Get-FileHash -Path $FilePath -Algorithm $Algorithm

    return $dlhash.Hash -eq $Hash
}


<#
.SYNOPSIS 
    Internal function to verify the integrity of a download.
.DESCRIPTION
    Internal function to verify the integrity of a download.
.PARAMETER Path
    Root path.
.PARAMETER Name 
    Name of the dependency to be verified.
.PARAMETER Sha 
    SHA algorithm to be used for verification
.EXAMPLE
    Assert-Package -Path "\" -Name "PowerShell" -Sha "SHA256"
    Assert-Package -Path "\" -Name "apache" -Sha "SHA512"
#>
function Assert-Package {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Sha
    )
    $app_path = $Path + $Directories["downloads"] + $Name

    $vfhash = Get-PackageSHA -Name $Name

    return Assert-Integrity -FilePath $app_path -Hash $vfhash -Algorithm $Sha
}