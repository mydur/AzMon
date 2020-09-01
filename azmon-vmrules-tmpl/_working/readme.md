# azmon-vmrules-tmpl

The purpose of this template is to deploy a set of Alert Rules and an Action Group to be used in the alert rules.

_scheduledQueryRules_
| #   | Name                                                 | Breach | Threshold | Freq | Period |
| --- | :--------------------------------------------------- | :----- | :-------- | :--- | :----- |
| 1   | Heartbeat alert - Critical                           | >2     | >0        | 5    | 10     |
| 2   | Logical Disk - Current Disk Queue Length - Critical  | >2     | >5        | 15   | 45     |
| 3   | Logical Disk - Current Disk Queue Length - Warning   | >2     | >3        | 15   | 45     |
| 4   | Memory - Available MB - Critical                     | >2     | <500      | 15   | 45     |
| 5   | Memory - Available MB - Warning                      | >2     | <750      | 15   | 45     |
| 6   | Memory - Pages per Sec - Warning                     | >2     | >350      | 15   | 45     |
| 7   | Memory - Pages per Sec - Critical                    | >2     | >500      | 15   | 45     |
| 8   | Memory -  Percent Committed Bytes in Use - Crtitical | >2     | >90       | 15   | 45     |
| 9   | Memory -  Percent Committed Bytes in Use - Warning   | >2     | >75       | 15   | 45     |
| 10  | Processor - Queue Length - Warning                   | >2     | >3        | 15   | 45     |
| 11  | Processor - Queue Length - Critica                   | >2     | >5        | 15   | 45     |
| 12  | Processor - Time Total - Critical                    | >2     | >85       | 15   | 45     |
| 13  | Processor - Time Total - Warning                     | >2     | >70       | 15   | 45     |
| 14  | Service - DHCP Client                                | =1     | >0        | 5    | 5      |
| 15  | Service - DNS Client                                 | =1     | >0        | 5    | 5      |
| 16  | Service - Windows Event Log                          | =1     | >0        | 5    | 5      |
| 17  | Service - Windows Firewall                           | =1     | >0        | 5    | 5      |
| 18  | Service - RPC                                        | =1     | >0        | 5    | 5      |
| 19  | Service - Server                                     | =1     | >0        | 5    | 5      |
| 20  | Service - WinRM                                      | =1     | >0        | 5    | 5      |
| 21  | Logical Disk - Free MB on C - Critical               | >2     | <5000     | 15   | 45     |

_Actiongroup_
| #   | Name                    | Short Name | Target            |
| --- | :---------------------- | :--------- | :---------------- |
| 1   | vmrules-azmon-prod-agrp | vmrazmon   | dummy@nowhere.com |

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **AZMONBasicRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **workspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AZMONBasicRGName.
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

> **Note:** Earlier versions of the template also had parameters for action group (short and long) and email address. These parameters have been removed to comply to the way we will use action groups together with Servicenow.

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId:** String identifier for the current template. (azmon-basic)
- **TemplateVersion:** Version of the template.
- **CreatedOn:** Current timestamp.
- **Project:** Project or customer identifier.
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

> As you probably noticed the resource group in which the virtual machines live that need to be monitored is not one of the parameters. That's because these alert rules are created in the same resource group as the virtual machines and the name of the target resource group can be obtained via a function in the template.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-vmrules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
