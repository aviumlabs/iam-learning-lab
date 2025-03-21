Windows VirtualBox VM IIQ Stack Installation Guide (c) by Michael Konrad

Windows VirtualBox VM IIQ Stack Installation Guide is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


# Windows VirtualBox VM IIQ Stack Install Guide

After completing the VirtualBox Windows Server installation, run the 
Packages module Install-Packages cmdlet to install and configure the 
stack for running IdentityIQ.

```PowerShell
cd Documents\scripts
# Allow the script to be executed
Unblock-File -Path .\Packages.psm1

# Import the module
Import-Module .\Packages.psm1

# Downloads, installs and configures the packages required for the 
# IdentityIQ lab environment.
# Installs OpenJDK 21, Apache Tomcat 9, PostgreSQL 15
Install-Packages
```