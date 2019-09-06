<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionId
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    The resource group where the template will be deployed. Can be the name of an existing or a new resource group.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER deploymentName
    The deployment name.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER parametersFilePath
    Optional, path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
#>

param(
    [Parameter(Mandatory = $True)]
    [string]
    $subscriptionId,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [string]
    $resourceGroupLocation,

    [Parameter(Mandatory = $True)]
    [string]
    $deploymentName,

    [string]
    $templateFilePath = "template.json",

    [string]
    $parametersFilePath = "parameters.json",

    [string]
    $workspaceName = "azmon-test-lana",

    [string]
    $workspaceRGName = "azmon-test-rg"
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
    Param(
        [string]$ResourceProviderNamespace
    )

    Write-Host "Registering resource provider '$ResourceProviderNamespace'";
    Register-AzResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

# sign in
Write-Host "Logging in...";
#Login-AzureRmAccount;

# select subscription
Write-Host "Selecting subscription '$subscriptionId'";
Select-AzSubscription -SubscriptionID $subscriptionId;

# Register RPs
$resourceProviders = @("microsoft.automation", "microsoft.operationalinsights", "microsoft.operationsmanagement", "microsoft.storage");
if ($resourceProviders.length) {
    Write-Host "Registering resource providers"
    foreach ($resourceProvider in $resourceProviders) {
        RegisterRP($resourceProvider);
    }
}

#Create or check for existing resource group
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
    if (!$resourceGroupLocation) {
        $resourceGroupLocation = Read-Host "resourceGroupLocation";
    }
    Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
    New-AzResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
}
else {
    Write-Host "Using existing resource group '$resourceGroupName'";
}

# Start the deployment
Write-Host "Starting deployment...";
if (Test-Path $parametersFilePath) {
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath -TemplateParameterFile $parametersFilePath;
}
else {
    New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName -TemplateFile $templateFilePath;
}


Write-Host "Starting policy assignment..."
$policyDef = Get-AzPolicyDefinition -Id '/providers/Microsoft.Authorization/policyDefinitions/0868462e-646c-4fe3-9ced-a733534b6a2c' -ApiVersion "2019-01-01"
$assignmentDisplayName = 'AzMon: Deploy Log Analytics Agent for Windows VMs in ' + $resourceGroupName
$workspaceResourceId = (Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceRGName -Name $workspaceName).ResourceId
$policyParams = @{'logAnalytics' = $workspaceResourceId }
$policyParams
$assignment = New-AzPolicyAssignment -Name ('DeployWinMMA(' + $resourceGroupName + ')') -DisplayName $assignmentDisplayName -Scope $resourceGroup.ResourceId -PolicyDefinition $policyDef -Location $resourceGroupLocation -PolicyParameterObject $policyParams -AssignIdentity -ApiVersion "2019-01-01"
$assignment
Write-Host "Waiting for AAD replication..."
Start-Sleep 60
Write-Host "Starting managed identity work..."
$roleDefinitionIds = $policyDef.Properties.policyRule.then.details.roleDefinitionIds
$roleDefinitionIds
if ($roleDefinitionIds.Count -gt 0) {
    $roleDefinitionIds | ForEach-Object {
        $roleDefId = $_.Split("/") | Select-Object -Last 1
        New-AzRoleAssignment -Scope $resourceGroup.ResourceId -ObjectId $assignment.Identity.PrincipalId -RoleDefinitionId $roleDefId
    }
}
