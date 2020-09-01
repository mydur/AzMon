# azmon-vmlinnuxrules-tmpl

The purpose of this template is to deploy a set of alert rules to be used in Linux monitoring.

> **Note:** At the moment Linux monitoring is only supported for Azure hosted virtual machines.

_scheduledQueryRules_
| #   | Name                                                   | Breach | Threshold | Freq | Period |
| --- | :----------------------------------------------------- | :----- | :-------- | :--- | :----- |
| 1   | Linux Syslog - daemon – Critical                       | >2     | >1        | 15   | 45     |
| 2   | Linux Syslog - daemon – Warning                        | >2     | >4        | 15   | 45     |
| 3   | Linux Syslog - kern – Critical                         | >2     | >1        | 15   | 45     |
| 4   | Linux Syslog - kern – Warning                          | >2     | >4        | 15   | 45     |
| 5   | Linux Syslog - cron – Critical                         | >2     | >1        | 15   | 45     |
| 6   | Linux Syslog - cron – Warning                          | >2     | >4        | 15   | 45     |
| 7   | Linux Syslog - auth – Critical                         | >2     | >1        | 15   | 45     |
| 8   | Linux Syslog - auth – Warning                          | >2     | >4        | 15   | 45     |
| 9   | Linux Syslog - syslog – Critical                       | >2     | >1        | 15   | 45     |
| 10  | Linux Syslog - syslog – Warning                        | >2     | >4        | 15   | 45     |
| 11  | Linux Daemon State - ntpd                              | >1     | >0        | 5    | 10     |
| 12  | Linux Daemon State - crond                             | >1     | >0        | 5    | 10     |
| 13  | Linux Daemon State - sshd                              | >1     | >0        | 5    | 10     |
| 14  | Linux Daemon State - syslogd                           | >1     | >0        | 5    | 10     |
| 15  | Linux Daemon State - auditd                            | >1     | >0        | 5    | 10     |
| 16  | Linux Memory - pct Available – Critical                | >2     | <5        | 15   | 45     |
| 17  | Linux Memory - pct Available – Warning                 | >2     | <15       | 15   | 45     |
| 18  | Linux Memory - pct Available Swap Space – Critical     | >2     | <5        | 15   | 45     |
| 19  | Linux Memory - pct Available Swap Space – Warning      | >2     | <15       | 15   | 45     |
| 20  | Linux Memory - Pages per Sec – Critical                | >2     | >500      | 15   | 45     |
| 21  | Linux Memory - Pages per Sec – Warning                 | >2     | >350      | 15   | 45     |
| 22  | Linux Logical Disk - pct Used Space - root – Critical  | >2     | >95       | 15   | 45     |
| 23  | Linux Logical Disk - pct Used Space - root – Warning   | >2     | >85       | 15   | 45     |
| 24  | Linux Logical Disk - Free Megabytes - root – Critical  | >2     | <500      | 15   | 45     |
| 25  | Linux Logical Disk - Free Megabytes - root – Warning   | >2     | <2048     | 15   | 45     |
| 26  | Linux Processor - pct IO Wait Time - _Total – Critical | >2     | >85       | 15   | 45     |
| 27  | Linux Processor - pct IO Wait Time - _Total – Warning  | >2     | >75       | 15   | 45     |

_Actiongroup_
| #   | Name                         | Short Name   | Target            |
| --- | :--------------------------- | :----------- | :---------------- |
| 1   | vmlinuxrules-azmon-prod-agrp | vmlinuxazmon | dummy@nowhere.com |

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **AZMONBasicRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **workspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AZMONBasicRGName.
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

> As you probably noticed the resource group in which the virtual machines live that need to be monitored is not one of the parameters. That's because these alert rules are created in the same resource group as the virtual machines and the name of the target resource group can be obtained via a function in the template.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-vmrules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
