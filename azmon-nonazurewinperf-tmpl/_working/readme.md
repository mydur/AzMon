# azmon-nonazurewinperf-tmpl

The purpose of this template is to deploy performance counter based alert rules for Non-Azure VMs. Two rules will be deployed, one for Critical alert level and the other for Warning alert level. Both alert rules will be of the metric measurement type which means that an alert is generated for each computer that falls within the defined criteria. Performance object, counter and instance can be specified via parameters as well as the critical and warning thresholds. Filtering is not possible which means that all NonAzure VMs will be affected by the rules.

The target resource group for the deployment is the resource group containing the base resources for the service (probably azmon-prod-rg).

To be able to re-use the template the following parameters were introduced:

- **perfObject:** Performance object to monitor (ex. Processor).
- **perfCounter:** Performance counter to monitor (ex. % Processor Time).
- **perfInstance:** Performance instance to monitor (ex. _Total).
- **warningThreshold:** Threshold for the warning alert.
- **criticalThreshold:** THreshold for the critical alert.
- **WorkspaceRGName:** The resource group in which the log analytics workspace was installed by the azmon-basic-tmpl template.
- **WorkspaceName:** The actual name of the log analytics workspace that can be found in the resource group of which the name is stored in AZMONBasicRGName.
- **actionGroupName:** The name of the action group to use when an alert has to be forwarded. Please note that this action group needs to exist before deploying the template.
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


<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-nonazurewinperf-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
