<# 
	.SYNOPSIS
		Deploy the AzMon environment in Azure.
	
	.DESCRIPTION
		This script deploys all necessary resources and configuration for monitoring in Azure according to Getronics standards. It uses a parameters file of which the location can be passed to the script via a parameter.The Azure CLI is a requirement and can be automatically checked by using the CheckPrereqs (switch) parameter.
	
	.EXAMPLE
		Init-AzMon.ps1 -ParametersFile "C:\Getronics\contorso123.json" -CheckPrereqs
		
		This command will use the contorso123.json file as parameter source and first check the prerequisites (Azure CLI) before starting the deployment.
		
	.PARAMETER ParametersFile
		Specifies the location of the JSON file containing the parameters values.
	
	.PARAMETER CheckPrereqs
                This is a switch parameter. If present then it indicates that prerequisites will be checked. If omitted then presence of Azure CLI is assumed.
                
        .PARAMETER DeployBaseSetup
                This is a switch that indicates that the base monitoring setup has to be deployed. Can be used alone or in conjunction with -AddVMResGroup.
        
        .PARAMETER AddVMResGroup
                This is a switch that indicates that the part of AzMon that has to be used for each resource group containing virtual machines that need to be monitored will also be deployed. Can be used in conjunction with -DeployBaseSetup or alone.
        
        .PARAMETER IncludeVMBkUp
                This switch indicates that the template deployment to configure virtual machine backup also takes place. Make sure the list of virtual machines to add to the backup is correct. If one of the virtual machines listed in the parameters file has not been deployed yet the template deployment will fail at that machine. All other virtual machines listed before the missing one will be added to the backup.
         
        .PARAMETER NonAzureVMs
                This switch indicates that the rules to monitor non-Azure VMs will be deployed to the same resource group as where the workspace is hosted.

        .PARAMETER IncludeLinux
                This switch indicates that the rules to monitor non-Azure VMs will be deployed to the same resource group as where the workspace is hosted.

        .PARAMETER IncludeDRM
                This switch indicates that the delegated rights for azgov-prod-rg and azmon-prod-rg should be enabled (Azure Lighthouse). DRM stands for Delegated Resource Management.
	
        .PARAMETER IncludeK8S
                This switch indicates that the monitoring for a Kubernetes cluster should be enabled and configured.
	
	.NOTES
		Title:          Init-AzMon.ps1
		Author:         Rudy Michiels
                Created:        2019-10-17
                Version:        0.4
		ChangeLog:
                        2019-09-26      Initial version
                        2019-09-30      Added -IncludeVMBkUp switch parameter
                        2019-10-17      Added -NonAzureVMs switch parameter
                        2019-10-25      Added -IncludeLinux switch parameter  
                        2019-12-20      Added -IncludeK8S switch parameter 
#>

##########################################################################
# PARAMS
##########################################################################
param (
        [string]$ParametersFile,
        [switch]$CheckPrereqs,
        [switch]$DeployBaseSetup,
        [switch]$AddVMResGroup,
        [switch]$IncludeVMBkUp,
        [switch]$NonAzureVms,
        [switch]$IncludeLinux,
        [switch]$IncludeDRM,
        [switch]$IncludeK8S,
        [switch]$IncludeASR,
        [switch]$Update
)

##########################################################################
# PREREQS
##########################################################################
# Azure CLI install/update
New-Item -Path "C:\Getronics" -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path "C:\Getronics\AzMon" -ItemType Directory -ErrorAction SilentlyContinue
Set-Location -Path "C:\Getronics\AzMon"
If ($CheckPrereqs) {
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile "C:\Getronics\AzMon\AzureCLI.msi"
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
$ParametersJSON = Get-Content -Path "$ParametersFile" -Raw | ConvertFrom-Json
$CompanyName = $ParametersJSON.General.CompanyName
$CompanyDomain = $ParametersJSON.General.CompanyDomain
$TenantID = $ParametersJSON.General.TenantID
$Environment = $ParametersJSON.General.Environment
$TagEndsOn = $ParametersJSON.General.TagEndsOn
$TagCostCenter = $ParametersJSON.General.TagCostCenter
$UniqueNumber = $ParametersJSON.General.UniqueNumber
$LocationDisplayName = $ParametersJSON.General.LocationDisplayName
$VMResourceGroupName = $ParametersJSON.VMRules.VMRGName
$dataPerDayThresholdMB = $ParametersJSON.Basic.dataPerDayThresholdMB
# Probably no change needed...
$ResourceGroupName = ("azmon-$Environment-rg").ToLower()
$WorkspaceName = $ParametersJSON.Outputs.workspaceName
$KeyvaultName = "azgov$UniqueNumber-$Environment-keyv"
$KeyvaultRGName = "azgov-$Environment-rg"
$AzMonAadaName = "azmon-$Environment-aada"
$TagOwnedBy = "Getronics"
$TagCreatedOn = (Get-Date -Format "yyyyMMdd")
$TagEnvironment = $Environment
$TagProject = "AzMon"
$AzMonLocalPath = "C:\Getronics\AzMon"
$GithubBaseFolder = "https://github.com/mydur/ARMtemplates/raw/master/"
$VMWorkbookName = "azmon-$Environment-wbok"
$RBOKAlertLifeCycleAckThreshold = 3     # Number of days without changes after which alert is set to Acknowledged
$RBOKAlertLifeCycleCloseThreshold = 20  # Number of days without changes after which alert is set to Closed


##########################################################################
# DOWNLOAD TEMPLATE FILES
##########################################################################
$TemplateFolder = "azmon-basic-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-basicrules-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-svchealth-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-nwrules-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-vmworkbook-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-backupsol-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-vmrules-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-nonazurevms-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-rschealth-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-vault-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-vmbkup-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/parameters.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\parameters.json") -Force -Encoding ascii
$TemplateFolder = "azmon-delegatedrights-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/parameters.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\parameters.json") -Force -Encoding ascii
$TemplateFolder = "azmon-delegatedvmrights-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/parameters.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\parameters.json") -Force -Encoding ascii
$TemplateFolder = "azmon-vmlinuxrules-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-basiclinux-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-k8srules-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
$TemplateFolder = "azmon-asrrules-tmpl/_working"
New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
# Runbooks
New-Item -Path ($AzMonLocalPath + "\_deployment") -ItemType Directory -ErrorAction SilentlyContinue
$FileName = "azmon-alertlifecycle-rbok.ps1"
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + "_deployment/" + $FileName) | Out-File -FilePath ($AzMonLocalPath + "\_deployment\" + $FileName) -Force -Encoding ascii
#
##########################################################################
# LOGIN TO AZURE
##########################################################################
#
# Throughout the script we use 2 ways of connecting to Azure, via Azure CLI (az commands) and via Powershell. In this section of the script we login to both parties. The AzCLI login is interactive and uses the --use-device-code option. Make sure to use an account that has been given rights in the tenant (AAD) because user id's (service principal) will be created. The roles required in the tenant are 'Global administrator' and 'Service administrator'. You can have a look at the following two pages for more information about roles in AAD: https://docs.microsoft.com/en-us/azure/role-based-access-control/rbac-and-directory-admin-roles and https://docs.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin. 
#
# The 2nd login, Powershell, uses a service principal that was created by the AzGov script. In the current version of the script there's no error checking and thus the script will show you errors when the service principal was not previously created and its secret stored in the keyvault. The service principal that is used here to do a automatic login is azps-<environment>-aada. For a prod environment this would be azps-prod-aada. Azure commandline, which is logged into first, will be used to retrieve the secret (password) from the keyvault. So make sure that the account used to login to Azure CLI has been given rights (access policy) to the keyvault or the retrieval will fail.
#
# Also, because policies will be assigned you need Owner rights to the subscription that is used. Make sure you are member of that role before you start the script.
$CurrentCLIUser = (az ad signed-in-user show) | ConvertFrom-Json
If ($CurrentCLIUser) {
        ("Continuing with user " + $CurrentCLIUser.userPrincipalName + " (press CTRL+C to abort and logout with az logout before restarting)")
        Start-Sleep -Seconds 5
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
        $UserNameUPN = $Login.user.name
        $UserDetails = (az ad user show `
                        --id "$UsernameUPN") `
        | ConvertFrom-Json
        If ($UserDetails) {
                $UserDisplayName = $UserDetails.displayName
        }
        else {
                $UserDisplayName = $Login.user.name
        }
}
$AzPSAadaKeyv = (az keyvault secret show `
                --vault-name $KeyvaultName `
                --name ("azps-" + $Environment + "-aada")) `
| ConvertFrom-Json
$AzPSAadaSecret = $AzPSAadaKeyv.value
$Pwd = ConvertTo-SecureString "$AzPSAadaSecret" -AsPlainText -Force
$PSCreds = New-Object System.Management.Automation.PSCredential(("http://azps-" + $Environment + "-aada"), $Pwd)
Connect-AzAccount -ServicePrincipal -Credential $PSCreds -Tenant $TenantID
$SubscriptionID = $Login.id
$SubscriptionName = $Login.name
$Location = (Get-AzLocation | ? { $_.DisplayName -eq "$LocationDisplayName" }).Location
#
##########################################################################
# Update
##########################################################################
#
If ($Update) {

}
##########################################################################
# DeployBaseSetup
##########################################################################
# This part of the script deploys the base setup of AzMon. Actual delployments are doen via ARM templates and deployments are started via AzCLI commands. The following templates are being deployed here:
#       - azmon-basic-tmpl
#       - azmon-svchealth-tmpl
#       - azmon-nwrules-tmpl
#       - azmon-vmworkbook-tmpl
#       - azmon-backupsol-tmpl
# The location of these templates is fixed in the script and the location starts with C:\Getronics\AzMon. Under this folder there should be a subfolder for each template. For the 1st one in the list this would then be C:\Getronics\AzMon\azmon-basic-tmpl. Below that folder there should be a '_working' folder that contains the actual template file. The process is the same for every template in the list. This folder setup is also used during developoment of the templates. In future versions we will probably get the templates from Github.
#
# Besides the templates there's 2 other type of activities that are executed:
#       - Creation of a resource group
#       - Creation of a service principal for AzMon
# The name of the resource group is constructed from the Project and Environment variables. If the project is AzMon and environment is Prod then the resource group will be called azmon-prod-rg. This resource group should be used to group all base resources and not the actual resources that need to be monitored.
#
# NOTE: Keep the name of the project as short as possible or leave it to AzMon when monitoring is independent of projects.
# NOTE: Re-deployment of the base setup with the same project and environment combination will fail if deployed in the same subscription.
#
# Finally the service principal is created and given Contributor rights to the subscription. This service principal can be used by monitoring in case remediation tasks need to be executed. In the current version of the solution there's no such tasks yet.
#
If ($DeployBaseSetup) {
        #
        # RESOURCE GROUP
        # -----------------
        # Assuming that the AzGov has also been deployed via the provided script a set of policies were introduced to add tags to resources and resource groups. Because of these policies resources in a resource group will inherit the values set in the tags on the resource group. That's why the creation of the resource group also adds tag values so they can be inherited by the resources created later in the group.
        $ResourceGroup = (az group create `
                        --name "$ResourceGroupName" `
                        --location "$Location" `
                        --tags `
                        "CostCenter=$TagCostCenter" `
                        "CreatedBy=$userDisplayName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "Environment=$TagEnvironment" `
                        "OwnedBy=$TagOwnedBy" `
                        "Project=$TagProject") `
        | ConvertFrom-Json
        ("Resource Group: " + $ResourceGroup.id)
        #
        #
        # BASIC (azmon-basic-tmpl)
        # ---------------------------
        # The purpose of this template is to deploy a basic setup of Azure Monitor. It contains the following resources:
        # - Log Analytics workspace
        # - Automation Account
        # - Storage Account
        # For the storage account and automation account there's no initial configuration but the log analytics workspace has initial configurations set in the template for the following:
        # - Datasources
        # - Saved searches
        # - Solutions
        # - Linked services
        # The template also contains an 'outputs' section of which the output is captured in variables listed below.
        ("azmon-basic-tmpl...")
        $WorkspaceDataRetention = $ParametersJSON.Basic.WorkspaceDataRetention
        $AzMonBasic = (az group deployment create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-basic-tmpl\_working\template.json") `
                        --name "azmon-basic" `
                        --parameters `
                        "Project=$TagProject" `
                        "VMRGName=$VMResourceGroupName " `
                        "Environment=$Environment" `
                        "dataRetention=$WorkspaceDataRetention" `
                        "Location=$LocationDisplayName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy" `
                        "UniqueNumber=$UniqueNumber") `
        | ConvertFrom-Json
        ("azmon-basic-tmpl: " + $AzMonBasic.properties.provisioningState + " (" + $AzMonBasic.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonBasicTmpl = $AzMonBasic.properties.provisioningState
        $WorkspaceName = $AzMonBasic.properties.outputs.workspacename.value
        $ParametersJSON.Outputs.workspaceName = $WorkspaceName
        $WorkspaceId = $AzMonBasic.properties.outputs.workspaceid.value
        $ParametersJSON.Outputs.workspaceID = $WorkspaceId
        $StorAcctName = $AzMonBasic.properties.outputs.storageaccountname.value
        $ParametersJSON.Outputs.storAcctName = $StorAcctName
        $AutoAcctName = $AzMonBasic.properties.outputs.automationaccountname.value
        $ParametersJSON.Outputs.autoAcctName = $AutoAcctName
        $AutoAcctId = $AzMonBasic.properties.outputs.automationaccountid.value
        #
        # AUTOMATION RUNBOOKS
        # -------------------
        # General configuration
        New-AzAutomationVariable -Name "General_SubscriptionId" -Value $SubscriptionId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $False
        New-AzAutomationVariable -Name "General_TenantId" -Value $TenantId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $False
        New-AzAutomationVariable -Name "General_ClientId" -Value ((Get-AzADServicePrincipal -DisplayName ("azps-" + $Environment + "-aada")).ApplicationId.Guid) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $True
        New-AzAutomationVariable -Name "General_ClientSecret" -Value $AzPSAadaSecret -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $True
        # Schedules
        $TimeZone = ([System.TimeZoneInfo]::Local).Id
        $StartTime = (Get-Date "06:00:00").AddDays(1)
        $ScheduleName = "daily-0600"
        New-AzAutomationSchedule -Name $ScheduleName -StartTime $StartTime -DayInterval 1 -TimeZone $TimeZone -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
        # azmon-alertlifecycle-rbok
        $RunbookName = "azmon-alertlifecycle-rbok"
        $RunbookDescription = "Manage the lifecycle of an alert New-Acknowledged-Closed."
        $RunbookPath = ($AzMonLocalPath + "\_deployment\" + $RunbookName + ".ps1")
        New-AzAutomationVariable -Name "AlertLifeCycle_AckThreshold" -Value $RBOKAlertLifeCycleAckThreshold -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $False
        New-AzAutomationVariable -Name "AlertLifeCycle_CloseThreshold" -Value $RBOKAlertLifeCycleCloseThreshold -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $False
        Import-AzAutomationRunbook -Path $RunbookPath -Name $RunbookName -Description $RunbookDescription -Type PowerShell -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Force -Published
        Register-AzAutomationScheduledRunbook -Name $RunbookName -ScheduleName $ScheduleName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
        #
        #
        # WORKSPACE MONITORING
        # ----------------------
        # This template deploys a set of rules and action group that all contribute to the monitoring of the workspace and the service itself. The areas that are being monitored are:
        #       - Workspace data usage: If data ingestion is above a threshold for 2 consecutive days then an alert is raised and this should be investigated.
        #
        ("azmon-basicrules-tmpl...")
        $AzMonBasicRules = (az group deployment create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-basicrules-tmpl\_working\template.json") `
                        --name "azmon-basicrules" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "AZMONBasicRGName=$ResourceGroupName" `
                        "workspaceName=$WorkspaceName" `
                        "dataPerDayThresholdMB=$dataPerDayThresholdMB" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-basicrules-tmpl: " + $AzMonBasicRules.properties.provisioningState + " (" + $AzMonBasicRules.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonBasicRulesTmpl = $AzMonBasicRules.properties.provisioningState
        $BasicRulesActionGroupId = $AzMonBasicRules.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.basicRulesActionGroupId = $BasicRulesActionGroupId
        #
        #
        # DIAGNOSTICS SETTINGS
        # ------------------------
        # Most Azure resources emit logs that can be capture by a log analytics workspace. In this section we configure diagnostics settings for some AzGov and AzMon resources.
        # AzGov.Keyvault
        $KeyvDiagSet = '[{ \"category\": \"AuditEvent\", \"enabled\": true, \"retentionPolicy\": { \"enabled\": false, \"days\": 0 }}]'
        $KeyvaultId = (az keyvault show --name "$KeyvaultName" --resource-group "$KeyvaultRGName" | ConvertFrom-Json).id
        $KeyvDiagnostics = (az monitor diagnostic-settings create `
                        --name "$WorkspaceName" `
                        --resource "$KeyvaultId" `
                        --workspace "$WorkspaceId" `
                        --logs "$KeyvDiagSet") `
        | ConvertFrom-Json
        ("$KeyvaultName diagnostic settings: " + $KeyvDiagnostics.id)
        # AzMon.AutomationAccount
        $AutoAcctDiagSet = '[{ \"category\": \"JobLogs\", \"enabled\": true, \"retentionPolicy\": { \"enabled\": false, \"days\": 0 }}]'
        $AutoAcctDiagnostics = (az monitor diagnostic-settings create `
                        --name "$WorkspaceName" `
                        --resource "$AutoAcctId" `
                        --workspace "$WorkspaceId" `
                        --logs "$AutoAcctDiagSet") `
        | ConvertFrom-Json
        ("$AutoAcctName diagnostic settings: " + $AutoAcctDiagnostics.id)
        # AzGov.AutomationAccount
        $AzGovAutoAcctId = $AutoAcctId -replace "azmon", "azgov"
        $AzGovAutoAcctName = $AutoAcctName -replace "azmon", "azgov"
        $AutoAcctDiagnostics = (az monitor diagnostic-settings create `
                        --name "$WorkspaceName" `
                        --resource "$AzGovAutoAcctId" `
                        --workspace "$WorkspaceId" `
                        --logs "$AutoAcctDiagSet") `
        | ConvertFrom-Json
        ("$AzGovAutoAcctName diagnostic settings: " + $AutoAcctDiagnostics.id)
        #
        #
        # SVCHEALTH (azmon-svchealth-tmpl)
        # -----------------------------------
        # Azure is comprised of managed services that are offered to the customer. These services hosted in Azure all run of course on hardware. It is Microsoft's task to monitor that hardware and also the software that delivers the service to the customer. We can't and shouldn't monitor the hardware or the software that hosts the services but we should at least be aware of the health state of the different services.
        # This template aims to notify us when a service has issues or when there's planned downtime or maintenance scheduled.
        # Alert rules created in this template also need a target to work against. In this case this will be at the subscription level. Two alert rules will be created, one for Incidents and one for Information.
        ("azmon-svchealth-tmpl...")
        $AzMonSvcHealth = (az group deployment create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-svchealth-tmpl\_working\template.json") `
                        --name "azmon-svchealth" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-svchealth-tmpl: " + $AzMonSvcHealth.properties.provisioningState + " (" + $AzMonSvcHealth.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonSvcHealthTmpl = $AzMonSvcHealth.properties.provisioningState
        $SvcHealthActionGroupId = $AzMonSvcHealth.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.svcHealthActionGroupId = $SvcHealthActionGroupId
        #
        #
        # NWRULES (azmon-nwrules-tmpl)
        # -------------------------------
        # The purpose of this template is to deploy network monitoring alert rules that are used to alert if one or more of the three tests detected network issues. These tests are:
        # - AzVnet2OnPrem: Azure VNet to on-premise infrastructure communication.
        # - AzVnet2Web: Azure VNet to internet communication.
        # - AzVnet2AzVnet: Azure VNet to Azure VNet communication
        # These tests need to be configured manually in the log analytics workspace via a set of steps that are separately available.
        ("azmon-nwrules-tmpl...")
        $AzMonNWRules = (az group deployment create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-nwrules-tmpl\_working\template.json") `
                        --name "azmon-nwrules" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "WorkspaceRGName=$ResourceGroupName" `
                        "workspaceName=$WorkspaceName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-nwrules-tmpl: " + $AzMonNWRules.properties.provisioningState + " (" + $AzMonNWRules.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonNWRulesTmpl = $AzMonNWRules.properties.provisioningState
        $NWRulesActionGroupId = $AzMonNWRules.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.nwRulesActionGroupId = $NWRulesActionGroupId
        #
        #
        # VMWORKBOOK (azmon-vmworkbook-tmpl)
        # -------------------------------------
        # The vmworkbook template is used to deploy an Azure monitor workbook to report on computer health and base performance counters. The location or region where the workbook is deployed is the same as the one where the target resource group is located. As a resource group it's best to select the same resource group as the one where the log analytics workspace was deployed.
        ("azmon-vmworkbook-tmpl...")
        $TemplateContents = Get-Content -Path ($AzMonLocalPath + "\azmon-vmworkbook-tmpl\_working\template.json")
        $NewTemplateContents = $TemplateContents -replace "a53c5946-e76d-4ca2-bee2-57cfbb3eee7a", $SubscriptionID -replace "azmon-prod-mydur", $VMWorkbookName -replace "azmon2437-prod-lana", $WorkspaceName -replace "azmon-prod-rg", $ResourceGroupName
        $NewTemplateContents | Out-File -FilePath ($AzMonLocalPath + "\azmon-vmworkbook-tmpl\_working\template.json") -Force  -Encoding ascii
        $AzMonVMWorkbook = (az group deployment create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-vmworkbook-tmpl\_working\template.json") `
                        --name "azmon-vmworkbook" ) `
        | ConvertFrom-Json
        ("azmon-vmworkbook-tmpl: " + $AzMonVMWorkbook.properties.provisioningState + " (" + $AzMonVMWorkbook.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonVMWorkbookTmpl = $AzMonVMWorkbook.properties.provisioningState
        #
        #
        # BACKUPSOL (azmon-backupsol-tmpl)
        # -----------------------------------
        # The template deploys an additional solution to the log analytics workspace to monitor Azure backup.
        ("azmon-backupsol-tmpl...")
        $AzMonBackupSol = (az group deployment create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-backupsol-tmpl\_working\template.json") `
                        --name "azmon-backupsol" `
                        --parameters `
                        "Environment=$Environment" `
                        "workspaceName=$WorkspaceName" `
                        "Location=$Location") `
        | ConvertFrom-Json
        ("azmon-backupsol-tmpl: " + $AzMonBackupSol.properties.provisioningState + " (" + $AzMonBackupSol.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonBackupSolTmpl = $AzMonBackupSol.properties.provisioningState
        #
        # CREATE SERVICE PRINCIPAL
        # ---------------------------
        # AZMON
        ("$AzMonAadaName...")
        $AzMonAada = (az ad sp create-for-rbac `
                        --name "$AzMonAadaName" `
                        --years 3) `
        | ConvertFrom-Json
        ($AzMonAada.displayName + ": " + $AzMonAada.appId)
        $AzMonAadaKeyv = (az keyvault secret set `
                        --vault-name "$KeyvaultName" `
                        --name "$AzMonAadaName" `
                        --description "Password" `
                        --value $AzMonAada.password) `
        | ConvertFrom-Json
        ($AzMonAada.displayName + " keyvault secret: " + $AzMonAadaKeyv.id)
        $AzMonAadaSP = (az ad sp show `
                        --id $AzMonAada.name) `
        | ConvertFrom-Json
        $AzMonAadaKeyvPol = (az keyvault set-policy `
                        --name "$KeyvaultName" `
                        --resource-group "$KeyvaultRGName" `
                        --object-id $AzMonAadaSP.objectId `
                        --secret-permissions get list `
                        --storage-permissions get getsas list listsas `
                        --certificate-permissions get getissuers list listissuers `
                        --key-permissions get list) `
        | ConvertFrom-Json
        #
        # INCLUDE DRM
        # -------------
        if ($IncludeDRM) {
                ("azmon-delegatedrights-tmpl...")
                $ContributorGroupId = $ParametersJSON.DRM.ContributorGroupId
                $MSPTenantId = $ParametersJSON.DRM.MSPTenantId 
                $TemplateContents = Get-Content -Path ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\parameters.json")
                $NewTemplateContents = $TemplateContents -replace "###MSPTenantID###", $MSPTenantID -replace "###ContributorGroupId###", $ContributorGroupId
                $NewTemplateContents | Out-File -FilePath ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\parameters.json") -Force  -Encoding ascii
                $AzMonDRM = (az deployment create `
                                --location "$Location" `
                                --template-file ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\template.json") `
                                --parameters ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\parameters.json") `
                                --name "azmon-delegatedrights" ) `
                | ConvertFrom-Json
                ("azmon-delegatedrights-tmpl: " + $AzMonDRM.properties.provisioningState + " (" + $AzMonDRM.properties.correlationId + ")")
                $ParametersJSON.Outputs.AzMonDRMTmpl = $AzMonDRM.properties.provisioningState
        } # End -IncludeDRM
} # End of DeployBaseSetup
#
#
##########################################################################
# IncludeLinux (Base setup)
##########################################################################
#
If ($IncludeLinux -and $WorkspaceName -ne "tbd" -and $ParametersJSON.Outputs.azMonBasicLinuxTmpl -ne "Succeeded") {
        ("azmon-basiclinux-tmpl...")
        $AzMonBasicLinux = (az group deployment create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-basiclinux-tmpl\_working\template.json") `
                        --name "azmon-basiclinux" `
                        --parameters `
                        "Project=$TagProject" `
                        "VMRGName=$VMResourceGroupName " `
                        "Environment=$Environment" `
                        "dataRetention=$WorkspaceDataRetention" `
                        "Location=$LocationDisplayName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy" `
                        "UniqueNumber=$UniqueNumber") `
        | ConvertFrom-Json
        ("azmon-basiclinux-tmpl: " + $AzMonBasicLinux.properties.provisioningState + " (" + $AzMonBasicLinux.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonBasicLinuxTmpl = $AzMonBasicLinux.properties.provisioningState
} # End of IncludeLinux for base setup
#
#
##########################################################################
# NonAzureVMs
##########################################################################
# Optionally the service can also monitor non-Azure VMs. Because our main grouping for Azure VMs is the resource group we need another way to group non-Azure VMs since they don't have a resource group rthey belong to. To solve this we created new alert rule queries, based on existing VMRules queries, that have an additional criteria. This additional criteria makes sure that only non-Azure VMs are taken into account for the query. The original queries check for the resource group name, for NonAzureVMs we replace this with _ResourceId = "". An empty ResourceIs means that the machine is not hosted in Azure and thus can be considered as non-Azure. This also means that ALL non-Azure VMs are conisdered as 1 group that is targetted with the same set of alert rules.
# This section deploys these alert rules to the same resource group as where the workspace is hosted. The deployment is controlled by a swith to the script called NonAzureVMs. We don't deploy the rules by default because even if there's no non-Azure VM the presence of the rules will still incur costs each time the query is fired.
#
If ($NonAzureVMs) {
        #
        # NONAZUREVMS (azmon-nonazurevms-tmpl)
        # ----------------------------------------
        # This template is used to deploy a set of monitoring rules that will be used for all virtual machines that are Non-Azure. These alert rules are stored in the same resource group as where the workspace resides. There's only 1 set of rules when it comes to non-azure virtual machine monitoring and that set contains the same rules as for monitoring virtual machines in a resource group.
        ("azmon-nonazurevms-tmpl...")
        $AzMonOnpremRules = (az group deployment create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-nonazurevms-tmpl\_working\template.json") `
                        --name "azmon-nonazurevms" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "AZMONBasicRGName=$ResourceGroupName" `
                        "workspaceName=$WorkspaceName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-nonazurevms-tmpl: " + $AzMonOnpremRules.properties.provisioningState + " (" + $AzMonOnpremRules.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonNonAzureVMsTmpl = $AzMonOnpremRules.properties.provisioningState
        $NonAzureVMsActionGroupId = $AzMonOnpremRules.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.nonAzureVMsActionGroupId = $NonAzureVMsActionGroupId
} # End of NonAzureVMs
#
#
##########################################################################
# AddVMResGroup
##########################################################################
# The resource group is the smallest collection that we use to identify resources to be monitored. What this means is that for each resource group that contains virtual machines to be monitored this part of the script will need to be executed. It deploys the following templates:
# - azmon-vmrules-tmpl
# - azmon-rschealth-tmpl
# - azmon-vault-tmpl
# - azmon-vmbkup-tmpl
# The last template, azmon-vmbkup-tmpl, is used to add virtual machines to the backup. This template should be used for all machines that require backup by the backup vault that is hosted in the same resource group as the virtual machines themselves. 
#
# The location of these templates is fixed in the script and the location starts with C:\Getronics\AzMon. Under this folder there should be a subfolder for each template. For the 1st one in the list this would then be C:\Getronics\AzMon\azmon-basic-tmpl. Below that folder there should be a '_working' folder that contains the actual template file. The process is the same for every template in the list. This folder setup is also used during developoment of the templates. In future versions we will probably get the templates from Github.
#
# NOTE: The method of deployment for azmon-vmbkup-tmpl is different from all the other templates. See later in this script for more information.
#
# Besides the template deployments there also the creation of a resource group that is done in this section of the script. This is the resource group that will contain or contains the virtual machines to be monitored. If the resource group already exists then the script will see this and retrieve the details of the group that are needed later in the script. The name of the resource group is part of the paramaters JSON file and should be changed in that location for every time this part of the script is executed for another resource group containing virtual machines to be monitored.
If ($AddVMResGroup) {
        # 8. VM Resource Group
        # This action created a resource group to host the virtual machines that will be monitored. If it already exists the script will just retrieve details needed later in the script.
        $VMResourceGroup = (az group create `
                        --name "$VMResourceGroupName" `
                        --location "$Location") `
        | ConvertFrom-Json
        ("VM Resource Group: " + $VMResourceGroup.id)
        #
        #
        # VMRULES (azmon-vmrules-tmpl)
        # -------------------------------
        # This template is used to deploy a set of monitoring rules that will be used for all virtual machines in the resource group. These alert rules are stored in the resource group together with the virtual machines so that when the resource group gets decomissioned the alert rules are deleted also. Remember that we use log analytics to monitor the virtual machines and that before a virtual machines can be monitored by a log analytics workspace an agent needs to be installed on the virtual machine that reports to the workspace. That's why in this section of the script we also enable a policy-set (initiative) that is used to deploy the Microsoft Monitoring Agent (MMA) to all supported virtual machines in the resource group. The scope for the policy is the resource group which means that we will have a policy for every resource group containing virtual machines to be monitored. The policy contains a DeployIfNotExist action which means that we need credentials to perform the actual deployment. We leave it to Azure to create a managed identity for us but we need to give that identity rights to perform its actions. Two roles are given to the managed identity:
        # - Contributor - scoped to resoruce group containing virtual machines
        # - Log Analytics Contributor - scoped to resource group containig the log analytics workspace
        ("azmon-vmrules-tmpl...")
        $AzMonVMRules = (az group deployment create `
                        --resource-group "$VMResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-vmrules-tmpl\_working\template.json") `
                        --name "azmon-vmrules" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "AZMONBasicRGName=$ResourceGroupName" `
                        "workspaceName=$WorkspaceName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-vmrules-tmpl: " + $AzMonVMRules.properties.provisioningState + " (" + $AzMonVMRules.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonVMRulesTmpl = $AzMonVMRules.properties.provisioningState
        $VMRulesActionGroupId = $AzMonVMRules.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.vmRulesActionGroupId = $VMRulesActionGroupId
        $AssignmentDisplayName = "AzMon: Deploy Log Analytics Agent for Windows VMs in " + $VMResourceGroupName
        $AssignmentName = "DeployWinMMA(" + $VMResourceGroupName + ")"
        $PolicySetDef = Get-AzPolicySetDefinition -Id "/providers/Microsoft.Authorization/policySetDefinitions/55f3eceb-5573-4f18-9695-226972c6d74a" -ApiVersion "2019-01-01"
        $PolicyParams = @{'logAnalytics_1' = $WorkspaceId }
        $Assignment = New-AzPolicyAssignment -Name "$AssignmentName" -DisplayName "$AssignmentDisplayName" -Scope $VMResourceGroup.id -PolicySetDefinition $PolicySetDef -Location $Location -PolicyParameterObject $PolicyParams -AssignIdentity -ApiVersion "2019-01-01"
        $VMRoleAssignment = (az role assignment create `
                        --role Contributor `
                        --assignee-object-id $Assignment.Identity.PrincipalId `
                        --scope $VMResourceGroup.id) `
        | ConvertFrom-Json
        ("VM Role assignment: " + $VMRoleAssignment.id)
        Start-Sleep -Seconds 15
        $ParametersJSON.Outputs.VMRoleAssignment = $VMRoleAssignment.id
        $RoleAssignment = (az role assignment create `
                        --role "Log Analytics Contributor" `
                        --assignee-object-id $Assignment.Identity.PrincipalId `
                        --scope $ResourceGroup.id) `
        | ConvertFrom-Json
        ("LANA Role assignment: " + $RoleAssignment.id)
        $ParametersJSON.Outputs.LANARoleAssignment = $RoleAssignment.id
        #
        #
        # RSCHEALTH (azmon-rschealth-tmpl)
        # ------------------------------------
        # The purpose of this template is to put all resources (alert rules and action groups) in place to monitor health of resources. Not every type of Azure resource emits health information but for those types who do this is an easy way to be kept aware of the health state of your individual resources.
        ("azmon-rschealth-tmpl...")
        $AzMonRscHealth = (az group deployment create `
                        --resource-group "$VMResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-rschealth-tmpl\_working\template.json") `
                        --name "azmon-rschealth" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-rschealth-tmpl: " + $AzMonRscHealth.properties.provisioningState + " (" + $AzMonRscHealth.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonRSCHealthTmpl = $AzMonRSCHealth.properties.provisioningState
        $RscHealthActionGroupId = $AzMonRscHealth.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.rscHealthActionGroupId = $RscHealthActionGroupId
        #
        #
        # VAULT (azmon-vault-tmpl)
        # ----------------------------
        # This template is used to deploy a Azure Recovery Services vault together with diagnostics sent to a log analytics workspace. To complete the monitoring you must make sure that the backup solution is also configured in the choosen log analytics workspace.
        ("azmon-vault-tmpl...")
        $instantRpRetentionRangeInDays = $ParametersJSON.Vault.instantRpRetentionRangeInDays
        $dailyRetentionDurationCount = $ParametersJSON.Vault.dailyRetentionDurationCount
        $weeklyRetentionDurationCount = $ParametersJSON.Vault.weeklyRetentionDurationCount
        $monthlyRetentionDurationCount = $ParametersJSON.Vault.monthlyRetentionDurationCount
        $yearlyRetentionDurationCount = $ParametersJSON.Vault.yearlyRetentionDurationCount
        $redundancyType = $ParametersJSON.Vault.redundancyType
        $AzMonVault = (az group deployment create `
                        --resource-group "$VMResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-vault-tmpl\_working\template.json") `
                        --name "azmon-vault" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "workspaceRGName=$ResourceGroupName" `
                        "workspaceName=$WorkspaceName" `
                        "instantRpRetentionRangeInDays=$instantRpRetentionRangeInDays" `
                        "dailyRetentionDurationCount=$dailyRetentionDurationCount" `
                        "weeklyRetentionDurationCount=$weeklyRetentionDurationCount" `
                        "monthlyRetentionDurationCount=$monthlyRetentionDurationCount" `
                        "yearlyRetentionDurationCount=$yearlyRetentionDurationCount" `
                        "redundancyType=$redundancyType" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy" `
                        "UniqueNumber=$UniqueNumber") `
        | ConvertFrom-Json
        ("azmon-vault-tmpl: " + $AzMonVault.properties.provisioningState + " (" + $AzMonVault.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonVaultTmpl = $AzMonVault.properties.provisioningState
        $BackupVaultName = $AzMonVault.properties.outputs.BackupVaultName.value
        $ParametersJSON.Outputs.backupVaultName = $BackupVaultName
        $BackupVaultId = $AzMonVault.properties.outputs.BackupVaultId.value
        $ParametersJSON.Outputs.backupVaultId = $BackupVaultId
        $VaultActionGroupId = $AzMonVault.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.vaultActionGroupId = $VaultActionGroupId
        #
        # INCLUDE DRM
        # -------------
        if ($IncludeDRM) {
                ("azmon-delegatedvmrights-tmpl...")
                $VMContributorGroupId = $ParametersJSON.DRM.VMContributorGroupId
                $MSPTenantId = $ParametersJSON.DRM.MSPTenantId 
                $TemplateContents = Get-Content -Path ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\parameters.json")
                $NewTemplateContents = $TemplateContents -replace "###MSPTenantID###", $MSPTenantID -replace "###VMContributorGroupId###", $VMContributorGroupId -replace "###VMResGroup###", $VMResourceGroupName
                $NewTemplateContents | Out-File -FilePath ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\parameters.json") -Force  -Encoding ascii
                $AzMonVMDRM = (az deployment create `
                                --location "$Location" `
                                --template-file ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\template.json") `
                                --parameters ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\parameters.json") `
                                --name "azmon-delegatedvmrights" ) `
                | ConvertFrom-Json
                ("azmon-delegatedvmrights-tmpl: " + $AzMonVMDRM.properties.provisioningState + " (" + $AzMonVMDRM.properties.correlationId + ")")
                $ParametersJSON.Outputs.AzMonVMDRMTmpl = $AzMonVMDRM.properties.provisioningState
        } # End -IncludeDRM
} # End AddVMResGroup
#
#
##########################################################################
# IncludeVMBkUp
##########################################################################
# What we do with this template is adding a list of virtual machines to the backup. This template uses an existing vault and backup policy. Only a single resource type is created and it's called Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems.
#
# As in any other template we try to avoid using resource Id's in the parameter fields. Also in this template friendly names are expected as input parameters and the resourceId() function in the template is responsible for retrieveing the full resource Id and pass it to the configuration items.
# 
# The sourceResourceId configuration item can only handle a single virtual machine at a time. In the parameters however we have the existingVirtualMachines parameter who can handle multple virtual machines at the same time. The way this works is that you provide the name of each virtual machine between double quotes and all virtual machine name should be separated by a comma. Example: ["vm01", "vm02"]
#
# NOTE: Because of the way the list of virtual machines should be passed in a parameter to the script we had issues of getting this list past correctly as a parameter via AzCLI. That's why we use a Powershell cmdlet to start the deployment. In this case we do not only need to path to the template file but also to the parameter file. Because we expect all templates to be present under C:\Getronics\AzMon we can execute the cmdlet without the usage of parameters to this script telling us where the files are. So if you want to add additional virtual machines to the backup the you can use the command below but don't forget to substitute the variables for actual values and also modifying the parameters.json file in the correct location.
#
# NOTE: Make sure that all virtual machines listed in the parameters file are also present in Azure in the resource group where the deployment takes place. If a virtual machine is missing in Azure then the deployment will fail at that point. All preceding virtual machines will have been added to the backup, all subsequent virtual machines will not have been added.
If ($IncludeVmBkup) {
        ("azmon-vmbkup-tmpl...")
        $AzBkupParametersJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-vmbkup-tmpl\_working\parameters.json") -Raw | ConvertFrom-Json
        $AzBkupParametersJSON.parameters.UniqueNumber.value = $ParametersJSON.General.UniqueNumber
        $AzBkupParametersJSON.parameters.existingVirtualMachines.value = $ParametersJSON.VMBkUp.existingVirtualMachines | ConvertTo-Json -Compress
        $AzBkupParametersJSON | ConvertTo-Json | Out-File -FilePath ($AzMonLocalPath + "\azmon-vmbkup-tmpl\_working\parameters.json") -Force -Encoding ascii
        $AzBkUpParametersFile = Get-Content -Path ($AzMonLocalPath + "\azmon-vmbkup-tmpl\_working\parameters.json") -Raw
        if ($ParametersJSON.VMBkUp.existingVirtualMachines.count -eq 1) {
                $AzBkUpParametersFile -replace """\\", "[" -replace "\\""""", """]" | Out-File -FilePath ($AzMonLocalPath + "\azmon-vmbkup-tmpl\_working\parameters.json") -Force -Encoding ascii
        }
        else {
                $AzBkUpParametersFile -replace "\\", "" -replace """\[", "[" -replace "\]""", "]" | Out-File -FilePath ($AzMonLocalPath + "\azmon-vmbkup-tmpl\_working\parameters.json") -Force -Encoding ascii
        }
        $AzMonVMBkup = New-AzResourceGroupDeployment -ResourceGroupName $VMResourceGroupName -Name "azmon-vmbkup" -TemplateFile  ($AzMonLocalPath + "\azmon-vmbkup-tmpl\_working\template.json") -TemplateParameterFile  ($AzMonLocalPath + "\azmon-vmbkup-tmpl\_working\parameters.json") 
} # End IncludeVMBkUp
#
#
##########################################################################
# IncludeLinux (VM rules)
##########################################################################
#
If ($IncludeLinux -and $WorkspaceName -ne "tbd" -and $ParametersJSON.Outputs.azMonBasicLinuxTmpl -eq "Succeeded") {
        ("azmon-vmlinuxrules-tmpl...")
        $AzMonVMLinuxRules = (az group deployment create `
                        --resource-group "$VMResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-vmlinuxrules-tmpl\_working\template.json") `
                        --name "azmon-vmlinuxrules" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "AZMONBasicRGName=$ResourceGroupName" `
                        "workspaceName=$WorkspaceName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-vmlinuxrules-tmpl: " + $AzMonVMLinuxRules.properties.provisioningState + " (" + $AzMonVMLinuxRules.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonVMLinuxRulesTmpl = $AzMonVMLinuxRules.properties.provisioningState
} # End of IncludeLinux for VM rules
#
#
##########################################################################
# IncludeK8S (K8S rules)
##########################################################################
#
If ($IncludeK8S -and $WorkspaceName -ne "tbd") {
        $K8SClusterName = $ParametersJSON.K8S.ClusterName
        $K8SClusterRGName = $ParametersJSON.K8S.ClusterRGName
        ("azmon-k8srules-tmpl...")
        $AzMonK8SRules = (az group deployment create `
                        --resource-group "$K8SClusterRGName" `
                        --template-file ($AzMonLocalPath + "\azmon-k8srules-tmpl\_working\template.json") `
                        --name "azmon-k8srules" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "K8SClusterName=$K8SClusterName" `
                        "K8SResourceGroup=$K8SClusterRGName" `
                        "AMLWorkspaceName=$WorkspaceName" `
                        "AMLResourceGroup=$ResourceGroupName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-k8srules-tmpl: " + $AzMonK8SRules.properties.provisioningState + " (" + $AzMonK8SRules.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonK8SRulesTmpl = $AzMonK8SRules.properties.provisioningState
        $ParametersJSON.Outputs.K8SClusterName = $K8SClusterName  
}
#
#
##########################################################################
# IncludeASR (ASR rules)
##########################################################################
#
If ($IncludeASR -and $WorkspaceName -ne "tbd") {
        $ASRVaultName = $ParametersJSON.ASR.VaultName
        $ASRVaultRGName = $ParametersJSON.ASR.VaultRGName
        $ASRRPOCritical = $ParametersJSON.ASR.RPOCritical
        $ASRRPOWarning = $ParametersJSON.ASR.RPOWarning
        $ASRTestFailoverMissingThreshold = $ParametersJSON.ASR.TestFailoverMissingThreshold
        ("azmon-asrrules-tmpl...")
        $AzMonASRRules = (az group deployment create `
                        --resource-group "$ASRVaultRGName" `
                        --template-file ($AzMonLocalPath + "\azmon-asrrules-tmpl\_working\template.json") `
                        --name "azmon-asrrules" `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "ASRVaultName=$ASRVaultName" `
                        "ASRVaultRGName=$ASRVaultRGName" `
                        "AMLWorkspaceName=$WorkspaceName" `
                        "AMLResourceGroup=$ResourceGroupName" `
                        "RPOCritical=$ASRRPOCritical" `
                        "RPOWarning=$ASRRPOWarning" `
                        "TestFailoverMissingThreshold=$ASRTestFailoverMissingThreshold" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        ("azmon-asrrules-tmpl: " + $AzMonASRRules.properties.provisioningState + " (" + $AzMonASRRules.properties.correlationId + ")")
        $ParametersJSON.Outputs.azMonASRRulesTmpl = $AzMonASRRules.properties.provisioningState
        $ParametersJSON.Outputs.ASRVaultName = $ASRVaultName

        $ASRDiagSet = '[{ \"category\": \"AzureSiteRecoveryJobs\", \"enabled\": true, \"category\": \"AzureSiteRecoveryEvents\", \"enabled\": true, \"category\": \"AzureSiteRecoveryReplicatedItems\", \"enabled\": true, \"category\": \"AzureSiteRecoveryReplicationStats\", \"enabled\": true, \"category\": \"AzureSiteRecoveryRecoveryPoints\", \"enabled\": true, \"category\": \"AzureSiteRecoveryReplicationDataUploadRate\", \"enabled\": true, \"category\": \"AzureSiteRecoveryProtectedDiskDataChurn\", \"enabled\": true, \"retentionPolicy\": { \"enabled\": false, \"days\": 0 }}]'
        $ASRVaultId = (az backup vault show --name "$ASRVaultName" --resource-group "$ASRVaultRGName" | ConvertFrom-Json).id
        $ASRDiagnostics = (az monitor diagnostic-settings create `
                        --name "$WorkspaceName" `
                        --resource "$ASRVaultId" `
                        --workspace "$WorkspaceId" `
                        --logs "$ASRDiagSet") `
        | ConvertFrom-Json
        ("$ASRVaultName diagnostic settings: " + $ASRDiagnostics.id)
}
#
# The next line outputs the ParametersJSON variable, that was modified with some output data from the template deployments, backup to its original .json parameter file.
$ParametersJSON | ConvertTo-Json | Out-File -FilePath "$ParametersFile" -Force -Encoding ascii