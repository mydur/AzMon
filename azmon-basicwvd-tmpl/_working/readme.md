# azmon-basicfile-tmpl

The purpose of this template is to make the workspace ready for Azure File Sync (AFS) monitoring. This is done by adding  datasources (performance and event) and some saved queries.

> **Note:** You will also find some lines in the template to deploy the AML workspace itself. This is needed because the sub-resources deployed later (saved queries, datasources) require this. Because the workspace already exists no actual deployment will take place.

The template adds datasources and saved queries to the AML workspace.

_Datasources (perf):_
| #   | Name                  | Category              | Counter                        | Instance | Interval |
| --- | :-------------------- | :-------------------- | :----------------------------- | :------- | :------- |
| 1   | AFSBytesTransDownload | AFS Bytes Transferred | Downloaded Bytes/sec           | *        | 60       |
| 2   | AFSBytesTransUpload   | AFS Bytes Transferred | Uploaded Bytes/sec             | *        | 60       |
| 3   | AFSBytesTransTotal    | AFS Bytes Transferred | Total Bytes/sec                | *        | 60       |
| 4   | AFSBytesOpsDownload   | AFS Bytes Operations  | Downloaded Sync Files/sec      | *        | 60       |
| 5   | AFSBytesTransUpload   | AFS Bytes Operations  | Uploaded Sync Files/sec        | *        | 60       |
| 6   | AFSBytesOpsTotal      | AFS Bytes Operations  | Total Sync File Operations/sec | *        | 60       |

_Datasources (event):_
| #   | Name                    | Eventlog                                  | Error | Warning | Info |
| --- | :---------------------- | :---------------------------------------- | :---- | :------ | :--- |
| 1   | EventAFSDiagnostic      | microsoft-FileSync-Agent/Diagnostic       | X     | X       |      |
| 2   | EventAFSItemResults     | microsoft-FileSync-Agent/ItemResults      | X     | X       |      |
| 3   | EventAFSOperational     | microsoft-FileSync-Agent/Operational      | X     | X       |      |
| 4   | EventAFSRecallResults   | microsoft-FileSync-Agent/RecallResults    | X     | X       |      |
| 5   | EventAFSScrubbing       | microsoft-FileSync-Agent/Scrubbing        | X     | X       |      |
| 6   | EventAFSTelemetry       | microsoft-FileSync-Agent/Telemetry        | X     | X       |      |
| 7   | EventAFSTieringResults  | microsoft-FileSync-Agent/TieringResults   | X     | X       |      |
| 8   | EventAFSMgmtDiagnostic  | microsoft-FileSync-Management/Diagnostic  | X     | X       |      |
| 9   | EventAFSMgmtOperational | microsoft-FileSync-Management/Operational | X     | X       |      |

_Saved queries:_
| #   | Name                          | Category                 | Display name                                                                                |
| --- | :---------------------------- | :----------------------- | :------------------------------------------------------------------------------------------ |
| 1   | searchAFSConnNotEstablished   | Getronics AFS Monitoring | AFS - A connection with the service could not be established                                |
| 2   | searchAFSNoAccessAzFileShare  | Getronics AFS Monitoring | AFS - Sync can't access the Azure file share specified in the cloud endpoint                |
| 3   | searchAFSFailedNotAuth        | Getronics AFS Monitoring | AFS - Sync failed because the request is not authorized to perform this operation           |
| 4   | searchAFSStoAcctNameResolve   | Getronics AFS Monitoring | AFS - The storage account name used could not be resolved                                   |
| 5   | searchAFSUnknownErrAccess     | Getronics AFS Monitoring | AFS - An unknown error occured while accessing the storage account                          |
| 6   | searchAFSSyncFailStorAcctLck  | Getronics AFS Monitoring | AFS - Sync failed due to storage account locked                                             |
| 7   | searchAFSSyncFailDatabase     | Getronics AFS Monitoring | AFS - Sync failed due to a problem with the sync database                                   |
| 8   | searchAFSFileShareLImit       | Getronics AFS Monitoring | AFS - You reached the Azure file share storage limit                                        |
| 9   | searchAFSFileShareNotFound    | Getronics AFS Monitoring | AFS - The Azure file share cannot be found                                                  |
| 10  | searchAFSSyncFailAuth         | Getronics AFS Monitoring | AFS - Sync failed due to a problem with authentication                                      |
| 11  | searchAFSSyncFaulAuthId       | Getronics AFS Monitoring | AFS - Sync failed due to authentication identity not found                                  |
| 12  | searchAFSVolumeLowDisk        | Getronics AFS Monitoring | AFS - The volume where the server endpoint is located is low on disk space                  |
| 13  | searchAFSSyncFailManyFiles    | Getronics AFS Monitoring | AFS - Sync failed due to problems with many individual files                                |
| 14  | searchAFSSyncFailServerPath   | Getronics AFS Monitoring | AFS - Sync failed due to a problem with the server endpoint path                            |
| 15  | searchAFSServiceUnavailable   | Getronics AFS Monitoring | AFS - The service is currently unavailable                                                  |
| 16  | searchAFSSyncFailException    | Getronics AFS Monitoring | AFS - Sync failed due to an exception                                                       |
| 17  | searchAFSSyncFailPermSysVol   | Getronics AFS Monitoring | AFS - Sync failed because permissions on the System Volume Information folder are incorrect |
| 18  | searchAFSSyncFailDeleteCreate | Getronics AFS Monitoring | AFS - Sync failed because the Azure file share was deleted and recreated                    |

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


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-basicfile-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
