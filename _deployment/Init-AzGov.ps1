<#
	.SYNOPSIS
		Deploy the AzGov environment in Azure.
	
	.DESCRIPTION
		This script deploys all necessary resources and configuration for governance in Azure according to Getronics standards. It uses a parameters file of which the location can be passed to the script via a parameter.The Azure CLI is a requirement and can be automatically checked by using the CheckPrereqs (switch) parameter.
	
	.EXAMPLE
		Init-AzGov.ps1 -ParametersFile "C:\Getronics\AzGov\contorso123.json" -CheckPrereqs
		
		This command will use the contorso123.json file as parameter source and first check the prerequisites (Azure CLI) before starting the deployment.
		
	.PARAMETER ParametersFile
		Specifies the location of the JSON file containing the parameters values.
	
	.PARAMETER CheckPrereqs
		This is a switch parameter. If present then it indicates that prerequisites will be checked. If omitted then presence of Azure CLI is assumed.
	
	.NOTES
		Title:          Init-AzGov.ps1
		Author:         Rudy Michiels
                Created:        2019-09-23
                Version:        0.1
		ChangeLog:
			2019-09-23  Initial version
#>

##########################################################################
# PARAMS
##########################################################################
param (
        [string]$ParametersFile,
        [switch]$CheckPrereqs
)

##########################################################################
# PREREQS
##########################################################################
# Azure CLI install/update
New-Item -Path "C:\Getronics" -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path "C:\Getronics\AzGov" -ItemType Directory -ErrorAction SilentlyContinue
#Set-Location -Path "C:\Getronics\AzGov"
If ($CheckPrereqs) {
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile "C:\Getronics\AzGov\AzureCLI.msi"
        Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
}

##########################################################################
# VARIABLES
##########################################################################
# Being read from JSON file...
If (Test-Path $ParametersFile) {
        "The file $ParametersFile is present. Continuing..."
}
else {
        "The file $ParametersFile is NOT present. Quiting..."
        Exit
}
$ParametersJSON = Get-Content -Path $ParametersFile -Raw | ConvertFrom-Json
$CompanyName = $ParametersJSON.General.CompanyName
$CompanyDomain = $ParametersJSON.General.CompanyDomain
$TenantID = $ParametersJSON.General.TenantID
$Environment = $ParametersJSON.General.Environment
$TagEndsOn = $ParametersJSON.General.TagEndsOn
$TagCostCenter = $ParametersJSON.General.TagCostCenter
$LocationDisplayName = $ParametersJSON.General.LocationDisplayName
# Probably no change needed...
$AzGovLocalPath = "C:\Getronics\AzGov"
$GithubBaseFolder = "https://github.com/mydur/ARMtemplates/raw/master/"
$ResourceGroupName = "azgov-$Environment-rg"
$TagPoliciesJSONFile = ($AzGovLocalPath + "\tagpolicies.json")
$TagPoliciesSetdName = "azgov-tagpolicies-setd"
$TagPoliciesSetdDisplayName = "AzGov: Append default tags on resources and groups"
$TagPoliciesSetdDescription = "Append default tags to resource group and resources. Resources inherit tags of their resource group."
$TagPoliciesAssiName = "azgov-tagpolicies-assi"
$AutomationAccountJSONFile = ($AzGovLocalPath + "\automationaccount.json")
$AzCLIAadaName = "azcli-$Environment-aada"
$AzPSAadaName = "azps-$Environment-aada"
$AzCopyAadaName = "azcopy-$Environment-aada"
$AzAutoAadaName = "azauto-$Environment-aada"
$TagOwnedBy = "Getronics"
$TagCreatedOn = (Get-Date -Format "yyyyMMdd")
$TagEnvironment = $Environment
$TagProject = "AzGov"
$Rnd = (Get-Random -Maximum 9999 -Minimum 1000).ToString()
$ParametersJSON.General.UniqueNumber = "$Rnd"
$KeyVaultName = "azgov$Rnd-$Environment-keyv"
$StorAcctName = ("azgov$Rnd" + $Environment + "stor").ToLower()
$StorAcctSKU = "Standard_LRS"


##########################################################################
# DOWNLOAD TEMPLATE FILES
##########################################################################
$TemplateFile = "azgov-tagpolicies-tmpl/_working/tagpolicies.json"
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFile) | Out-File -FilePath $TagPoliciesJSONFile -Force
$TemplateFile = "azgov-autoacct-tmpl/_working/automationaccount.json"
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFile) | Out-File -FilePath $AutomationAccountJSONFile -Force

##########################################################################
# 0. LOGIN TO AZURE
##########################################################################
# All activities in the script are executed via Azure CLI and thus we only need to login to AzCLI. The method we use is via --use-device-code and the link to use in your browser is given in the same message as where the device-code can be found. Make sure to use an account that has been given rights in the tenant because user id's (service principal) will be created. The roles required by this script in the tenant are 'Global administrator' and 'Service administrator'. You can have a look at the following two pages for more information about roles in AAD: https://docs.microsoft.com/en-us/azure/role-based-access-control/rbac-and-directory-admin-roles and https://docs.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin.
#
# Also, because policies will be assigned you need Owner rights to the subscription that is used. Make sure you are member of that role before you start the script.
$CurrentCLIUser = (az ad signed-in-user show) | ConvertFrom-Json
If ($CurrentCLIUser) {
        ("Continuing with user " + $CurrentCLIUser.userPrincipalName + " (press CTRL+C to abort and logout with az logout before restarting)")
        Start-Sleep -Seconds 10
        $UserDisplayName = $CurrentCLIUser.displayName
        $CurrentCLIUserAccount = (az account show) | ConvertFrom-Json
        $SubscriptionID = $CurrentCLIUserAccount.id
        $SubscriptionName = $CurrentCLIUserAccount.name
}
else {
        $Login = (az login `
                        --tenant "$TenantID" `
                        --use-device-code) `
        | ConvertFrom-Json
        $SubscriptionID = $Login.id
        $SubscriptionName = $Login.name
        $UserDetails = (az ad signed-in-user show) | ConvertFrom-Json
        If ($UserDetails) {
                $UserDisplayName = $UserDetails.displayName
        }
        else {
                $UserDisplayName = $Login.user.name
        }
}
$Location = (Get-AzLocation | ? { $_.DisplayName -eq "$LocationDisplayName" }).Location

##########################################################################
# MAIN
##########################################################################
# 1. CREATE THE POLICY SET DEFINITION (ALSO CALLED INITIATIVE)
# ------------------------------------------------------------
# A guideline for the --name parameter is azgov-<short description>-setd. Try to avoid blanks in the name and use the --display-name parameter for more detailed naming. The --name parameter is never shown in the Azure portal. The --subscription parameter is filled in with data from the login command. Finally the --definitions parameter contains the full or relative path to the json with the set definition in it.
$CreateSetDefinition = (az policy set-definition create `
                --name "$TagPoliciesSetdName" `
                --display-name "$TagPoliciesSetdDisplayName" `
                --description "$TagPoliciesSetdDescription" `
                --subscription "$SubscriptionID" `
                --definitions "$TagPoliciesJSONFile") `
| ConvertFrom-Json
("Policy set-definition ID: " + $CreateSetDefinition.id)
$ParametersJSON.Outputs.GovSetDefId = $CreateSetDefinition.id

# 2. CREATE AN ASSIGNMENT FOR THE INITIATIVE
# ------------------------------------------
# The set-defintion or initiative that was just created is assigned to a scope via this command. Same rules as before apply here for the --name azgov-<short description>-assi. The --policy-set-definition parameter contains the id for the set definition that was just created and is constructed with data from the creation result. In this case the --scope is a subscription, hence the naming that is used. Note that the --display-name parameter contains a reference to the name of your subscription. This subscription name is retrieved from the login command returned data.
$AssignmentDisplayName = "AzGov: Append default tags on resources and groups in subscription ($SubscriptionName)"
$CreateAssignment = (az policy assignment create `
                --name $TagPoliciesAssiName `
                --display-name $AssignmentDisplayName `
                --policy-set-definition "/subscriptions/$SubscriptionID/providers/Microsoft.Authorization/policySetDefinitions/$TagPoliciesSetdName" `
                --scope "/subscriptions/$SubscriptionID") `
| ConvertFrom-Json
("Assignment ID: " + $CreateAssignment.id)
$ParametersJSON.Outputs.GovAssignmentId = $CreateAssignment.id

# 3. CREATE A RESOURCE GROUP FOR ALL AZGOV RESOURCES
# --------------------------------------------------
# The following command creates a resource group to store all AzGov related resources that need to be hosted in a resource group. 
$ResourceGroup = (az group create `
                --location "$Location" `
                --name "$ResourceGroupName" `
                --subscription "$SubscriptionID" `
                --tags CreatedBy="$UserDisplayName" OwnedBy="$TagOwnedBy" CostCenter="$TagCostCenter" CreatedOn="$TagCreatedOn" EndsOn="$TagEndsOn" Environment="$TagEnvironment" Project="$TagProject") `
| ConvertFrom-Json
("Resource Group: " + $ResourceGroup.id)
$ParametersJSON.Outputs.GovResGroupId = $ResourceGroup.id

# 4. CREATE A KEY VAULT
# ---------------------
# This keyvault will be used to store all AzGov related secrets and certificates. By default the user that creates the vault gets assigned an access policy to manage all types of keys stored in the vault. Other users will have to be granted a specific access policy for their tasks.
$KeyVault = (az keyvault create `
                --location "$Location" `
                --name "$KeyVaultName" `
                --subscription "$SubscriptionID" `
                --resource-group "$ResourceGroupName" `
                --enable-soft-delete true `
                --enabled-for-deployment true `
                --enabled-for-template-deployment true) `
| ConvertFrom-Json
("Keyvault: " + $Keyvault.id)
$KeyvaultID = $Keyvault.id
$KeyvautLock = (az resource lock create `
                --lock-type CanNotDelete `
                --name "azgov-keyvaultND-lock" `
                --resource "$KeyVaultName" `
                --resource-group "$ResourceGroupName" `
                --resource-type "Microsoft.KeyVault/vaults") `
| ConvertFrom-Json
$ParametersJSON.Outputs.GovKeyvaultId = $KeyvaultID
#
#
# 5. CREATE SERVICE PRINCIPALS
# ----------------------------
# AZCOPY
$AzCopyAada = (az ad sp create-for-rbac `
                --name "$AzCopyAadaName" `
                --years 3) `
| ConvertFrom-Json
($AzCopyAada.displayName + ": " + $AzCopyAada.appId)
$AzCopyAadaKeyv = (az keyvault secret set `
                --vault-name "$KeyvaultName" `
                --name "$AzCopyAadaName" `
                --description "Password" `
                --value $AzCopyAada.password) `
| ConvertFrom-Json
($AzCopyAada.displayName + " keyvault secret: " + $AzCopyAadaKeyv.id)
$AzCopyAadaSP = (az ad sp show `
                --id $AzCopyAada.name) `
| ConvertFrom-Json
$AzCopyAadaKeyvPol = (az keyvault set-policy `
                --name $Keyvault.name `
                --resource-group $ResourceGroup.name `
                --object-id $AzCopyAadaSP.objectId `
                --spn "$AzCopyAadaName" `
                --secret-permissions get list `
                --storage-permissions get getsas list listsas `
                --certificate-permissions get getissuers list listissuers `
                --key-permissions get list) `
| ConvertFrom-Json
# AZCLI
$AzCLIAada = (az ad sp create-for-rbac `
                --name "$AzCLIAadaName" `
                --role Owner `
                --years 3) `
| ConvertFrom-Json
($AzCLIAada.displayName + ": " + $AzCLIAada.appId)
$AzCLIAadaKeyv = (az keyvault secret set `
                --vault-name "$KeyvaultName" `
                --name "$AzCLIAadaName" `
                --description "Password" `
                --value $AzCLIAada.password) `
| ConvertFrom-Json
($AzCLIAada.displayName + " keyvault secret: " + $AzCLIAadaKeyv.id)
$AzCLIAadaSP = (az ad sp show `
                --id $AzCLIAada.name) `
| ConvertFrom-Json
$AzCLIAadaKeyvPol = (az keyvault set-policy `
                --name $Keyvault.name `
                --resource-group $ResourceGroup.name `
                --object-id $AzCLIAadaSP.objectId `
                --secret-permissions backup, delete get list purge recover restore set `
                --storage-permissions backup delete deletesas get getsas list listsas purge recover regeneratekey restore set setsas update `
                --certificate-permissions backup create delete deleteissuers get getissuers import list listissuers managecontacts manageissuers purge recover restore setissuers update `
                --key-permissions backup create decrypt delete encrypt get import list purge recover restore sign unwrapKey update verify wrapKey) `
| ConvertFrom-Json
# AZPS
$AzPSAada = (az ad sp create-for-rbac `
                --name "$AzPSAadaName" `
                --role Owner `
                --years 3) `
| ConvertFrom-Json
($AzPSAada.displayName + ": " + $AzPSAada.appId)
$AzPSAadaKeyv = (az keyvault secret set `
                --vault-name "$KeyvaultName" `
                --name "$AzPSAadaName" `
                --description "Password" `
                --value $AzPSAada.password) `
| ConvertFrom-Json
($AzPSAada.displayName + " keyvault secret: " + $AzPSAadaKeyv.id)
$AzPSAadaSP = (az ad sp show `
                --id $AzPSAada.name) `
| ConvertFrom-Json
$AzPSAadaKeyvPol = (az keyvault set-policy `
                --name $Keyvault.name `
                --resource-group $ResourceGroup.name `
                --object-id $AzPSAadaSP.objectId `
                --secret-permissions backup, delete get list purge recover restore set `
                --storage-permissions backup delete deletesas get getsas list listsas purge recover regeneratekey restore set setsas update `
                --certificate-permissions backup create delete deleteissuers get getissuers import list listissuers managecontacts manageissuers purge recover restore setissuers update `
                --key-permissions backup create decrypt delete encrypt get import list purge recover restore sign unwrapKey update verify wrapKey) `
| ConvertFrom-Json
# AZAUTO
$AzAutoAada = (az ad sp create-for-rbac `
                --name "$AzAutoAadaName" `
                --years 3) `
| ConvertFrom-Json
($AzAutoAada.displayName + ": " + $AzAutoAada.appId)
$AzAutoAadaKeyv = (az keyvault secret set `
                --vault-name "$KeyvaultName" `
                --name "$AzAutoAadaName" `
                --description "Password" `
                --value $AzAutoAada.password) `
| ConvertFrom-Json
($AzAutoAada.displayName + " keyvault secret: " + $AzAutoAadaKeyv.id)
$AzAutoAadaSP = (az ad sp show `
                --id $AzAutoAada.name) `
| ConvertFrom-Json
$AzAutoAadaKeyvPol = (az keyvault set-policy `
                --name $Keyvault.name `
                --resource-group $ResourceGroup.name `
                --object-id $AzAutoAadaSP.objectId `
                --secret-permissions get list `
                --storage-permissions get getsas list listsas `
                --certificate-permissions get getissuers list listissuers `
                --key-permissions get list) `
| ConvertFrom-Json
#
#
# 6. STORAGE ACCOUNT
# ------------------
# This storage account can be used to store all things related to managing an Azure environment. To start this storage account doesn't contain any data.
$StorAcct = (az storage account create `
                --name "$StorAcctName" `
                --resource-group "$ResourceGroupName" `
                --location "$Location" `
                --sku "$StorAcctSKU" `
                --https-only true `
                --access-tier Cool `
                --kind StorageV2) `
| ConvertFrom-Json
("Storage account: " + $StorAcct.id)
$StorAcctID = $StorAcct.id
$StorAcctLock = (az resource lock create `
                --lock-type CanNotDelete `
                --name "azgov-storacctND-lock" `
                --resource "$StorAcctName" `
                --resource-group "$ResourceGroupName" `
                --resource-type "Microsoft.Storage/storageAccounts") `
| ConvertFrom-Json
$ParametersJSON.Outputs.GovStorAcctId = $StorAcctID
#
#
# 7. AUTOMATION ACCOUNT
# ---------------------
# This is the automation account that will be used to run automation scripts used for governance. To start this automation account doesn't contain any runbooks.
$AutoAcct = (az group deployment create `
                --resource-group "azgov-prod-rg" `
                --template-file "c:\getronics\azgov\automationaccount.json" `
                --name "azgov-automationacct" `
                --parameters "Environment=$Environment" "Location=$Location" "UniqueNumber=$Rnd") `
| ConvertFrom-Json
("Automation Account: " + $AutoAcct.id)
$ParametersJSON.Outputs.GovAutoAcctId = $AutoAcct.id
#
# The next line outputs the ParametersJSON variable, that was modified with some output data from the template deployments, backup to its original .json parameter file.
$ParametersJSON | ConvertTo-Json | Out-File -FilePath "$ParametersFile" -Force -Encoding ascii