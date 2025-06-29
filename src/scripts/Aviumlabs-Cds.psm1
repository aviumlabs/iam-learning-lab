# Aviumlabs-Cds.psm1
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

# Tomcat Instance ID
$TcInstanceId = "-a"

# Base Packages
$BasePackages = [ordered]@{
    "PowerShell-7.5.1-win-x64.msi" = @{ 
        endpoint = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.1/PowerShell-7.5.1-win-x64.msi";
        halg = "SHA256";
        vhash = "B110ECCAF55BB53AE5E6B6DE478587ED8203570B0BDA9BD374A0998E24D4033A";
        verified = $false;
    }
}

# Packages 
$Packages = [ordered]@{
    "ant-contrib-1.0b3-bin.zip" = @{
        endpoint = "$PSScriptRoot\Packages\ant-contrib-1.0b3-bin.zip";
        halg = "MD5";
        vhash = "c5a75fc28cbc52f09bd43b5506978601";
        verified = $false;
    }
    "apache-ant-1.10.15-bin.zip" = @{
        endpoint = "https://dlcdn.apache.org/ant/binaries/apache-ant-1.10.15-bin.zip";
        halg = "SHA512";
        vhash = "1de7facbc9874fa4e5a2f045d5c659f64e0b89318c1dbc8acc6aae4595c4ffaf90a7b1ffb57f958dd08d6e086d3fff07aa90e50c77342a0aa5c9b4c36bff03a9";
        verified = $false;
    }
    "apache-jmeter-5.6.3.zip" = @{
        endpoint = "https://dlcdn.apache.org/jmeter/binaries/apache-jmeter-5.6.3.zip";
        halg = "SHA512";
        vhash = "387fadca903ee0aa30e3f2115fdfedb3898b102e6b9fe7cc3942703094bd2e65b235df2b0c6d0d3248e74c9a7950a36e42625fd74425368342c12e40b0163076";
        verified = $false;
    }
    "apache-tomcat-9.0.106-windows-x64.zip" = @{
        endpoint = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.106/bin/apache-tomcat-9.0.106-windows-x64.zip";
        halg = "SHA512";
        vhash = "57454fd2244526cb728d29c63d1a75679fd809cabdb38cfb62eedf19806c51888f1e6c7feaa4710a9d788493d0f26752fbd5836acb39161a3bfe07441be82ad2";
        verified = $false;
    }
    "openjdk-21.0.2_windows-x64_bin.zip" = @{
        endpoint = "https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_windows-x64_bin.zip";
        halg = "SHA256";
        vhash = "b6c17e747ae78cdd6de4d7532b3164b277daee97c007d3eaa2b39cca99882664";
        verified = $false;
    }
    "postgresql-15.12-1-windows-x64.exe" = @{
        endpoint = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1259414";
        halg = "SHA256";
        vhash = "2dfa43460950c1aecda05f40a9262a66bc06db960445ea78921c78f84377b148";
        verified = $false;
    }
    "python-3.13.3-amd64.exe" = @{
        endpoint = "https://www.python.org/ftp/python/3.13.3/python-3.13.3-amd64.exe";
        halg = "SHA256";
        vhash = "698f2df46e1a3dd92f393458eea77bd94ef5ff21f0d5bf5cf676f3d28a9b4b6c";
        verified = $false;
    }
    "sqlite-dll-win-x64-3500100.zip" = @{
        endpoint = "https://www.sqlite.org/2025/sqlite-dll-win-x64-3500100.zip";
        halg = "SHA256";
        vhash = "2bf2afb9a6b94dffcc033f37ebdc50118d0ea9e5536729421efa8fb4eb2a5c5f";
        verified = $false;
    }
    "sqlite-tools-win-x64-3500100.zip" = @{
        endpoint = "https://www.sqlite.org/2025/sqlite-tools-win-x64-3500100.zip";
        halg = "SHA256";
        vhash = "a9b26ca6e415f61ada511a14fb2166c9278de3b471702281dd02f3ce97288cfa";
        verified = $false;
    }
    "tomcat-native-2.0.8-openssl-3.0.14-win32-bin.zip" = @{
        endpoint = "https://dlcdn.apache.org/tomcat/tomcat-connectors/native/2.0.8/binaries/tomcat-native-2.0.8-openssl-3.0.14-win32-bin.zip";
        halg = "SHA512";
        vhash = "a4a8816668f14a7461711e25cb9277534981936c9e6f8b00ae55084cb265dc1d89ad07fa508ae2e1f7832236dafafbdd9d76a313c87f34e00ecfdfe75776638a";
        verified = $false;
    }
    "VSCodeSetup-x64-1.100.2.exe" = @{ 
        endpoint = "https://update.code.visualstudio.com/1.100.2/win32-x64/stable";
        halg = "SHA256"
        vhash = "8249a4a4a9e73f34b6f4f4d51481d1a7d547c2c55560e45482d7d8b23017c646";
        verified = $false;
    }
}

# Lab Directories
$Directories = [ordered]@{
    "artifacts" = "apps\backups\artifacts"
    "bin" = "bin\";
    "backups" = "apps\backups\";
    "downloads" = "apps\downloads\";
    "iiqkeys" = "apps\secrets\iiqkeys\";
    "secrets" = "apps\secrets\";
    "tomcat" = "apps\tomcat";
    "postgresdata" = "apps\postgresql\15\data"
}

# Lab secrets
$SecretFiles = [ordered]@{
    "ADSafeModeFile" = ".secret_iiqad_svc_pass";
    "KeyStoreFile" = ".secret_keystore";
    "TomcatSvcFile" = ".secret_tomcat_svc_pass";
    "TomcatManagerFile" = ".secret_tomcat_manager_pass";
    "TomcatRpaFile" = ".secret_tomcat_rpa_pass";
    "TomcatJmxFile" = ".secret_tomcat_jmx_pass";
    "PostgresFile" = ".secret_psql";
}

# Update these variables to preferred Apache Tomcat usernames 
# Leave *Pass blank, passwords will be generated by the script and copied to 
# the secrets directory.
$TomcatUsers = [ordered]@{
    "Manager" = "manager";
    "ManagerPass" = "";
    "RpaUser" = "rpa-tomcat";
    "RpaPass" = "";
    "JmxUser" = "jmx-tomcat";
    "JmxPass" = "";
}

New-Variable -Name Directories -Value $Directories -Scope Local -Force
New-Variable -Name BasePackages -Value $BasePackages -Scope Local -Force
New-Variable -Name Packages -Value $Packages -Scope Local -Force
New-Variable -Name SecretFiles -Value $SecretFiles -Scope Local -Force
New-Variable -Name TomcatUsers -Value $TomcatUsers -Scope Local -Force
New-Variable -Name TcInstanceId -Value $TcInstanceId -Scope Local -Force

Export-ModuleMember -Variable Directories, BasePackages, Packages, SecretFiles, TomcatUsers, TcInstanceId