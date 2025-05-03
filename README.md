# Aviumlabs IAM Learning Lab

`Avium Labs IAM Learning Lab` is a self-contained environment for 
learning about Identity and Access Management and SailPoint IdentityIQ. 


## Prerequisites

You'll need a `GitHub` account and the following software installed on your
computer prior to starting this lab.

* VirtualBox
* GitHub CLI
* Git


## Getting Started

Create a directory, such as `Software` on your computer. The 
`Software` directory will be mounted inside the virtual machine. 

Clone this repository in the `Software` directory by creating a new private 
repository based on this repository under your GitHub Account.

```shell
cd Software
```

```shell
gh repo create iam-learning-lab -c -d "Avium Labs IAM Learning Lab" --private -p aviumlabs/iam-learning-lab
```

The included .gitignore file excludes the properitary SailPoint IdentityIQ files. 
Comment out the IdentityIQ IP section for a private repository. 

This lab's software components:

* Windows Server 2022
* PostgreSQl 15
* Tomcat 9
* Java 21

Setting up `Avium Labs IAM Learning Lab` is documented in the guides 
in the docs directory. 

1. [aviumlabs-virtualbox-install-guide](./docs/aviumlabs-virtualbox-install-guide.md)
2. [aviumlabs-iam-lab-install-guide](./docs/aviumlabs-iam-lab-install-guide.md)


## Additional Prerequisite Software

The following prequisite software needs to be downloaded and copied to your 
**private** repository prior to running `Install-IdentityIq`.

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