# azmon-tagpolicies-tmpl

As you probably already know you should use tags on Azure resources to make you life easier. They can be very helpful in scenarios like the ones listed below:

- Filter the costs based on tag like Division, Owner, Environment
- Retrieve ownership of certain resouces
- List resources or resource groups that are passed their end date

Although the existence of a tag can be enforced via a default value, it will always be the responsibility of operations or project staff to put the correct value in the tag.

This template will enforce the following tags with a default value on resource groups and contained resources.

- OwnedBy

The way this works is that for example the Default value for the OwnedBy tag on a resource group is set at creation of the resource group. Should you specify yourself a different value at creation then the default value will not be applied. All resource groups that were created before activation of the policy will not receive the OwnedBy tag and accompanying value until the resource group is updated and that resource group didn't already have a OwnedBy tag. For each tag there's a second policy that sets the value of the tag for the resource to the same value as used for the resource groups. This means that every resource, created in a resource group with a given value for the OwnedBy tag, will receive that same value in its OwnedBy tag.

The scope for all policies set via this template is the subscription to which the template is deployed.

Parameters are not required for this template.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-tagpolicies-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
