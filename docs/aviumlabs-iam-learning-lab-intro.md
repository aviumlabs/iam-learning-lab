# Avium Labs IAM Learning Lab

I am excited to share the release of the `Avium Labs IAM Learning Lab` - 
`https://github.com/aviumlabs/iam-learning-lab`. 

This initial release of `iam-learning-lab` is foundational only, later releases 
will introduce Identity and Access Lifecycle Management.

I hope we can agree even though this is only a foundational release, there is 
quite a bit of interesting material here. 

The overarching design goal of this project is to provide a `solid` and  
`consistent` learning environment, along with:  
* Self-contained environment   
* Support future releases/use cases  
* Automation  
* Advanced Logging Support  


## Highlights

* Automated package downloads  
* Automated integrity verification of package downloads  
* Automated install and configuration of Windows OpenSSH Capability  
* Automated install and configuration of Microsoft Active Directory  
  * Automated service account and security group creation  
  * Automated group policy deployment  
* Automated install and configuration of PostgreSQL 15  
* Automated install and configuration of Apache Tomcat 9  
* Automated build, deployment, and initialization of IdentityIQ 8.4  
  * Requires manually downloading software from SailPoint  


## Goals

### Self-Contained

For `Avium Labs IAM Learning Lab`, I've chosen VirtualBox for the virtual 
machine layer. It has cross-platform support and the `Clone` and `Snapshot` 
functionality make it easy to test a multitude of functionality. I've made 
heavy use of `Restore` in creating this lab :upside_down_face:.


### Future Releases

I've chosen Windows and Active Directory as the base platform to support 
future IAM use cases, specifically managing Active Directory Account and 
Group lifecycles. 

Even though many organizations are migrating to the Cloud and various 
directory services, Active Directory still has a significant presence and 
hopefully what you experiment with in this lab will transfer to 
other directory services and Account/Group lifecycle management.


### Automation

I've worked on `a lot` of projects across my career and one thing that 
**still** stands out today is the lack of consistency across 
**environments**, which is completely understandable as many organizations 
still rely on `hand jamming` software installs. I'm not a fan; if you 
have ever sat in `operations` at the end of a *hand jammed* install 
you know why I'm not a fan.

Not everything is automated in this learning lab, such as configuring your 
computer with the prerequisite software, initial install of Microsoft 
Windows Server 2022, network adapter configuration, DNS cleanup, etc. 

These are not automated mostly because it is a `local` learning environment. 

There are several tools for managing `Infrastructure as Code` including 
`OpenTofu`, `Palumi`, `Terraform`, and probably others; for advanced 
deployments.

Automation is performed by two main `PowerShell` modules and two supporting modules:  
| PowerShell Module       | Purpose                                                |
| :---                    | :--                                                    |
| Aviumlabs-Packages.psm1 | Package download, install, and configuration           |
| Aviumlabs-Iiq.psm1      | Automated build, deployment, and initialization of IIQ |
| Aviumlabs-Cutils.psm1   | Shared functions                                       |
| Aviumlabs-Cds.pms1      | Shared data structures                                 |

The modules are fairly well documented and are broken down by `Public API` and 
`Internal API`. Each task performed is broken down into one or more functions; 
each function is listed in alphabetical order per section and use 
`PowerShell Approved Verbs`. 

The `README.md` is the documentation starting point and for this release there 
are **two guides** that walk through the setup and deployment of 
`Avium Labs IAM Learning Lab`.

1. aviumlabs-virtualbox-install-guide.md  
2. aviumlabs-iam-lab-install-guide.md  

A log of the install is captured to `aviumlabs-iam-lab-install.log` in the 
`Documents` directory.

If you find a bug or issue, plesae report it here 
`https://github.com/aviumlabs/iam-learning-lab/issues`

### Advanced Logging Support

Logs are the backbone of troubleshooting and when you have a complex system, 
such as this one with multiple log files, potentially spread across multiple 
servers (advanced deployments); just finding the right logs becomes a tedious 
task. 

I've taken care to design this solution to maximize the advantages of 
Apache Tomcat. 

Apache Tomcat is installed and configured to support Tomcat instances. This 
separates the Tomcat binaries from the web application runtime. This has 
multiple benefits, including a straight forward method for keeping Apache 
Tomcat up to date and a specific log naming convention. 

The log naming convention is not supported out-of-the-box by Tomcat instances, 
it's done by the PowerShell module during the automated configuration. I'm not 
a regular expression guru, but damn are they handy!

It is a simple naming convention; `<instance_name>-<regular_log_name>`. This 
naming convention has huge wins in advanced deployments and logging to a 
shared filesystem. 

If you run this lab without changing the server name, you'll have the following 
Tomcat logs at the end of the install:  

* devsrv-a.\<date>
* devsrv-a-access-log.\<date>
* devsrv-a-catalina.\<date>
* devsrv-a-common-daemons.\<date>
* devsrv-a-host-manager.\<date>
* devsrv-a-manager.\<date>

`devsrv-a-catalina` is the primary log file for troubleshooting this Tomcat 
instance. 

I've also taken care to provide an advanced log4j2.properties file for managing 
the IdentityIQ logs. First, they are written to the same log directory as the 
Apache Tomcat logs. This is enabled through a combination of configuration and 
filesystem setup. 

The logs have been split to make it easier to pinpoint issues during development and troubleshooting. Future articles will cover their usage in detail.

* devsrv-a-identityiq
* devsrv-a-identityiq-console.log.gz
* devsrv-a-identityiq-error
* devsrv-a-identityiq-trace
* devsrv-a-sailpoint-discarded-messages

That's it for the intro. If you find this project useful, please give it a star 
on GitHub. 

If you find this project **really** useful, please consider becoming a `sponsor`. 

Oh, and if you are interested in web application development, check out my 
advanced web development project - `https://github.com/aviumlabs/phoenix-compose`. 

This is a `Docker` based project and (in my opinion), runs the most advanced 
technology stack out there today:  
* Alpine Linux 3.21.3  
* PostgreSQL 17.4  
* Erlang 27.3.4  
* Elixir 1.18.4  
* Phoenix Framework 1.7.21  

Version numbers are subject to change :wink:.

Have fun! 