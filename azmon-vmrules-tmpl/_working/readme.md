# azmon-vmrules-tmpl

The purpose of this template is to deploy a set of Alert Rules and an Action Group to be used in the alert rules.

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **WorkspaceRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **WorkspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AZMONBasicRGName.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]

> Earlier versions of the template (before v1.0.5) also had parameters for action group (short and long) and email address. These parameters have been removed to comply to the way we will use action groups together with Servicenow.

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project or customer identifier.

> As you probably noticed the resource group in which the virtual machines live that need to be monitored is not one of the parameters. That's because these alert rules are created in the same resource group as the virtual machines and the name of the target resource group can be obtained via a function in the template.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-vmrules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
