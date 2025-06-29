Avium Labs VirtualBox VM Install Guide (c) by Michael Konrad

Avium Labs VirtualBox VM Install Guide is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>


# Avium Labs VirtualBox VM Install Guide - Windows Server 2022

A guide for configuring a VirtualBox VM running Windows Server 2022.

## Download Evaluation ISO

https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US

Select ISO downloads 64-bit edition


## Configure VM

Assumptions:
* A `Software` directory exists to be setup as a VirtualBox `Shared Folder`. 

Open VirtualBox

- Select **New**
  * Name: **Win2022**
  * Folder: **default_path**
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
- Select General > Advanced
  * Set Shared Clipboard > Bidirectional
- Select System
  * **Boot Order**
  * Unselect Floppy
  * Move Floppy to bottom of list
- Select Network
  * Select **Adapter 1**
  * Attached to: NAT 
  * Select **Adapter 2**
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

**Windows Server 2022**
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
  * Password: **enter password**
  * Reenter password: **enter password**
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
```

Restart Windows
```PowerShell
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

Display the current IP configuration:  
```PowerShell
Get-NetIPConfiguration
```

Disable IPv6:  
```PowerShell
Get-NetAdapter | ForEach { Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 }
```


## Set Network Configuration

Set the IP address, where the `InterfaceIndex` matches the `Host-Only Adapter` 
(192.168.56.x):  
```PowerShell
New-NetIPAddress -IPAddress 192.168.56.20 -InterfaceIndex 6 -PrefixLength 24 `
-DefaultGateway 192.168.56.1
```

Review Firewall profiles:  
```PowerShell
Get-NetFirewallProfile
```

Block Inbound connections by default:  
```PowerShell
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction Allow `
-NotifyOnListen False -AllowUnicastResponseToMulticast True `
-LogFileName $env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log
```

Allow ICMPv4 (ping / Test-NetConnection):  
```PowerShell
New-NetFirewallRule -Name 'ICMPv4' -DisplayName 'ICMPv4' `
-Description 'Allow ICMPv4' -Enabled True -Profile Any `
-Direction Inbound -Protocol ICMPv4 -Program Any -Action Allow `
-RemoteAddress LocalSubnet
```

Confirm new firewall rule:  
```PowerShell
Get-NetFirewallRule | Where-Object Name -Like 'ICMPv4'
```

Test ICMP from your computer:  
```shell
ping 192.168.56.20
```

or:  
```PowerShell 
Test-NetConnection -ComputerName 192.168.56.20
```

## Run Windows Update

```PowerShell
Install-Module -Name PSWindowsUpdate
```

```PowerShell
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
```

## Install Packages and Active Directory

The `Aviumlabs-Packages.psm1` PowerShell module supports the install and 
configuration of several packages. 

**Important** you may want to update these **ADDomain** values defined at the 
top of the `Aviumlabs-Packages` module prior to running `Install-BasePackages`:   

* "DomainName" = "aviumlabs.test"
* "NetbiosName" = "AVIUMLABS"
* "RootDN" = "DC=aviumlabs,DC=test"
* "ServerName" = "devsrv.aviumlabs.test"
* "Locality" = "Washington"
* "Organization" = "Aviumlabs"
* "Country" = "US"
 
Set execution policy to Bypass for the current user:  
```PowerShell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```
 
The `Shared Folder` is typically mounted on the Z: drive in the Windows 
VirtualBox VM  
```PowerShell
cd `z:\path\to\iam-learning-lab\src\scripts`
```

:Import the Aviumlabs-Packages module:     
```PowerShell
Import-Module .\Aviumlabs-Packages.psm1
```
 
Download, install, and configure PowerShell 7 and Windows features:  

* PowerShell 7.5.1 
* Microsoft Windows OpenSSH Capability 
* Microsoft Active Directory

```PowerShell
Install-BasePackages
```

Restart Windows
```PowerShell
shutdown /r
```

**References**
* https://woshub.com/pswindowsupdate-module/


## Configure DNS

Prevent this private DNS server from serving the public and loopback interfaces.  

On this VirtualBox VM, Ethernet is the public interface and Ethernet 2 is the 
private network interface. Match the InterfaceIndex to public and private.  

Change the domain_name variable to match your enviornment:  
```PowerShell
$domain_name = "aviumlabs.test"
```

```PowerShell
Get-DnsClient
```

InterfaceIndexes may be different, set as required:
```PowerShell
Set-DnsClient -InterfaceIndex 13 -RegisterThisConnectionsAddress $False
```
```PowerShell
Set-DnsClient -InterfaceIndex 1 -ConnectionSpecificSuffix $domain_name
```
```PowerShell
Set-DnsClient -InterfaceIndex 12 -ConnectionSpecificSuffix $domain_name
```
```PowerShell
Get-DnsClient
```

>  
> InterfaceAlias    InterfaceConnectionSpecifcSuffix  ConnectionSpecificSuffix  RegisterThisConn UseSuffixWhen  
>                   Index                             SearchList                ectionsAddress   Registering  
> ------------     --------------------------------  ------------------------  ---------------- -------------  
> Ethernet          13                                {}                        False            False  
> Ethernet 2        12 $domain_name                   {}                        True             False  
> Loopback Pse..    1  $domain_name                   {}                        True             False  
>  


## Clean Up DNS

Display the DNS resource records:  
```PowerShell
Get-DnsServerResourceRecord -ZoneName $domain_name
```

Remove the public interface records:  
```PowerShell
$server_name = hostname
```
```PowerShell
Remove-DnsServerResourceRecord -ZoneName $domain_name -RRType A -Name "@" -RecordData "10.0.2.15" -Force
```
```PowerShell
Remove-DnsServerResourceRecord -ZoneName $domain_name -RRType A -Name DomainDnsZones -RecordData "10.0.2.15" -Force
```
```PowerShell
Remove-DnsServerResourceRecord -ZoneName $domain_name -RRType A -Name ForestDnsZones -RecordData "10.0.2.15" -Force
```
```PowerShell
Remove-DnsServerResourceRecord -ZoneName $domain_name -RRType A -Name $server_name -RecordData "10.0.2.15" -Force
```

Review the DNS resource record changes:  
```PowerShell
Get-DnsServerResourceRecord -ZoneName $domain_name
```


## Shutdown and Clone VM

Shutdown and clone or take a snapshot of the VirtualBox VM to be able to 
revert to an AD baseline configuration.


**End of Avium Labs VirtualBox VM Install**