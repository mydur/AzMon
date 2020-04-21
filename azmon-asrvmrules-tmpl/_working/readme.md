# azmon-asrvmrules-tmpl

The purpose of this template is to deploy a set of Alert Rules and an Action Group to monitor Azure Site Recovery. The rules contained in this template monitor the health of the ASR configuration/process server.

_scheduledQueryRules_
| #   | Name                                                                     | Breach | Threshold | Freq | Period |
| --- | :----------------------------------------------------------------------- | :----- | :-------- | :--- | :----- |
| 1   | ASR - Cache Disk - % Free Space - Critical (ASRvmName)                   | >2     | <25       | 15   | 45     |
| 2   | ASR - Cache Disk - % Free Space - Warning (ASRvmName)                    | >2     | <35       | 15   | 45     |
| 3   | ASR - Service - Process Server (ASRvmName)                               | >1     | >0        | 5    | 10     |
| 4   | ASR - Service - Process Server Monitor (ASRvmName)                       | >1     | >0        | 5    | 10     |
| 5   | ASR - Service - cxprocessserver (ASRvmName)                              | >1     | >0        | 5    | 10     |
| 6   | ASR - Service - InMage PushInstall (ASRvmName)                           | >1     | >0        | 5    | 10     |
| 7   | ASR - Service - InMage Scout Application Service (ASRvmName)             | >1     | >0        | 5    | 10     |
| 8   | ASR - Service - InMage Scout VX Agent - Sentinel/Outpost (ASRvmName)     | >1     | >0        | 5    | 10     |
| 9   | ASR - Service - Log Upload Service (ASRvmName)                           | >1     | >0        | 5    | 10     |
| 10  | ASR - Service - Microsoft Azure Site Recovery Services Agent (ASRvmName) | >1     | >0        | 5    | 10     |
| 11  | ASR - Service - Microsoft Azure Site Recovery Service (ASRvmName)        | >1     | >0        | 5    | 10     |
| 12  | ASR - Service - tmansvc (ASRvmName)                                      | >1     | >0        | 5    | 10     |
| 13  | ASR - Service - MySQL (ASRvmName)                                        | >1     | >0        | 5    | 10     |
| 14  | ASR - Service - World Wide Web Pusblishing Service (ASRvmName)           | >1     | >0        | 5    | 10     |

_Actiongroup_
| #   | Name                        | Short Name  | Target            |
| --- | :-------------------------- | :---------- | :---------------- |
| 1   | asr-vmrules-azmon-prod-agrp | asrvmrazmon | dummy@nowhere.com |

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **AZMONBasicRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **workspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AZMONBasicRGName.
- **ASRvmName:** Name of thes erver holding the configuration and process role.
- **ASRcacheDrive:** Drive letter (including :) that holds the cache data. This will be used to add specific % Free Space monitoring.
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

> The resource group in which the alert rules will be deployed is the same resource group that hosts the recovery services vault.
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-asrvmrules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
