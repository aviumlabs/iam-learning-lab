# Aviumlabs IAM Learning Lab

`Aviumlabs IAM Learning Lab` is a self-contained environment for 
learning about Identity and Access Management and SailPoint IdentityIQ. 


## Prerequisites

VirtualBox
GitHub CLI
GitHub Account
Git


## Getting Started

Create a directory, such as `Software` on your local workstation. The 
`Software` directory will be mounted inside the virtual machine. 

Clone this repository in the `Software` directory by creating a new private 
repository based on this repository under your GitHub Account.

```shell
cd Software
```

```shell
gh repo create iiq-lab-windows -c -d "Aviumlabs IAM Learning Lab" --private -p aviumlabs/iiq-lab-windows 
```

The included .gitignore file excludes the properitary SailPoint IdentityIQ files. 
Comment out the IdentityIQ IP section for a private repository. 

This lab's software components:
* Windows Server 2022
* PostgreSQl 15
* Tomcat 9
* Java 21

Setting up `Aviumlabs IAM Learning Lab` is documented in the guides 
in the docs directory. 

1. [aviumlabs-virtualbox-install-guide](./docs/aviumlabs-virtualbox-install-guide.md)
2. [aviumlabs-iam-lab-install-guide](./docs/aviumlabs-iam-lab-install-guide.md)


## Prerequisite Steps

The following prequisite steps need to be completed prior to running `Install-IdentityIQ`.

To complete the lab install, IdentityIQ needs to be downloaded from SailPoint 
https://community.sailpoint.com - requires a SailPoint Compass account.

IdentityIQ 8.4
* https://community.sailpoint.com/t5/IdentityIQ-Articles/What-s-New-in-IdentityIQ-8-4/ta-p/240336#

IdentityIQ 8.4 Checksum
* https://community.sailpoint.com/t5/IdentityIQ-Articles/What-s-New-in-IdentityIQ-8-4/ta-p/240336#

IdentityIQ 8.4p2
* https://community.sailpoint.com/t5/IdentityIQ-Server-Software/IdentityIQ-8-4p2/ta-p/262143#

IdentityIQ 8.4p2 Checksum
* https://community.sailpoint.com/t5/IdentityIQ-Server-Software/IdentityIQ-8-4p2/ta-p/262143#


__Verify__ the integrity of the downloaded files.
```PowerShell
# Verify hash against IdentityIQ_8.4_identityiq-8.4-CHECKSUM.txt
Get-FileHash -Path "identityiq-8.4.zip" -Algorithm SHA256

# Verify hash against identityiq-8.4p2-CHECKSUM.txt
Get-FileHash -Path "identityiq-8.4p2.jar" -Algorithm SHA256
```

Copy the `identityiq-8.4.zip` file to your **private** repository to the 
**src\ssb\base\ga** directory.

Copy the `identityiq-8.4p2.jar` file to the **src\ssb\base\patch** 
directory.

