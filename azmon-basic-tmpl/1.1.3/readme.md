# azmon-basic-tmpl

The purpose of this template is to deploy a basic setup of Azure Monitor. It contains the following resources:

- Log Analytics workspace
- Automation Account
- Storage Account

For the storage account and automation account there's no initial configuration but the log analytics workspace has initial configurations set in the template for the following:

- Datasources
- Saved searches
- Solutions
- Linked services

To be able to re-use the template for different customers/projects the following parameters are use:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **VMRGName:** The resource group name that is used in the saved queries. This doesn't have to be an existing resource group as long as you don't use the saved queries.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-basic-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
