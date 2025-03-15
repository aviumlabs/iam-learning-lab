Windows VirtualBox VM Installation Guide (c) by Michael Konrad

Windows VirtualBox VM Installation Guide is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


# Microsoft Windows Server 2022 VirtualBox VM Install Guide

A guide for configuring a VirtualBox VM to run Windows Server 2022.

## Download Evaluation ISO

https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US

Select ISO downloads 64-bit edition


## Configure VM

Assumptions:
* A "Software" directory exists to be setup as a VirtualBox `Shared Folder`. 

Open VirtualBox

- Select __New__
  * Name: __Win2022__
  * Folder: __default_path__ 
  * ISO Image: Browse to the Microsoft Windows ISO
  * Type:  Microsoft Windows 
  * Version: Windows 2022 (64-bit)
  * Select Skip Unattended Installation
- Select Hardware
  * Base Memory: 10256 MB
  * Processors: 3
- Select Hard Disk
  * Hard Disk File Location and Size: (Default path), Size: 80GB 
  * Select Finish

Select Settings
- Select System
  * __Boot Order__
  * Unselect Floppy
  * Move Floppy to bottom of list
- Select Network
  * Select __Adapter 1__
  * Attached to: NAT 
  * Select __Adapter 2__
  * Select Enable Network Adapter
  * Attached to: Host-only Adapter
  * Name: VirtualBox Host-Only Ethernet Adapter
- Select Shared Folders
  * Select __+__
  * Folder Path: Browse to "Software" directory
  * Folder Name: Software
  * Select Automount
  * Select OK
- Select OK
- Saving Settings


## Install Windows Server 2022
From VirtualBox Manager
- Select Win2022
- Select Start  

__Windows Server 2022__
- Microsoft Server Operting System Setup
  * Language to install: English (United States)
  * Time and currency format: English (United States)
  * Keyboard or input method: US
  * Select Next
- Select Install now 
- Select the operating system you want to install
  * Select Windows Server 2022 Standard Evaluation (Desktop Experience)
  * Select Next
- Applicable notices and license terms
  * Read terms and license
  * Select I accept...
  * Select Next
- Which type of installation do you want?
  * Select Custom: Install Microsoft Server Operating System only (advanced)
- Where do you want to install the operating system?
  * Drive 0 (default)
  * Select Next
- Installing Microsft Server Operating System 
...  
- Customize settings 
  * User name: Administrator
  * Password: __enter password__
  * Reenter password: __enter password__
  * Select Finish

  Login as Administrator  


## Install VirtualBox Guest Additions

Select Devices > Optical Drives > GuestAdditions.iso
Browse to Drive and double click VBoxWindowsAdditions

Reboot now
Select Finish

## Set Server Name

```PowerShell
Rename-Computer -NewName "devsrv"

# Restart Windows
shutdown /r
```

## Configure Windows Time Service

```PowerShell
Set-TimeZone -Id "Eastern Standard Time"

w32tm /config /update /manualpeerlist:pool.ntp.org
Restart-Service w32time
w32tm /query /status
```

## Turnoff Server Manager Dashboard

```PowerShell
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
```


## Disable IPv6
Disable IPv6 unless you have an IPv6 use case.

```PowerShell
# Get the current IP configuration 
Get-NetIPConfiguration

# Disable IPv6
Disable-NetAdapterBinding "Ethernet" -ComponentID ms_tcpip6
Disable-NetAdapterBinding "Ethernet 2" -ComponentID ms_tcpip6
```


## Set Host-Adapter Network Configuration

```PowerShell
# Get current network configuration
Get-NetIPConfiguration

# Set the IP address, where InterfaceIndex matches Host-Only Adapter (192.168.56.x)
New-NetIPAddress -IPAddress 192.168.56.20 -InterfaceIndex 6 -PrefixLength 24 `
-DefaultGateway 192.168.56.1

# Review Profiles
Get-NetFirewallProfile

# Block Inbound Connections by Default
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction Allow `
-NotifyOnListen False -AllowUnicastResponseToMulticast True `
-LogFileName $env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log

# Allow ICMPv4 (ping)
New-NetFirewallRule -Name 'ICMPv4' -DisplayName 'ICMPv4' `
-Description 'Allow ICMPv4' -Enabled True -Profile Any `
-Direction Inbound -Protocol ICMPv4 -Program Any -Action Allow `
-RemoteAddress LocalSubnet

# Confirm new firewall rule
Get-NetFirewallRule | Where-Object Name -Like 'ICMPv4'
```

```PowerShell
# Test ICMP from Workstation 
ping 192.168.56.20

# or 
Test-NetConnection -ComputerName devsrv
```

## Run Windows Update

```PowerShell
Install-Module -Name PSWindowsUpdate

Get-WindowsUpdate -AcceptAll -Install -AutoReboot
```

## Install Packages

The Packages.psm1 PowerShell module will download and install PowerShell 7.5.0, 
Visual Studio Code 1.98.0, and it will install and configure OpenSSH.

Copy the Pck.psm1 and Packages.psm1 file to the virtual machine and run the installer.

```PowerShell
# Allow the script to be executed
Unblock-File -Path .\Pck.psm1
Unblock-File -Path .\Packages.psm1

# Import the module
Import-Module .\Packages.psm1

# Download and install the packages
Install-Packages
```

__References__
* https://woshub.com/pswindowsupdate-module/


## Shutdown and Clone VM

Shutdown and clone the VirtualBox VM to be able to revert to a baseline 
configuration.

## Install Active Directory

```PowerShell
# Create a secure password string
$password = Read-Host -AsSecureString

# From the Packages module, run the Install-ActiveDirectory command.
Install-ActiveDirectory -ServerName "<server_name>" -DomainName "<domain_name>" -NetbiosName "<NAME>" -Pwd $password

# Configure DNS Network Adapter Setting
# Prevent this private DNS server from serving the public and loopback interfaces.

Get-DnsClient

# InterfaceIndexes may be different, set as required
Set-DnsClient -InterfaceIndex 7 -RegisterThisConnectionsAddress $false
Set-DnsClient -InterfaceIndex 1 -RegisterThisConnectionsAddress $false
Set-DnsClient -InterfaceIndex 1 -ConnectionSpecificSuffix $domain_name
Get-DnsClient

>  
> InterfaceAlias    InterfaceConnectionSpecifcSuffix  ConnectionSpecificSuffix  RegisterThisConn UseSuffixWhen  
>                   Index                             SearchList                ectionsAddress   Registering  
> ------------     --------------------------------  ------------------------  ---------------- -------------  
> Ethernet          7 localdomain                     {}                        True             False  
> Ethernet 2        6 <domain_name>                   {}                        False            False  
> Loopback Pse..    1                                 {}                        False            False  
>  

# Delete the 10.x DNS A resource record
# Any A record containing the RecordData of 10.0.x.x should be deleted.
Get-DnsServerResourceRecord -ZoneName $domain_name

# ...

Remove-DnsServerResourceRecord -ZoneName $domain_name -RRType A -Name DomainDnsZones -RecordData "10.0.2.15"
Remove-DnsServerResourceRecord -ZoneName $domain_name -RRType A -Name ForestDnsZones -RecordData "10.0.2.15"
Remove-DnsServerResourceRecord -ZoneName $domain_name -RRType A -Name $server_name -RecordData "10.0.2.15"

[Y] Yes [N] No [S] Suspend [?] Help (default is "Y"): __press enter__
```

## Shutdown and Clone VM

Shutdown and clone the VirtualBox VM to be able to revert to an AD baseline 
configuration.


__End of Windows Installation and Configuration__