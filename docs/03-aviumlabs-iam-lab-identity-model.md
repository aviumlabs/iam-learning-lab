Avium Labs Identity Model Guide (c) by Michael Konrad

Avium Labs Identity Model Guide is licensed under a 
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>

# Identity Model

Managing identities is a core pillar of Cybersecurity and getting to 
a `managed identity` state is a challenge for many organizations. 

This identity model is based on the principle of **least data**, similar to 
**least privilege**; the identity model captures sufficient attributes for an 
organization to be able to efficiently manage identities and access in 
accordance with the organization's business processes. 

This approach makes the Identity data set less valuable to hackers, reduces 
exposure in the event of a breach, and increases the maintainability of the 
data set. 

The data model developed in this guide will be the model used in the lab.

Identities can be used to identify nearly anything in an organization. This 
guide will focus on people and service accounts. 

Planning the identity model prior to deployment is an **important** step. For 
instance, as a common shared reference across the organization and for 
implementing the model in IdentityIQ.

Out-of-the-box IdentityIQ only supports 10 searchable attributes. If an 
organization requires more than 10 searchable attributes, then the IdentityIQ 
identity model needs to be extended during configuration. 


## Identity Model

| Attribute Friendly Name | Attribute Purpose |
| :---                  | :--- |
| Unique Id             | A unique identifier.                                                   |
| Type                  | The type of the identity, i.e., Employee, Contractor, Service Account. |
| Status                | The status of the identity, i.e., Active, Leave, Inactive.             |
| Given Name            | The given name or first name of the identity.                          |
| Preferred Given Name  | Optional preferred given name of the identity.                         |
| Middle Name           | Optional middle name of the identity.                                  |
| Family Name           | The family name or last name of the identity.                          |
| Preferred Family Name | Optional preferred family name of the identity.                        |
| Display Name          | The full, friendly name of the identity.                               |
| Title                 | Optional prefix of the identity - i.e., Mr, Ms, Mrs, Miss, Mx.         |
| Suffix                | Optional generational qualifier - i.e., Jr, Sr, I, II.                 |
| Organization          | The name of the organization the identity reports to.                  |
| Business Unit         | Optional zero or more business units where the identity reports to.    |
| Department            | The department the identity reports to.                                |
| Job Title             | The job title of the identity.                                         |
| Position              | The position number of the identity.                                   |
| Email                 | The email address of the identity.                                     |
| Reports To            | The identity responsible for this identity.                            |
| Location              | Optional zero or more physical/logical locations of the identity.      |
| Phone Number          | Optional zero or more telephone numbers of the identity.               |
| Service Date          | The date the identity starts with the organization.                    |
| Record Date           | The latest date the identity record has been processed by HR.          |

Business unit, Location, and Phone Number as defined in this identity model 
have their own data models, but are typically defined as single-valued attributes on 
the identity. 
IdentityIQ supports multivalued attributes as `lists`. There is also 
the consideration of downstream or target applications capability to support 
rich data models. 


## IdentityIQ Information

The following information is helpful in planning the identity model and 
implementation of the identity model in IdentityIQ in relation to the 
organization's business processes.


### Default Identity Types

* Employee
* Contractor
* External / Partner
* RPA / Bots
* Service Account


### Workgroups

Workgroups are used to manage internal SailPoint access, for shared 
responsibilities, or managing tasks. 

Such as:
* Application Owner
* Application Revoker
* Certification Owner
* Role Owner
* Entitlement Owner
* Account Group Owner
* Policy Owner
* Policy Violation Owner
* Policy Violation Observers


### Populations

Populations are sets of identities generated from queries on the Advanced 
Analytics page and can be based on multiple criteria. Any identity attribute 
marked as __Searchable__ can be used as a population criteria. 

The result of the query (the population) is a single set of identities who 
share a common set of properties.


### Groups

Groups are sets of identities that share a common value for a specific 
identity attribute. Only identity attributes marked as __Group Factory__ 
attributes can be used as a group filter attribute in the creation of 
Groups. 

Groups are usually created in sets. 

When a Population or a Group is saved, the query criteria to generate it is 
saved and not the set of identities that matched the criteria at that time. 
Each time the Population or Group is used, the query is run and the current 
set of identities matching the criteria is returned and applied to the 
operation. 


## Cybersecurity Framework

`Identity and Access Management` or `Identity Governance and Administration` is 
the **middleware** of an organization and falls under the `PROTECT` section of 
the [NIST Cybersecurity Framework 2.0](https://www.nist.gov/cyberframework).

The lab will focus on two `Subcategories`:

* PR.AA-01: Identities and credentials for authorized users, services, and 
  hardware are **managed** by the organization

* PR.AA-05: Access permissions, entitlements, and authorizations are defined 
  in a policy, **managed**, enforced, and reviewed, and incorporate the principles 
  of least privilege and separation of duties 

The lab will not covery hardware from PR.AA-01 or policy from PR.AA-05.


## Business Processes

IAM supports and enhances a company's business processes; in onboarding, 
transferring, and offboarding personnel, in managing access to information 
technology systems and services, and in managing operational accounts. 

Along the way we will develop workflows (business processes) for `managing` 
identities. We will consider the following business processes in the lab:  

* Onboarding
* Going on Leave
* Returning from Leave
* Transferring
* Offboarding


## Identity Mapping

Mapping the identity model into IdentityIQ has a direct impact on the 
development of workflows and other SailPoint features, such as searching 
and reporting.   

**Identity Mapping - IdentityIQ Model**  
| Attribute Name        | IIQ Field Name        | IIQ Searchable | IIQ Indexed | IIQ Group Factory |
| :---                  | :---                  | :---           | :---        | :---              |
| Employee Id           | name                  | Y (OOTB)       | Y (OOTB)    | N                 |
| Type                  | type                  | Y (OOTB)       | Y (OOTB)    | N                 |
| Status                | status                | Y              | Y           | Y                 |
| Given Name            | firstname             | Y (OOTB)       | Y (OOTB)    | N                 |
| Preferred Given Name  | preferredGivenName    | N              | N           | N                 |
| Middle Name           | middleName            | N              | N           | N                 |
| Family Name           | lastname              | Y (OOTB)       | Y (OOTB)    | N                 |
| Preferred Family Name | preferredFamilyName   | N              | N           | N                 |
| Display Name          | displayName           | N              | N           | N                 |
| Title                 | title                 | N              | N           | N                 |
| Suffix                | suffix                | N              | N           | N                 |
| Organization          | organization          | N              | N           | N                 |
| Business Unit         | businessUnit          | Y              | Y           | Y                 |
| Department            | department            | Y              | Y           | Y                 |
| Job Title             | jobTitle              | Y              | Y           | Y                 |
| Position              | position              | Y              | Y           | N                 |
| Reports To            | manager               | Y (OOTB)       | Y (OOTB)    | Y (OOTB)          |
| Email                 | email                 | Y (OOTB)       | Y (OOTB)    | N                 |
| Location              | location              | Y              | Y           | Y                 |
| Phone Number          | phoneNumber           | Y              | Y           | N                 |
| Service Date          | serviceDate           | Y              | Y           | N                 |
| Record Date           | recordDate            | Y              | Y           | N                 |


IIQ Searchable Total: 10  
IIQ Indexed Total:    10  
IIQ Group Factory:    5

With the identity mapping completed, we can now create the identity model in 
IdentityIQ. 

For the lab, the `example.build.custom.Extend-idAttrs.xml` file 
has been renamed and modified to create the searchable and indexed attributes 
as part of SSB build. 


## Install with Updated Identity Model

If you deployed the initial version of this lab, v0.9.0, the following 
steps will build and deploy the updated IdentityIQ war and extend the 
Identity schema. 

```PowerShell
cd `z:\path\to\iam-learning-lab\src\scripts`
```

Import the Aviumlabs-Iiq module:  
```PowerShell
Import-Module .\Aviumlabs-Iiq.psm1
```
Run the installer:
```PowerShell
Deploy-IdentityIQ
```

Extend the schema:
```PowerShell
Install-IiqExtendedSchema
```

### Identity Mapping IdentityIQ Configuration

The next steps will map the new identity attributes in IdentityIQ. Use the 
`Identity Mapping - IdentityIQ Model` for configuring the settings of each 
attribute. 

With the schema extended, open IdentityIQ - 
`https://devsrv:8443/identityiq/login.jsf?prompt=true`

These are the manual steps required to map the identity model in IdentityIQ.  
The resulting artifacts are included in the SSB build and will be deployed automatically.  

1. Select Gear > Global Settings > Identity Mappings

There will be an error on this page with 
`...property xyz is not defined in ObjectConfig:Identity`. 

2. Select Add New Attribute

Complete the pop-up form for each attribute:  

  a. Attribute Name: status
  b. Display Name: avm_status
  c. Select Searchable
  d. Select Group Factory

Select Save

  a. Attribute Name: organization
  b. Display Name: avm_organization

Select Save

  a. Attribute Name: businessUnit
  b. Display Name: avm_business_unit
  c. Select Searchable
  d. Select Group Factory

Select Save

  a. Attribute Name: department
  b. Display Name: avm_department
  c. Select Searchable
  d. Select Group Factory

Select Save

  a. Attribute Name: position
  b. Display Name: avm_position
  c. Select Searchable

Select Save

  a. Attribute Name: location
  b. Display Name: avm_location
  c. Select Searchable
  d. Select Multi-Valued
  e. Select Group Factory

Select Save

  a. Attribute Name: phoneNumber
  b. Display Name: avm_phone_number
  c. Select Searchable
  d. Select Multi-Valued

Select Save

  a. Attribute Name: serviceDate
  b. Display Name: avm_service_date
  c. Select Searchable

Select Save

  a. Attribute Name: recordDate
  b. Display Name: avm_record_date
  c. Select Searchable

Select Save

The baseline identity model is now configured in IdentityIQ.

The attribute `Display Name` values have been configure in the 
`ssb > web > WEB-INF > classes > sailpoint > web > messages > iiqCustom.properties` 
file.  

### Object Exporter

The lab includes the `Object Exporter` plugin which needs to be configured 
prior to exporting the ObjectConfig artifact. 

1. Select Setup > Tasks  
2. Select New Task
3. Select `XML Object Exporter`
  a. Name: Export Artifacts
  b. Base path for export: `/apps/backups/artifacts`
  c. Select Remove IDs from exported XML
  d. Set Classes to export (leave blank for all, use 'default' for a default 
     set of classes): `default`
  e. Select Strip environment-specific metadata
  e. Set Naming format (see help text for variables): `avm_$Class$_$Name$`

Select Save and Execute

Wait for the task to complete, select the `Task Results` tab to watch.

Copy \apps\backups\artifacts\ObjectConfig\avm_ObjectConfig_Identity file 
to the SSB\config\ObjectConfig directory.

Copy \apps\backups\artifacts\TaskDefinition\avm_TaskDefinition_Export_Artifacts 
file to the SSB\config\TaskDefintion directory.

Run a new deploy and test that the changes have been captured and are 
deployed correctly.

```PowerShell
cd `z:\path\to\iam-learning-lab\src\scripts`
```

Import the Aviumlabs-Iiq module:  
```PowerShell
Import-Module .\Aviumlabs-Iiq.psm1
```
Run the installer:
```PowerShell
Deploy-IdentityIQ
```


## Reference

**File Changes**

File name change: build.custom.extended-idattribs.xml  

`
<project name="services.standard.build.custom.acme-idattrs.xml"> 

<project name="services.standard.build.custom.extended-idattrs.xml">
`

`
description="Make modifications to IdentityExtended.hbm.xml to add ACME's attrs.">

description="Make modifications to IdentityExtended.hbm.xml to add extended attrs.">
`

`
<!-- Modified to support ACME's Extended Attributes.

<!-- Modified to support Extended Attributes.
`

`
<property name="effectivePerNer" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_effective_per_ner_ci"  />
<property name="networkId" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_network_id_ci"  />
<property name="organizationalManager" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_org_mgr_ci"  />
<property name="emplid" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_emplid_ci"  />
<property name="agency" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_agency_ci"/>
`


`
<property name="status" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_status_ci"  />
<property name="organization" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_organization_ci"  />
<property name="businessUnit" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_business_unit_ci"  />
<property name="department" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_department_ci"  />
<property name="jobTitle" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_job_title_ci"/>
<property name="position" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_position_ci"/>
<property name="location" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_location_ci"/>
<property name="phoneNumber" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_phone_number_ci"/>
<property name="serviceDate" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_service_date_ci"/>
<property name="recordDate" type="string" length="450"
    access="sailpoint.persistence.ExtendedPropertyAccessor"
    index="spt_identity_record_date_ci"/>
`

`
<!-- End of Modify for ACME's Extended Attributes.

<!-- End of Modify for Extended Attributes.
`

`
<echo message="Applying ACME Identity Attributes extensions for ExtendedPropertyAccessor"/>

<echo message="Applying Identity Attributes extensions for ExtendedPropertyAccessor"/>
`