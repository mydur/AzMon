# azmon-svchealth-tmpl

Azure is comprised of managed services that are offered to the customer. These services hosted in Azure all run of course on hardware. It is Microsoft's task to monitor that hardware and also the software that delivers the service to the customer. We can't and shouldn't monitor the hardware or the software that hosts the services but we should at least be aware of the health state of the different services.

This template aims to notify us when a service has issues or when there's planned downtime or maintenance scheduled.

Alert rules created in this template also need a target to work against. In this case this will be at the subscription level. Two alert rules will be created, one for Incidents and one for Information. The criteria in the alert rules uses the following parameters:

- Category (= ServiceHealth)
- IncidentType
- ServiceName
- RegionName

The IncidentType can go two ways:

- Issue rule = Incident
- Information rule = Maintenance or Informational or ActionRequired

In the ServiceName parameter we put the list of services that we want to monitor. This list can be extended in the template before it's deployed or later in the alert rule after deployment. A basic list is foreseen and this holds the following services:

- Application Insights
- Automation
- Azure Active Directory
- Azure DNS
- Azure Monitor
- Azure Policy
- Azure Resource Manager
- Backup
- Diagnostic Logs
- Log Analytics
- Network Infrastructure
- Network Watcher
- Storage
- Virtual Machines
- Virtual Network

The region(s) in which those services are used is also in the criteria. The same remark here as for the services, a basic list is foreseen but can be modified before or after the deployment. In the basic list you will find following regions:

- West Europe

Following resource types are created by the template:

- Alert Rules
- Action Group(s)

The location where the resources are created is choosen at deployment time and should be the resource group where the basic monitoring setup is deployed. Lifecycle of the created resources is defined by the lifecycle of the subscription at which they are targetted.

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** The environment for which the resources can be used. Allowed values are dev-test-acc-prod.
- **actionGroupName:** Full name of the action group that is created for direct notification via email.
- **actionGroupShortName:** Short name of maximum 12 characters for the email notification action group.
- **emailAddress:** Email address of the person or group to be added to the action group.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()].

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project, customer or application identifier.
- **Environment:** The environment for which the resources can be used.

> As you probably noticed the subscription that is targetted is not part of the parameters. That's because the resources are created in a resource group that lives in the targetted subscription and thus the name of the subscription can be retrieved by a function in JSON.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-svchealth-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
