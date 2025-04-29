Identity Planning Guide (c) by Michael Konrad

Identity Planning Guide is licensed under a 
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work. If not, see <http://creativecommons.org/licenses/by/4.0/>

# Identity

Managing identities is a core pillar of Cybersecurity and getting to 
a `managed identity` state is a challenge for many organizations. 

This identity model is based on the principle of __least data__, similar to 
__least privilege__; the identity model captures sufficient attributes for an 
organization to be able to efficiently manage identities and access. 

The identity model needs to be able to support the organization's 
business processes. 

This approach makes the Identity data set less valuable to hackers, reduces 
exporsure in the event of a breach, and increases the maintainability of the 
data set. 

The data model developed in this guide will be the model used in this lab.

Identities can be used to identify nearly anything in an organization. This 
guide will focus on people and machines - in this guide service accounts fall 
under machines.

Planning the identity model prior to deployment is an __important__ first step,
as IdentityIQ processes revolve around the identity model. Out-of-the-box 
IdentityIQ only supports 10 searchable attributes. If an organization requires 
more than 10 searchable attributes, then the IdentityIQ identity model needs to 
be extended during deployment. 


## Identity Model

| Attribute Friendly Name | Attribute Purpose |
| :---           | :--- |
| Unique Id      | An identifier, typcially a number that uniquely identifies the identity across the organization. |
| Type           | The type of the identity, i.e., Employee, Contractor, Machine,  |
| Status         | The status of the identity, i.e., Active, Disabled |
| Given Name     | The given name or first name of the identity. |
| Middle Name    | Optional middle name of the identity. |
| Family Name    | The family name or last name of the identity. |
| Dipplay Name   | The full name of the identity. |
| Title          | Optional prefix of the identity - i.e., Mr, Ms, Mrs, Miss, Mx. |
| Suffix         | Optional generational qualifier - i.e., Jr, Sr, I, II. |
| Organiation    | The name of the organization where the identity is deployed. |
| Business Unit  | The unit or division where the identity is deployed. |
| Department     | The department where the identity is deployed. |
| Job Title      | The job title of the identity. |
| Location       | Optional physical / logical location of the identity. | 
| Mobile         | The mobile telephone number of the identity. |


## IdentityIQ Out-of-the-Box (OOTB) Identity Attributes


IdentityIQ has 5 OOTB identity attributes that are searchable and indexed.

| Attribute Name | Attribute Purpose |
| :---           | :--- |
| name | Unique identifier (i.e. EmployeeId, UserId, Username, etc) |
| firstname | Identity full first name |
| lastname  | Identity full last name |
| type | Identity type |



IdentityIQ supports additional identity attributes out-of-the-box, 
10 OOTB extended identity attributes searchable and 5 indexed.


### Default Identity Types

* Employee
* Contractor
* External / Partner
* RPA / Bots
* Service Account


## Workgroups

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


## Populations

Populations are sets of identities generated from queries on the Advanced 
Analytics page and can be based on multiple criteria. Any identity attribute 
marked as __Searchable__ can be used as a population criteria. 


The  result of the query (the population) is a single set of identities who 
share a common set of properties.


## Groups

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