# azmon-basic-tmpl

The vmworkbook template is used to deploy an Azure monitor workbook to report on computer health and base performance counters.

After deployment the workbook contains the following.

**AVAILABILITY AND HEALTH**

- **Computers reporting in the last 24 hours:** Timechart graph that indicates how many computers are reporting to the log analytics workspace in the last 24 hours.
- **Availability rate in the last 24 hours (sample rate 5 minutes):** A grid showing the number of samples in which the computer was available during the last 24 hours. Based on that number of samples an availability rate in percent is calculated. In this grid you can select a computer that later will be used in the process views.
- **Last heartbeat > 5 minutes ago in the last 24 hours:** Grid that shown a list of computers with their last heartbeat next to it for a period of 24 hours. Computers not heartbeating for more than 24 hours will not show up.
- **Availability rate over {AvailRateOverDays} days (sample rate 5 minutes):** Another availability rate view but now with the number of days as a parameter.

**PERFORMANCE**

- **CPU % Total:** Timechart showing the total CPU usage per computer sampled every 15 minutes. Note that the percentage can go above 100% because of multi processor systems. This timechart makes it possible to brush the timeline. The brushed selection is then used for all other performance views in this workbook.
- **CPU Queue Length:** Average of CPU queue length per computer sampled every 15 minutes.
- **Memory Available Mbytes:** Average of available Mbytes per computer sampled every 15 minutes.
- **Pages/second:** Average number of pages per second per computer sampled every 15 minutes.
- **Free Space in MB:** Average logical disk free space per computer sampled every 15 minutes. A parameter to the workbook indicates which logical drive to use.
- **Disk Queue Length:** Average logical disk queue length per computer sampled every 15 minutes. A parameter to the workbook indicates which logical drive to use.
- **Bytes Received/sec:** Average network card bytes received per second sampled every 15 minutes. A parameter to the workbook indicates which network card to use.
- **Bytes Sent/sec:** Average network card bytes sent per second sampled every 15 minutes. A parameter to the workbook indicates which network card to use.
- **Top 10 Processes per CPU Usage:** The top 10 list of processes based on their CPU usage. The computer that is being reported on is selected in the Availability rate in the last 24 hours view.
- **Top 10 Processes by Memory (MB) Usage:** The top 10 list of processes based on their CPU usage. The computer that is being reported on is selected in the Availability rate in the last 24 hours view.

Like already mentioned in the list of views shown above, the workbook also has some parameters.

- **Workspace name:** The log analytics workspace from where to get the data.
- **Resource group:** The resource group used in the queries used to limit the scope of virtual machines.
- **Time frame:** The starting period for all views that don't have a period fixed in their query. Performance views can be time-brushed by the CPU % Total view.
- **Availability time frame:** The number of days to calculate the availability rate in the 2nd availability rate view that doesn't have a fixed period.
- **Logical disk:** The drive letter to use in the logical disk views. (Free Space in MB and Disk Queue Length)
- **Network adapter:** The network adapter to use in the network adapter views. (Bytes Received/Sec and Bytes Sent/Sec)

> The location or region where the workbook is deployed is the same as the one where the target resource group is located. As a resource group it's best to select the same resource group as the one where the log analytics workspace was deployed

To be able to re-use the template for different customers/projects the following parameters are used:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** The environment for which the resources can be used. Allowed values are dev-test-acc-prod.
- **WorkspaceName:** The name of the log analytics workspace used by the queries.
- **workbookId:** This paramter contains a GUID that is autmatically generated via [newGuid()].
- **CreatedOn:** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()]

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-vmworkbook-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
