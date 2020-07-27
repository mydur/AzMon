# azmon-k8srules-tmpl

The purpose of this template is to deploy a set of Alert Rules and an Action Group to monitor a Kubernetes (K8S) cluster. Each K8S cluster that needs to be managed must be added to monitoring individually and via this template. The template also enables Azure Monitor for Containers. This tells the K8S cluster to enable the _omsagent_ addon and report data to our workspace.

> **Note:** With the template we aim to add generic K8S cluster monitoring that doesn't take into account the individual containers or applications that run on the cluster. Because of the generic nature of the template and the alert rules in it the thresholds used throughout different alert rules will need to be modified to suit your environment. 

_scheduledQueryRules_
| #   | Name                                                          | Breach | Threshold | Freq | Period |
| --- | :------------------------------------------------------------ | :----- | :-------- | :--- | :----- |
| 1   | K8S - Pods that are failing or recovered from failure         | >2     | >15       | 15   | 45     |
| 2   | K8S - Pods are being evicted                                  | >2     | >10       | 15   | 45     |
| 3   | K8S - Storage related issues have been detected               | >2     | >10       | 15   | 45     |
| 4   | K8S - Scheduler unable to find node to run pod                | >2     | >10       | 15   | 45     |
| 5   | K8S - Node not ready or not schedulable                       | >2     | >15       | 15   | 45     |
| 6   | K8S - Too many failures detected in short time-span           | >2     | >25       | 15   | 45     |
| 7   | K8S - Nodes average CPU utilization in percent (Warning)      | >2     | >80       | 15   | 45     |
| 8   | K8S - Nodes average CPU utilization in percent (Critical)     | >2     | >90       | 15   | 45     |
| 9   | K8S - Nodes average memory utilization in percent (Warning)   | >2     | >85       | 15   | 45     |
| 10  | K8S - Nodes average memory utilization in percent (Critical)  | >2     | >95       | 15   | 45     |
| 11  | K8S - Percent failing Pods is too high                        | >2     | >10       | 15   | 45     |
| 12  | K8S - Percent unknown Pods is too high                        | >2     | >30       | 15   | 45     |
| 13  | K8S - Cluster nodes disks free space used exceeded (Critical) | >2     | >90       | 15   | 45     |
| 14  | K8S - Cluster nodes disks free space used exceeded (Warning)  | >2     | >80       | 15   | 45     |

_Actiongroup_
| #   | Name                     | Short Name    | Target            |
| --- | :----------------------- | :------------ | :---------------- |
| 1   | k8srules-azmon-prod-agrp | k8srulesazmon | dummy@nowhere.com |



To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment:** Can be one of the following: dev-test-acc-prod.
- **AMLResourceGroup:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **AMLWorkspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AMLResourceGroup.
- **K8SClusterName:** The name of the Kubernets cluster that needs to be added to monitoring.
- **K8SResourceGroup:** The resource group in which the K8S cluster is located.
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


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-k8srules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
