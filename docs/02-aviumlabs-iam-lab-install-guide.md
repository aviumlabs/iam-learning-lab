Avium Labs IAM Learning Lab Install Guide (c) by Michael Konrad

Avium Labs IAM Learning Lab Install Guide is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


# Avium Labs IAM Learning Lab Install Guide

After completing the `Avium Labs VirtualBox VM` install, run 
Aviumlabs-Packages module `Install-Packages` to install and 
configure the stack for running `Avium Labs IAM Learning Lab`.


## Avium Labs IAM Learning Lab Install

Login to the devsrv and run the following commands in PowerShell 7.

The Shared Folder is typically mounted on the Z: drive in the Windows  
VirtualBox VM.  
 
```PowerShell
cd `z:\path\to\iam-learning-lab\src\scripts`
```

Import the `Aviumlabs-Packages` module:  
```PowerShell
Import-Module .\Aviumlabs-Packages.psm1
```

`Install-Packages` downloads, installs, and configures these packages 
for the `Avium Labs IAM Learning Lab`:  

* OpenJDK 21
* Apache Tomcat 9 
* PostgreSQL 15 

```PowerShell
Install-Packages
```

At the end of the packages install, the system will be fully configured 
and ready for the deployment of IdentityIQ. 

The following Windows services are installed and set to start automatically:  
* apache-devsrv-a - an Apache Tomcat 9 instance
* postgresql-x64-15 - the PostgreSQL database server

## Shutdown and Clone VM

Shutdown and clone or take a snapshot of the VirtualBox VM to be able to 
revert to a Tomcat baseline configuration.

## Test Apache Tomcat (Optional)

The Apache Tomcat manager application is available at 
`https://devsrv:8443/manager`.

The install configures three Apache Tomcat users for the manager application:
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
cd `z:\path\to\iam-learning-lab\src\scripts`
```

Import the Aviumlabs-Iiq module:  
```PowerShell
Import-Module .\Aviumlabs-Iiq.psm1
```
Run the installer:
```PowerShell
Install-IdentityIQ
```

If you are installing this lab after v0.9.0, additionally run the following 
command to extend the Identity schema:
```PowerShell
Install-IiqExtendedSchema
```

After the deployment has completed open `https://devsrv:8443/identityiq.`

Login with the standard administrator account `spadmin`.

**End of Avium Labs IAM Learning Lab Install**


<a name="iiq-build-info" />  

## IdentityIQ Build Information

The `Avium Labs IAM Learning Lab` project uses SailPoint's 
`Standard Services Build` (ssb) for building an IdentityIQ deloyment.

Standard services build (ssb) uses Apache Ant for building an IdentityIQ 
deployment. There are several files that are used to control the build of 
IdentityIQ.

The build.properties file is the central control of the build process. 
There are several values that are required to be set prior to running a 
build. These properties have been preset for this lab.

__Required Properties__
| Property | Purpose |
| :---     | :---    | 
| IIQVersion=    | Sets the version of IdentityIQ to be deployed i.e. 8.4 |
| IIQPatchLevel= | Sets the patch version of IdentityIQ |

The following optional properties are useful in the deployment of IdentityIQ.
These properties are based on the individual components licensed. Setting these 
properties to true includes these components in the deployment. 

__Optional Properties__
| Property | Purpose |
| :---     | :---    |
| usingLcm=        | Lifecyle Manager         |
| usingRapidSetup= | RapidSetup               |
| usingPAM=        | Privilege Access Manager |
| usingFAM=        | File Access Manager      |
| usingCAM=        | Cloud Access Manager     |
| usingAI=         | AI Services              |

The build process supports various outputs including a basic build where 
the IdentityIQ files are extracted to the `build\extract` directory.

Manual steps for building IdentityIQ:
```PowerShell
# Set build environment
$env:SPTARGET = "sandbox"

# Run the build command
.\build
```

If you were doing a manual deployment of a new install there are a couple 
of prerequisites to be completed, prior to deployment.

Loading and upgrading the IdentityIQ databases; these sql scripts are located 
in the `build\extract\database` directory.
* create_identityiq_tables-8.4.*
* upgrade_identityiq_tables.*