# IdentityIQ Lab - Microsoft Windows Environment 

This project is an implmentation of SailPoint IdentityIQ on 
Windows Server 2022, it requires a SailPoint Compass account to be able to 
download SailPoint IdentityIQ.

This lab is designed to be self-contained and installed on a VirtualBox 
virtual machine.

## Prerequisites

VirtualBox
GitHub CLI
GitHub Account
Git

## Getting Started

Create a directory, such as `Software` on your local workstation. The 
`Software` directory will be mounted inside the virtual machine. 

Clone this repository in the `Software` directory.
```shell
cd Software

# Create a new private repository based on this repository, under your
# GitHub Account
gh repo create iiq-lab-windows -c -d "An IdentityIQ Lab Environment" --private -p aviumlabs/iiq-lab-windows 
```

The included .gitignore file excludes the properitary SailPoint IdentityIQ files. 
Comment out the IdentityIQ IP section for a private repository. 

This lab's software components:
* Windows Server 2022
* PostgreSQl 15
* Tomcat 9
* Java 21


__Important first step__ prior to working on the implementation is to download 
IdentityIQ from SailPoint. This requires a SailPoint Compass account.

IdentityIQ 8.4
* https://community.sailpoint.com/t5/IdentityIQ-Articles/What-s-New-in-IdentityIQ-8-4/ta-p/240336#

IdentityIQ 8.4 Checksum
* https://community.sailpoint.com/t5/IdentityIQ-Articles/What-s-New-in-IdentityIQ-8-4/ta-p/240336#

IdentityIQ 8.4p2
* https://community.sailpoint.com/t5/IdentityIQ-Server-Software/IdentityIQ-8-4p2/ta-p/262143#

IdentityIQ 8.4p2 Checksum
* https://community.sailpoint.com/t5/IdentityIQ-Server-Software/IdentityIQ-8-4p2/ta-p/262143#


__Verify__ the files have not been tampered.
```PowerShell
# Verify hash against IdentityIQ_8.4_identityiq-8.4-CHECKSUM.txt
Get-FileHash -Path "identityiq-8.4.zip" -Algorithm SHA256

# Verify hash against identityiq-8.4p2-CHECKSUM.txt
Get-FileHash -Path "identityiq-8.4p2.jar" -Algorithm SHA256
```

Setting up the IdentityIQ lab Windows environment is documented in the guides 
in the docs directory. 

1. [windows-virtualbox-install-guide](./docs/windows-virtualbox-install-guide.md)
2. [identityiq-install-guide](./docs/identityiq-install-guide.md)


