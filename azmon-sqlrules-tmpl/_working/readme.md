# azmon-sqlrules-tmpl

The purpose of this template is to deploy a set of alert rules and an action group to monitor Azure SQL databases. The Azure SQL monitoring relies on diagnostic settings being enabled. If deployment is done via the automation script then enabling diagnostics is being taken care of by that script. 

Giving an overview of the alert rules is equal as telling what will be monitored for each database that is added to monitoring. Looked at it from a logical perspective this gives us the following list:
- **Blocked Connections:** Blocked connections are likely caused by firewall settings on your SQL server or database. AzMon SQL  automatically monitors the blocked_by_firewall.
- **Failed Connections:** Failed connections are connections that were not blocked by a firewall rule but were still unsuccessful. Failed connections can either be transient or persistent depending on their cause.  AzMon SQL  automatically monitors the connection_failed.
- **DTU Usage:** DTU Usage measures the amount of DTU used on your database or elastic pool as a percentage. DTU stands for Database Transaction Unit. DTUs give you a way to compare database performance across the service tiers offered by Azure. DTUs roughly measure performance as a combination of CPU, Memory, Reads, and Writes. AzMon SQL automatically monitors the dtu_consumption_percent metric for anomalous usage and high usage.
- **Deadlocks:** A deadlock is caused when two or more transactions hold locks that the other transactions require. Deadlocks will prevent the involved transactions from completing. When a deadlock is detected, the server will abort one of the involved transactions, rolling it back, and allowing the other transactions to proceed. The aborted transaction must be retried. AzMon SQL detects deadlocks in Azure SQL by monitoring the deadlock metric on your SQL databases.
- **IO Usage:** IO Usage measures the IO utilization of your database for its currently configured capacity. The amount of total IO available depends on your service tier and the configured amount of vCore of DTU. AzMon SQL automatically monitors Data and Log IO utilization via the physical_data_read_percent and log_write_percent metrics.
- **Sessions:** Sessions refers to the number of concurrent connections allowed to a SQL database at a time. The maximum number of sessions allowed depends on your databases’s service tier. When the sessions limit is reached, additional connections to the database will be rejected. AzMon SQL monitors the sessions_percent metric so you can know when you’ve hit the limit.
- **Workers:** Workers can be thought of as the processes in the SQL database that are processing queries. The maximum number of workers allowed depends on your databases’s service tier. When the worker limit is reached, clients will receive an error message and will be unable to query your database. AzMon SQL monitors the workers_percent metric so you can know when you’ve hit the limit.
- **Storage:** Storage measures the percentage of your max file storage that is in use. The max storage is easily confused with the allocated storage but they are different. Allocated storage is the amount of file storage that has been formatted and is writable by your database, and is automatically increased as more storage is needed, up to the maximum amount of storage. AzMon SQL  automatically monitors the storage_percent metric for high usage.


Several alert rules will be created:

_scheduledQueryRules_

| #   | Name                                                    | Type | Sev  | Interval | Period | Threshold | Breaches |
| --- | :------------------------------------------------------ | :--- | :--- | :------- | :----- | :-------- | :------- |
| 1   | SQL - DTU usage in percent (Warning)                    | AML  | 1    | 10       | 60     | > 85      | > 3      |
| 2   | SQL - DTU usage in percent (Critical)                   | AML  | 0    | 10       | 60     | > 95      | > 3      |
| 3   | SQL - IO usage physical data read in percent (Warning)  | AML  | 1    | 10       | 60     | > 85      | > 3      |
| 4   | SQL - IO usage physical data read in percent (Critical) | AML  | 0    | 10       | 60     | > 95      | > 3      |
| 5   | SQL - IO usage log write in percent (Warning)           | AML  | 1    | 10       | 60     | > 85      | > 3      |
| 6   | SQL - IO usage log write in percent (Critical)          | AML  | 0    | 10       | 60     | > 95      | > 3      |
| 7   | SQL - Storage in percent (Warning)                      | AML  | 1    | 10       | 60     | > 85      | > 3      |
| 8   | SQL - Storage in percent (Critical)                     | AML  | 0    | 10       | 60     | > 95      | > 3      |
| 9   | SQL - Failed connections (Warning)                      | AML  | 1    | 10       | 60     | > 10      | > 3      |
| 10  | SQL - Failed connections (Critical)                     | AML  | 0    | 10       | 60     | > 20      | > 3      |
| 11  | SQL - Sessions in percent (Warning)                     | AML  | 1    | 10       | 60     | > 85      | > 3      |
| 12  | SQL - Sessions in percent (Critical)                    | AML  | 0    | 10       | 60     | > 95      | > 3      |
| 13  | SQL - Workers in percent (Warning)                      | AML  | 1    | 10       | 60     | > 85      | > 3      |
| 14  | SQL - Workers in percent (Critical)                     | AML  | 0    | 10       | 60     | > 95      | > 3      |
| 15  | SQL - Blocked connections (Warning)                     | AML  | 1    | 10       | 60     | > 10      | > 3      |
| 16  | SQL - Blocked connections (Critical)                    | AML  | 0    | 10       | 60     | > 20      | > 3      |
| 17  | SQL - Deadlocks (Warning)                               | AML  | 1    | 10       | 60     | > 5       | > 3      |
| 18  | SQL - Deadlocks (Critical)                              | AML  | 0    | 10       | 60     | > 10      | > 3      |

&nbsp;

_Actiongroup_
| #   | Name                     | Short Name    | Target            |
| --- | :----------------------- | :------------ | :---------------- |
| 1   | sqlrules-azmon-prod-agrp | sqlrulesazmon | dummy@nowhere.com |

&nbsp;

To be able to re-use the template the following parameters were introduced:

&nbsp;

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

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-sqlrules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
