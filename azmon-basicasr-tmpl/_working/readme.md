# azmon-basicasr-tmpl

The purpose of this template is to make the workspace ready for ASR monitoring. This is done by adding 2 datasources and some saved queries.

> **Note:** You will also find some lines in the template to deploy the AML workspace itself. This is needed because the sub-resources deployed later (saved queries, datasources) require this. Because the workspace already exists no actual deployment will take place.

The template adds datasources and saved queries to the AML workspace.

_Datasources:_
| #   | Name                 | Category     | Counter           | Instance | Interval |
| --- | :------------------- | :----------- | :---------------- | :------- | :------- |
| 1   | ASRSourceVmChurnRate | ASRAnalytics | SourceVmChurnRate | *        | 60       |
| 2   | ASRSourceVmThrpRate  | ASRAnalytics | SourceVmThrpRate  | *        | 60       |

_Saved queries:_
| #   | Name                         | Category                 | Display name                                    |
| --- | :--------------------------- | :----------------------- | :---------------------------------------------- |
| 1   | searchASRReplHealthCritical  | Atos ASR Monitoring | ASR - Replication health – Critical             |
| 2   | searchASRReplHealthWarning   | Atos ASR Monitoring | ASR - Replication health – Warning              |
| 3   | searchASRRPOBreachWarning    | Atos ASR Monitoring | ASR - RPO breaches – Warning                    |
| 4   | searchASRRPOBreachCritical   | Atos ASR Monitoring | ASR - RPO breaches – Critical                   |
| 5   | searchASRTestFailoverMissing | Atos ASR Monitoring | ASR - Too many test failovers missing – Warning |
| 6   | searchASRJobFailures         | Atos ASR Monitoring | ASR - Job failures                              |
| 7   | searchASRTestFailover90d     | Atos ASR Monitoring | ASR - Test failover last date 90days            |



To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **AMLWorkspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AMLResourceGroup.
- **AMLWorkspaceRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project or customer identifier.
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-basicasr-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
