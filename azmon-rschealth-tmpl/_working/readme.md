# azmon-rschealth-tmpl

The purpose of this template is to put all resources (alert rules and action groups) in place to monitor health of resources. Not every type of Azure resource emits health information but for those types who do this is an easy way to be kept aware of the health state of your individual resources. More information on Azure resource health can be found here.

To trigger notification of a certain health state we use alert rules that react on a configured criteria. Besides the criteria, which will be detailed later, we also need to target the alert rules. There's 3 options to target a resource health alert rule:

- Subscription level
- Resourcegroup level
- Resource level

Targetting at subscription level would probably be too wide as a target and would probably raise alerts for resources we don't want to monitor. On the other side there's the resource as a target for the alert rule. Although this is the most granular level to target the alert rules, it would also create too much overhead in management because of the number of alert rules that need to be created. The most efficiënt way to create an acceptable signal to noise ration is to target to resource groups. Resource groups can be used for different purposes like resource groups per:

- Application
- Project
- Customer
- Environment (TDAP)

Following resource types are created by the template:

- Alert Rules
- Action Group(s)

All resources are created in the same resource group as the one that is used as target. By doing this we link the lifecycle of the resources created by this template to the lifecycle of the resource group and its resources. Suppose you delete the resource group then the alert rules and action groups will also be deleted. This is expected behavior because rules monitoring health of resouces in a non-existong resource group have no reason of existence.

To be able to re-use the template the following parameters were introduced:

- **Project:** An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- **Environment** The environment for which the resources can be used. Allowed values are dev-test-acc-prod.
- **CreatedOn** This paramters is in fact a variable that holds the current date and time to be added as a tag to the resources created by this template. Because of technical reasons this has to be a parameter and not a variable. The default value for the parameter is the outcome of the function [utcNow()].

> Earlier versions of the template (before v1.0.5) also had parameters for action group (short and long) and email address. These parameters have been removed to comply to the way we will use action groups together with Servicenow.

Tags are very important in Azure Governance as they help you in filtering the resources you're using. Resources created by this template get the following tags of which the values are stored in a variable with the same name:

- **TemplateId** String identifier for the current template. (azmon-basic)
- **TemplateVersion** Version of the template.
- **CreatedOn** Current timestamp.
- **Project** Project, customer or application identifier.
- **Environment** The environment for which the resources can be used.
- **EndsOn:** This parameter provides an indication of when the created resource should be end-of-life. It helps when cleaning up your Azure resources to have an idea when a resource isn't used anymore. The format of the date provided is yyyymmdd. When there's no end date available you should use 99999999.
- **CreatedBy:** A free text field to provide information about the person or team that created the resource. Isn't to be confused with the OwnedBy field.
- **OwnedBy:** A free text field to provide information about the person or team that owns the resource. Isn't to be confused with the CreatedBy field.

> As you probably noticed the resource group that holds the resources that need to be monitored is not part of the parameters. That's because the resources are created in the target resource group and thus the name of the resource group can be retrieved by a function in JSON.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-rschealth-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
