# azmon-nwrules-tmpl

The purpose of this template is to deploy network monitoring alert rules that are used to alert if one or more of the three tests detected network issues. These tests are:

- **AzVnet2OnPrem:** Azure VNet to on-premise infrastructure communication.
- **AzVnet2Web:** Azure VNet to internet communication.
- **AzVnet2AzVnet:** Azure VNet to Azure VNet communication

> These tests need to be configured manually in the log analytics workspace via a set of steps that are separately available.

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **WorkspaceRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **WorkSpaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AZMONBasicRGName.
- **ActionGroupName:** The name of the action group that will be created by this template and used in all the alert rules also created by this template.
- **ActionGroupShortName:** The short name of the above (max 12 characters).
- **EmailAddress:** The email address of the mailboxreceiving direct emails from Azure Monitor for the alert rules created by this template.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project or customer identifier.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-nwrules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
