Aviumlabs IAM Learning Lab Install Guide (c) by Michael Konrad

Aviumlabas IAM Learning Lab Install Guide is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


# Aviumlabs IAM Learning Lab Install Guide

After completing the `Aviumlabs VirtualBox VM` install, run the 
Aviumlabs-Packages module `Install-Packages` function to install and 
configure the stack for running `Aviumlabs IAM Learning Lab`.


## Aviumlabs IAM Learning Lab Install

Login to the devsrv and run the following commands in PowerShell 7.

The Shared Folder is typically mounted on the Z: drive in the Windows  
VirtualBox VM.  
 
```PowerShell
cd `z:\path\to\iam-lab-windows\src\scripts`
```

Import the `Aviumlabs-Packages` module:  
```PowerShell
Import-Module .\Aviumlabs-Packages.psm1
```

`Install-Packages` downloads, installs, and configures these packages 
for the `Aviumlabs IAM Learning Lab`.  

__OpenJDK 21, Apache Tomcat 9, PostgreSQL 15__ 

```PowerShell
Install-Packages
```

At the end of the packages installation, the system will be fully configured 
and ready for the deployment of IdentityIQ. 

The following Windows services are installed and set to start automatically:
* IdentityIQ - an Apache Tomcat 9 instance
* postgresql-x64-15 - the PostgreSQL database server

The Apache Tomcat manager application is available at 
https://devsrv:8443/manager.

The installation configures three Apache Tomcat users for the manager 
application:
| Username    | Role   | Purpose |
| :--- | :--- | :--- |
| manager | manager-gui | Logon to web application |
| rpa-tomcat | manager-script | Script, automate deployments |
| jmx-tomcat | manager-jmx | Java Management Interface, see documentation |

The passwords for these accounts are randomly generated and written to the 
`\apps\secrets` directory:
* .secret_tomcat_manager_pass
* .secret_tomcat_rpa_pass
* .secret_tomcat_jmx_pass

The password for the `postgres` account is written to:
* .secret_psql


## Build, Deploy, and Initialize IdentityIQ

The Aviumlabs-Iiq.psm1 module automates the deployment of IdentityIQ.  
There is additional information about the `IdentityIQ Build` in the 
[IdentityIQ Build Information](#iiq-build-info) section. This module is 
dependent on the packages installed in the previous step and must be 
installed against the same root drive path. I.e., if you specified a 
different drive letter above, specify that same driver letter here.

This is a long running process at least on my hardware:
* MacBook Pro : 2.4 GHz Quad-Core Intel Core i5

```PowerShell
cd `z:\path\to\iam-lab-windows\src\scripts`
```

Import the Aviumlabs-Iiq module:  
  
```PowerShell
Import-Module .\Aviumlabs-Iiq.psm1
```

```PowerShell
Install-IdentityIQ
```

After the deployment has completed open `https://<server_name>:8443/identityiq.`

Login with the standard administrator account `spadmin`



<a name="iiq-build-info" />
## IdentityIQ Build Information

The iiq-lab-windows project uses the SailPoint `Standard Services Build` (ssb) 
for building an IdentityIQ deloyment.

Standard services build (ssb) uses Apache Ant for building an IdentityIQ 
deployment. There are several files that are used to control the build of 
IdentityIQ.

The build.properties file is the central control of the build process. 
There are several values that are required to be set prior to running a 
build.

__Required Properties__
| Property | Purpose |
| :--- | :--- | 
| IIQVersion= | Sets the version of IdentityIQ to be deployed i.e. 8.4 |
| IIQPatchLevel= | Sets the patch version of IdentityIQ |

The following optional properties are useful in the deployment of IdentityIQ.
These properties are based on the individual components licensed. Setting these 
properties to true includes these components in the deployment. 

__Optional Properties__
| Property | Purpose |
| :--- | :--- |
| usingLcm= | Lifecyle Manager |
| usingRapidSetup= | RapidSetup |
| usingPAM= | Privilege Access Manager |
| usingFAM= | File Access Manager |
| usingCAM= | Cloud Access Manager |
| usingAI=  | AI Services |

Additional properties are available to enable automatic database creation, 
automcatic deployment of IdentityIQ to the application server, etc.

The required and optional properties described above have been preset in 
for this lab. 

The build process supports various outputs including a basic build where 
the IdentityIQ files are extracted to the `build\extract` directory.

```PowerShell
# Set build environment
$env:SPTARGET = "sandbox"

# Run the build command
.\build
```

On a new install there are a couple of prerequisites to be 
completed, prior to deployment.

The database needs to be configured and this is done with 
the `create_identityiq_tables-8.4.postgresql` sql script.

The script is located in the `build\extract\database` directory.
