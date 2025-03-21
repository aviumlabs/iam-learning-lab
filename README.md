# Microsoft Windows IdentityIQ Lab

This project is an implmentation of SailPoint IdentityIQ on 
Windows Server 2022, it requires a SailPoint Compass account to be able to 
download SailPoint IdentityIQ.

This lab is structured to run the stack in a VirtualBox VM.

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
 

The stack:
* Windows Server 2022
* PostgreSQl 15
* Tomcat 9
* Java 21


To configure the VirtualBox VM and deploy the stack follow the steps in 
docs/windows-virtualbox-installation-guide.md.


