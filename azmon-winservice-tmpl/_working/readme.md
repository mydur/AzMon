# azmon-winservice-tmpl

The purpose of this template is to deploy an alert rule to monitor a give Windows service. The service to monitor is provided in a parameter to the template. You need to give the short name as well as the display name for the rule to work. Also the name of the action to use when forwarding the alert needs to be provided as a parameter. However, the latter has a default value: vmrules-azmon-prod-agrp

To be able to re-use the template the following parameters were introduced:

- **svcShortName:** The short name of the service to monitor. This one is used to build the name of the rule.
- **svcDisplayName:** The display name of the service to monitor. This one is used in the query.
- **WorkspaceRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **WorkspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AZMONBasicRGName.
- **actionGroupName:** The name of the action group to use when an alert has to be forwarded. Please note that this action group needs to exist before deploying the template.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

> Earlier versions of the template (before v1.0.3) also had parameters for action group (short and long) and email address. These parameters have been removed to comply to the way we will use action groups together with Servicenow.

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project or customer identifier.
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-winservice-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
