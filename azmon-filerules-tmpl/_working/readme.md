# azmon-filerules-tmpl

The purpose of this template is to deploy a set of Alert Rules and an Action Group to be used in the alert rules for Azure File Sync monitoring.

There's two distinct alert rules sections:
- **metricAlerts:** Alert rules of this type are evaluated against the storage account that hosts the file shares.
- **scheduledQueryRules:** These are the alertrule type that we normally use and are evaluated against an AML workspace.

_metricAlerts_
| #   | Name                                                | Metric       | Threshold        | Freq | Period |
| --- | :-------------------------------------------------- | :----------- | :--------------- | :--- | :----- |
| 1   | AFS - File services availability (_storacctname_)   | Availability | Avg < 100 pct    | 15   | 60     |
| 2   | AFS - Storage account availability (_storacctname_) | Availability | Avg < 100 pct    | 15   | 60     |
| 3   | AFS - File capacity - Warning (_storacctname_)      | FileCapacity | Avg > WarnThresh | 15   | 60     |
| 4   | AFS - File capacity - Critical (_storacctname_)     | FileCapacity | Avg > CritThresh | 15   | 60     |

_scheduledQueryRules_
| #   | Name                                                                                                     | Breach | Threshold | Freq | Period |
| --- | :------------------------------------------------------------------------------------------------------- | :----- | :-------- | :--- | :----- |
| 1   | AFS - A connection with the service could not be established - (Computer)                                | >3     | >0        | 30   | 120    |
| 2   | AFS - Sync can't access the Azure file share specified in the cloud endpoint - (Computer)                | >3     | >0        | 30   | 120    |
| 3   | AFS - Sync failed because the request is not authorized to perform this operation - (Computer)           | >3     | >0        | 30   | 120    |
| 4   | AFS - The storage account name used could not be resolved - (Computer)                                   | >3     | >0        | 30   | 120    |
| 5   | AFS - An unknown error occured while accessing the storage account - (Computer)                          | >3     | >0        | 30   | 120    |
| 6   | AFS - Sync failed due to storage account locked - (Computer)                                             | >3     | >0        | 30   | 120    |
| 7   | AFS - Sync failed due to a problem with the sync database - (Computer)                                   | >3     | >0        | 30   | 120    |
| 8   | AFS - You reached the Azure file share storage limit - (Computer)                                        | >3     | >0        | 30   | 120    |
| 9   | AFS - The Azure file share cannot be found - (Computer)                                                  | >3     | >0        | 30   | 120    |
| 10  | AFS - Sync failed due to a problem with authentication - (Computer)                                      | >3     | >0        | 30   | 120    |
| 11  | AFS - Sync failed due to authentication identity not found - (Computer)                                  | >3     | >0        | 30   | 120    |
| 12  | AFS - The volume where the server endpoint is located is low on disk space - (Computer)                  | >3     | >0        | 30   | 120    |
| 13  | AFS - Sync failed due to problems with many individual files - (Computer)                                | >3     | >0        | 30   | 120    |
| 14  | AFS - Sync failed due to a problem with the server endpoint path - (Computer)                            | >3     | >0        | 30   | 120    |
| 15  | AFS - The service is currently unavailable - (Computer)                                                  | >3     | >0        | 30   | 120    |
| 16  | AFS - Sync failed due to an exception - (Computer)                                                       | >3     | >0        | 30   | 120    |
| 17  | AFS - Sync failed because permissions on the System Volume Information folder are incorrect - (Computer) | >3     | >0        | 30   | 120    |
| 18  | AFS - Sync failed because the Azure file share was deleted and recreated - (Computer)                    | >3     | >0        | 30   | 120    |

_Actiongroup_
| #   | Name                      | Short Name     | Target            |
| --- | :------------------------ | :------------- | :---------------- |
| 1   | filerules-azmon-prod-agrp | filerulesazmon | dummy@nowhere.com |


To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **AMLWorkspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AMLResourceGroup.
- **AMLWorkspaceRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **StorAcctName:** Name of the storage account that hosts the file services. Note that the storage account must reside in the same resource group as the target fro the template deployment.
- **FileCapacityThresholdMBWarning:** The warning threshold for file services in MB.
- **FileCapacityThresholdMBCritical:** The critical threshold for file services in MB.
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
  As you probably noticed the resource group in which the blobs live that need to be monitored is not one of the parameters. That's because these alert rules are created in the same resource group as the blobs and the name of the target resource group can be obtained via a function in the template.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-filerules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
