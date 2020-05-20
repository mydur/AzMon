# azmon-nsgrules-tmpl

The purpose of this template is to deploy a set of alert rules to monitor NSG (Network Security Groups). Via this template it will be possible to create alert rules that watch for the number of times a NSG rule has been used. For example you can create an alert rule that checks the number of times a NSG rule for a given NSG has been used. If a threshold has been breached that alert rule will then generate an alert.

This template does not create alert rules that watch the Azure NSG service itself, that is covered by Azure Service Health.

All rules that need to be created are described in a JSON file that is called nsgrules.json by default. An example of such a json file is shown below.

```json
{
  "nsgrules": [
    {
      "NSGName": "azmonvm-prod-nsg",
      "NSGRGName": "azmonvm-prod-rg",
      "ActionGroupName": "nwrules-azmon-prod-agrp",
      "ActionGroupRGName": "azmon-prod-rg",
      "NSGRuleName": "DefaultRule_DenyAllInBound",
      "Direction": "In",
      "Type": "block",
      "IPV4": "10.10.100.4",
      "Subnet": "10.10.100.0//24",
      "Frequency": 15,
      "Threshold": 20,
      "Breach": 2,
      "Description": "Deny All InBound",
      "Log": ""
    },
    {
      "NSGName": "azmonvm-prod-nsg",
      "NSGRGName": "azmonvm-prod-rg",
      "ActionGroupName": "nwrules-azmon-prod-agrp",
      "ActionGroupRGName": "azmon-prod-rg",
      "NSGRuleName": "DefaultRule_DenyAllOutBound",
      "Direction": "Out",
      "Type": "block",
      "IPV4": "",
      "Subnet": "10.10.100.0/24",
      "Frequency": 15,
      "Threshold": 20,
      "Breach": 2,
      "Description": "Deny All OutBound",
      "Log": ""
    }
  ]
}
```

The Init-AzMon.ps1 powershell script that parses this json file will create two separate alert rules, one for each block. It will only do so if the Log value is empty, like it is in the example. When the powershell script finishes adding an alert rule for a block from the json file, it will modify the Log value so it indicates when the rule was added. A second run of the script based on the same nsgrules.json file will notice the Log value and skip all blocks with Log values other than blank.

Each block contains all information that is required to create the alert rule. The name of the alert rule is a combination of different values: _Network - NSG - [ NSG Rule Name ] for [IPV4 address **or** Subnet CIDR] on ([ NSG Name ])_

There's two types of rules that can be created, one is based on the IPV4 address and the other on Subnet (CIDR) notation. If the IPV4 value is empty then the script assumes that the Subnet value needs to be used. The name of the alert rule will be build accordingly and the section in the template responsible for the subnet alert rule will be used.

The decision on which alert rule the template will create is based on the IPV4 parameter of the template. If that parameter is empty then the subnet alert rule will be created, in all other cases the IPV4 alert rule will be created. Look for the following lines of code in the template.json file:

```json
"condition": "[not(empty(parameters('IPV4')))]",

"condition": "[empty(parameters('IPV4'))]",
```

Also the thresholds are part of the template.json parameters. It is important to know that the queries used in the alert rules contains an aggregate function that slices that dataset that is being looked at into 5 minute parts. The Frequency value in the nsgrules.json file is also used to select the dataset timeframe that is being looked at. So if a rule is evaluated every 15 minutes (Frequency=15) then the dataset used is also 15 minutes and this dataset is being sliced into 5 minutes parts. This is important to know for the Breach value. Breach indicates the minimum number of consecutive breaches of the Threshold value that need to be detected before an alert is raised. So a 15 minutes dataset (Frequency=15) sliced into 5 minutes parts (3 in total) cab have a maximum of 3 breaches. This also means that the highest number for Breach in this case is 2. Remember that a breach is only detected if the average value of the counter being looked at over a period of 1 slice/part (5 minutes) is higher than the given Threshold.

> **Note:** Each deployment of the template only creates a single alert rule corresponding to a block in the nsgruls.json file.

The destination resource group of the alert rules being created is the same resource group as where the NSG is located. That's why the NSG resource group name is one of the parameters. Notification is done, like for any other monitoring that is implemenetd, via an action group. There's a difference however, the action group is not created by the template for NSG monitoring. Parameters for action group name and name of the resource group hosting the action group have been added to the template. This results in the action group needing to be present before the template can be deployed.

To be able to re-use the template the following parameters were introduced:

- **NSGName:** Name of the Network Security Group.
- **NSGRuleName:** Name of the NSG rule to search for.
- **Description:** Description for the NSG rule name.
- **Direction:** Direction of the traffic. Can be _In_ or _Out_.
- **Type:** Type of action taken. Cn be _block_ or _allow_.
- **IPV4:** IPV4 address of the server to filter. This parameters is mutual exclusive with the Subnet parameter and has priority if both exist.
- **Subnet:** Subnet CIDR notation of the subnet to filter. This parameters is mutual exclusive with the IPV4 parameter and does not have priority if both exist.
- **Frequency:** The frequency at which the alert rule will execute the query against the log analytics database. The same value is used for the Period (data window).
- **Threshold:** Threshold value against which the query result is evaluated.
- **Breach:** Number of consecutive times that threshold should be reached before an alert is raised.
- **NSGAlertRuleName:** Name of the alert rule that will be created.
- **AZMONBasicRGName:** Resource group name where basic monitoring was deployed -=- PLEASE ONLY USE LOWER CASE AND NUMBERS -=-.
- **workspaceName:** Workspace name where basic monitoring is running -=- PLEASE ONLY USE LOWER CASE AND NUMBERS -=-.
- **actionGroupName:** Name of the action group to use for alert forwarding.
- **actionGroupRGName:** Name of the action group resource group to use for alert forwarding.
- **Environment:** Can one of the following, dev-test-acc-prod -=- PLEASE ONLY USE LOWER CASE AND NUMBERS -=-.
- **Project:**
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

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-nsgrules-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
