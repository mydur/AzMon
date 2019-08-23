# azmon-blob-tmpl

The purpose of this template is to deploy a set of Alert Rules and an Action Group to be used in the alert rules for Azure Storage Blob Services monitoring.

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **StorAcctName:** Name of the storage account that hosts the file services. Note that the storage account must reside in the same resource group as the target fro the template deployment.
- **BlobCapacityThresholdMBWarning:** The warning threshold for blob services in MB.
- **BlobCapacityThresholdMBCritical:** The critical threshold for blob services in MB.
- **ActionGroupName:** The name of the action group that will be created by this template and used in all the alert rules also created by this template.
- **ActionGroupShortName:** The short name of the above (max 12 characters).
- **EmailAddress:** The email address of the mailboxreceiving direct emails from Azure Monitor for the alert rules created by this template.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project or customer identifier.
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.
  As you probably noticed the resource group in which the blobs live that need to be monitored is not one of the parameters. That's because these alert rules are created in the same resource group as the blobs and the name of the target resource group can be obtained via a function in the template.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-blob-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
