# azmon-basicsql-tmpl

The purpose of this template is to make the workspace ready for Azure SQL monitoring. The AzMon SQL monitoring solution, like any other AzMon solution, also uses the log analytics workspace as its main data storage. Preparing the workspace consists of activities that need to be executed only once and are applicable for all monitored databases. We can identify two different activities:
* Importing a SQL insights community workbook
* Adding the Azure SQL Analytics solution to the log analytics workspace
  
Importing the solution is done in the same way as all other solutions running on the AML workspace, via an ARM template. Although this template can only be deployed when the basic template is deployed (read AML workspace is already available) it will still try to create the AML workspace. The deployment will see that the AML workspace already exists and will then only add the subcomponents of the AML workspace that are also defined in this ARM template. The only subcomponent described in the ARM template is the SQL Analytics solution

> **Note:** You will also find some lines in the template to deploy the AML workspace itself. This is needed because the sub-resources deployed later (saved queries, datasources) require this. Because the workspace already exists no actual deployment will take place.

The template also adds saved queries to the AML workspace. 


&nbsp;

_Saved searches:_
| #   | Name                         | Category                 | Display name                                 |
| --- | :--------------------------- | :----------------------- | :------------------------------------------- |
| 1   | SearchSQLDTUusage            | Atos SQL Monitoring | SQL - DTU usage in percent                   |
| 2   | SearchSQLIOusagePhysDataRead | Atos SQL Monitoring | SQL - IO usage physical data read in percent |
| 3   | SearchSQLIOusageLogWrite     | Atos SQL Monitoring | SQL - IO usage log write in percent          |
| 4   | SearchSQLStorageUsagePercent | Atos SQL Monitoring | SQL - Storage usage in percent               |
| 5   | SearchSQLFailedConnections   | Atos SQL Monitoring | SQL - Failed connections                     |
| 6   | SearchSQLSessionsPercent     | Atos SQL Monitoring | SQL - Sessions usage in percent              |
| 7   | SearchSQLWorkersPercent      | Atos SQL Monitoring | SQL - Workers usage in percent               |
| 8   | SearchSQLBlockedConnections  | Atos SQL Monitoring | SQL - Blocked connections                    |
| 9   | SearchSQLDeadlocks           | Atos SQL Monitoring | SQL - Deadlocks                              |


&nbsp;

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **AMLWorkspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AMLResourceGroup.
- **AMLWorkspaceRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **SQLRGName:** Name of the resource group that will be used in the example saved queries.
- **Location:** The region in which the deployment will take place.
- **DataRetention:** Number of retention days in the PerGB2018 pricing tier (31-730).
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

&nbsp;

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project or customer identifier.
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

&nbsp;

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FAzMon%2Fmaster%2Fazmon-basicsql-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
