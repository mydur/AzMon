# azmon-vault-tmpl

What we do with this temlate is adding a list of virtual machines to the backup. This template uses an existing vault and backup policy. Only single resource type is created and it's called Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems.

As in any other template we try to avoid using resource Id's in the parameter fields. Also in this template friendly names are expected as input parameters and the resourceId() function in the template is responsible for retrieveing the full resource Id and pass it to the configuration items.

The sourceResourceId configuration item can only handle a single virtual machine at a time. In the parameters however we have the existingVirtualMachines parameter who can handle multple virtual machines at the same time. The way this works is that you provide the name of each virtual machine between double quotes and all virtual machine name should be separated by a comma. Example: ["vm01", "vm02"]

To be able to re-use this template the following parameters were introduced.

- Project: An inidicator string for the customer or project that this will be used for. What you enter here will be used in tags but also in the names for the different resources that are created.
- Environment: The environment for which the resources can be used. Allowed values are dev-test-acc-prod.
- existingVirtualMachinesResourceGroup: Resource group where the virtual machines are located. This can be different from resource group of the vault.
- existingVirtualMachines: Array of Azure virtual machines. e.g. ["vm1","vm2","vm3"]
- existingRecoverservicesVault: Recovery services vault name where the VMs will be backed up to.
- existingBackupPolicy: Backup policy to be used to backup VMs. Backup Policy defines the schedule of the backup and how long to retain backup copies. By default every vault comes with a 'DefaultPolicy' which canbe used here.
- location: Location for all resources. Default value here is the same location as the resource group where the template is deployed.

Looping through the list of virtual machines can be done by the copy instruction in the resource definition. The number of times the loop is executed is determined via count instruction which is part of the copy instruction. The count is then determined by the length of the existingVirtualMachines parameter.

> Remark:
> There's a prerequisite for this template to work. All virtual machines listed in the parameter need to be in the same resource group which is also available as a parameter.

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmydur%2FARMtemplates%2Fmaster%2Fazmon-vmbkup-tmpl%2F%5Fworking%2Ftemplate.json" target="_blank">
<img src="http://azuredeploy.net/deploybutton.png"/>
</a><br />
