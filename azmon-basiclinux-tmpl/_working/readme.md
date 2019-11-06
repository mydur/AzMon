# azmon-basiclinux-tmpl

Optionally the Azure Monitoring service also supports Linux machines hosted in Azure. Although the agent deployment policy (activated when the first resource group is added to monitoring) also supports Linux machines, the workspace still needs to be prepared for Linux monitoring. This is why we use this template. It does the following:
- Activates Syslog monitoring for
  - kern
  - daemon
  - cron
  - auth
  - syslog
- Activates performance counter collection for:
  - Memory
  - Logical Disk
  - Processor
  - Network
  - Process

> **NOTE:** Optionally the template will also deploy the workspace if it doesn't exist. Should the workspace already exist then the template will still try to deploy it but because ARM templates are idempotent this is not an issue.

To be able to re-use the template for different customers/projects the following parameters are use:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **VMRGName:** The resource group name that is used in the saved queries. This doesn't have to be an existing resource group as long as you don't use the saved queries.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **UniqueNumber:** Unique number to add to the name of the accounts.
- **dataRetention:** Number of retention days in the PerGB2018 pricing tier (31-730).
- **Location:** The region in which the deployment will take place.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-basiclinux-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
