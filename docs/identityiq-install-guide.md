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

```PowerShell
# Shared Folder is typically mounted on the Z: drive in VirtualBox
z:
cd `\path\to\iiq-lab-windows\src\scripts`

# Import the module
Import-Module .\Packages.psm1

# Downloads, installs and configures the packages required for the IdentityIQ 
# lab Windows environment.
# OpenJDK 21, Apache Tomcat 9, PostgreSQL 15
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

The iiq-lab-windows project includes the SailPoint `Standard Services Build` 
as the method for building an IdentityIQ deloyment.

