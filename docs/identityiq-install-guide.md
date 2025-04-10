VirtualBox VM IdentityIQ Installation Guide (c) by Michael Konrad

VirtualBox VM IdentityIQ Installation Guide is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


# VirtualBox VM IdentityIQ Install Guide

After completing the VirtualBox Windows Server installation, run the 
Packages module Install-Packages cmdlet to install and configure the 
stack for running IdentityIQ.


## IdentityIQ Stack Install

Login to the devsrv and run the following commands in PowerShell 7.

>  
> The Shared Folder is typically mounted on the Z: drive in the Windows  
> VirtualBox VM.  
>  
```PowerShell
cd `z:\path\to\iiq-lab-windows\src\scripts`
```

>  
> Import the Packages Module  
>  
```PowerShell
Import-Module .\Packages.psm1
```

>  
> Download, install and configures the packages required for the IdentityIQ  
> lab Windows environment.  
> OpenJDK 21, Apache Tomcat 9, PostgreSQL 15  
>  
```PowerShell
Install-Packages
```

At the end of the packages installation, the system will be fully configured 
and ready for the IdentityIQ deployment. 

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
`secrets` directory:
* .secret_tomcat_manager_pass
* .secret_tomcat_rpa_pass
* .secret_tomcat_jmx_pass

The password for the `postgres` account is written to:
* .secret_psql



## IdentityIQ Build

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
| usingLcm= | Set to true to enb


```PowerShell
# Set build environment
$env:SPTARGET = "sandbox"

# Run the build command
.\build