# azmon-basic-tmpl

The purpose of this template is to deploy a virtual machines health/performance workbook.

_More information later after 1st final version of the template._

To be able to re-use the template for different customers/projects the following parameters are used:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** The environment for which the resources can be used. Allowed values are dev-test-acc-prod.
- **WorkspaceName:** The name of the log analytics workspace used by the queries.
- **workbookId:** This paramter contains a GUID that is autmatically generated via [newGuid()].
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-vmworkbook-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
