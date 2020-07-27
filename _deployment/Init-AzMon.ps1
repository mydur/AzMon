#Requires -RunAsAdministrator
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
	
        .PARAMETER IncludeASR
                This switch indicates that the monitoring for Azure Site Recovery should be enabled and configured.	
	
        .PARAMETER IncludeAFS
                This switch indicates that the monitoring for Azure File Sync should be enabled and configured.
	
        .PARAMETER ASRServer
                This switch indicates that monitoring for on on-premise ASR Configuration/Process server should be enabled.
	
        .PARAMETER IncludeNSG
                This switch indicates that the monitoring for Network Security Groups should be enabled and configured.
                
        .NOTES
		Title:          Init-AzMon.ps1
		Author:         Rudy Michiels
                Created:        2019-10-17
                Version:        10
		ChangeLog:
                        2019-09-26      Initial version
                        2019-09-30      Added -IncludeVMBkUp switch parameter
                        2019-10-17      Added -NonAzureVMs switch parameter
                        2019-10-25      Added -IncludeLinux switch parameter  
                        2019-12-20      Added -IncludeK8S switch parameter
                        2020-02-20      Added -IncludeASR switch parameter
                        2020-03-03      Added -IncludeAFS switch parameter
                        2020-04-20      Added -ASRserver switch parameter
                        2020-05-07      Added -IncludeNSG switch parameter 
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
        [switch]$IncludeAFS,
        [switch]$ASRserver,
        [switch]$IncludeNSG,
        [switch]$Update
)

##########################################################################
# PREREQS
##########################################################################
# Azure CLI install/update
[console]::ForegroundColor = "White"
[console]::BackgroundColor = "Black"
Clear-Host
New-Item -Path "C:\Getronics" -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path "C:\Getronics\AzMon" -ItemType Directory -ErrorAction SilentlyContinue
#Set-Location -Path "C:\Getronics\AzMon"
If ($CheckPrereqs) {
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile "C:\Getronics\AzMon\AzureCLI.msi"
        Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
        Remove-Item -Force "C:\Getronics\AzMon\AzureCLI.msi"
}

##########################################################################
# VARIABLES
##########################################################################
# Being read from JSON file...
If (Test-Path $ParametersFile) {
        Write-Host ("The file $ParametersFile is present. Continuing...") -ForegroundColor "Green"
}
else {
        Write-Host ("The file $ParametersFile is NOT present. Quiting...") -ForegroundColor "Red"
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
$WorkspaceDataRetention = $ParametersJSON.Basic.WorkspaceDataRetention
$SubscriptionName = $ParametersJSON.General.SubscriptionName
# Probably no change needed...
$ResourceGroupName = ("azmon-$Environment-rg").ToLower()
$WorkspaceName = $ParametersJSON.Outputs.workspaceName
$WorkspaceId = $ParametersJSON.Outputs.workspaceId
$KeyvaultName = "azgov$UniqueNumber-$Environment-keyv"
$KeyvaultRGName = "azgov-$Environment-rg"
$AzAutoAadaName = "azmonauto-$Environment-aada"
$TagOwnedBy = "Getronics"
$TagCreatedOn = (Get-Date -Format "yyyyMMdd")
$TagEnvironment = $Environment
$TagProject = "AzMon"
$AzMonLocalPath = "C:\Getronics\AzMon"
$GithubBaseFolder = "https://github.com/mydur/ARMtemplates/raw/master/"
$VMWorkbookName = "azmon-$Environment-wbok"
$AutoAcctName = $ParametersJSON.Outputs.autoAcctName
$RBOKAlertLifeCycleAckThreshold = 3     # Number of days without changes after which alert is set to Acknowledged
$RBOKAlertLifeCycleCloseThreshold = 20  # Number of days without changes after which alert is set to Closed


##########################################################################
# DOWNLOAD TEMPLATE FILES
##########################################################################
Write-Host ("Downloading templates...") -ForegroundColor "White"
$TemplateFolders = "azmon-basic-tmpl/_working", "azmon-basicrules-tmpl/_working", "azmon-svchealth-tmpl/_working", "azmon-nwrules-tmpl/_working", "azmon-vmworkbook-tmpl/_working", "azmon-backupsol-tmpl/_working", "azmon-vmrules-tmpl/_working", "azmon-nonazurevms-tmpl/_working", "azmon-rschealth-tmpl/_working", "azmon-vault-tmpl/_working", "azmon-vmbkup-tmpl/_working", "azmon-delegatedrights-tmpl/_working", "azmon-delegatedvmrights-tmpl/_working", "azmon-vmlinuxrules-tmpl/_working", "azmon-basiclinux-tmpl/_working", "azmon-k8srules-tmpl/_working", "azmon-asrrules-tmpl/_working", "azmon-asrvmrules-tmpl/_working", "azmon-basicasr-tmpl/_working", "azmon-filerules-tmpl/_working", "azmon-basicfile-tmpl/_working", "azmon-nsgrules-tmpl/_working", "azmon-subdiag-tmpl/_working", "azmon-aaddiags-tmpl/_working"

foreach ($TemplateFolder in $TemplateFolders) {
        Write-Host ("   " + $TemplateFolder + "...") -ForegroundColor "White" -NoNewline
        New-Item -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\")) -ItemType Directory -ErrorAction SilentlyContinue
        (New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/template.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force -Encoding ascii
        $TemplateContents = Get-Content -Path ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json")
        $NewTemplateContents = $TemplateContents -replace "\?\?\?", " "
        $NewTemplateContents | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\template.json") -Force  -Encoding ascii
        (New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + $TemplateFolder + "/parameters.json") | Out-File -FilePath ($AzMonLocalPath + "\" + ($TemplateFolder -replace "/", "\") + "\parameters.json") -Force -Encoding ascii
        Write-Host ("Done") -ForegroundColor "Gray"
}

# Runbooks
New-Item -Path ($AzMonLocalPath + "\_deployment") -ItemType Directory -ErrorAction SilentlyContinue
$FileName = "azmon-alertlifecycle-rbok.ps1"
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + "_deployment/" + $FileName) | Out-File -FilePath ($AzMonLocalPath + "\_deployment\" + $FileName) -Force -Encoding ascii
# Helper scripts
$FileName = "Create-RunAsAccount.ps1"
(New-Object System.Net.WebClient).DownloadString($GithubBaseFolder + "_deployment/" + $FileName) | Out-File -FilePath ($AzMonLocalPath + "\_deployment\" + $FileName) -Force -Encoding ascii
<#
##########################################################################
# LOGIN TO AZURE
##########################################################################

Throughout the script we use 2 ways of connecting to Azure, via Azure CLI (az commands) and via Powershell. In this section of the script we login to both parties. The AzCLI login is interactive and uses the --use-device-code option. Make sure to use an account that has been given rights in the tenant (AAD) because user id's (service principal) will be created. The roles required in the tenant are 'Global administrator' and 'Service administrator'. You can have a look at the following two pages for more information about roles in AAD: https://docs.microsoft.com/en-us/azure/role-based-access-control/rbac-and-directory-admin-roles and https://docs.microsoft.com/en-us/azure/role-based-access-control/elevate-access-global-admin. 

The 2nd login, Powershell, uses a service principal that was created by the AzGov script. In the current version of the script there's no error checking and thus the script will show you errors when the service principal was not previously created and its secret stored in the keyvault. The service principal that is used here to do a automatic login is azps-<environment>-aada. For a prod environment this would be azps-prod-aada. Azure commandline, which is logged into first, will be used to retrieve the secret (password) from the keyvault. So make sure that the account used to login to Azure CLI has been given rights (access policy) to the keyvault or the retrieval will fail.

Also, because policies will be assigned you need Owner rights to the subscription that is used. Make sure you are member of that role before you start the script.
#>
$CurrentCLIUser = (az ad signed-in-user show) | ConvertFrom-Json
If ($CurrentCLIUser) {
        Write-Host ("Continuing with user " + $CurrentCLIUser.userPrincipalName + " (press CTRL+C to abort and logout with az logout before restarting)") -ForegroundColor "Green"
        Start-Sleep -Seconds 5
        Write-Host ("Connecting to subscription <" + $SubscriptionName + ">") -ForegroundColor "Green"
        az account set --subscription "$SubscriptionName"
        $UserDisplayName = $CurrentCLIUser.displayName
        $CurrentCLIUserAccount = (az account show) | ConvertFrom-Json
        $SubscriptionID = $CurrentCLIUserAccount.id
}
else {
        $Login = (az login `
                        --tenant "$TenantID" `
                        --use-device-code) `
        | ConvertFrom-Json
        Write-Host ("Connecting to subscription <" + $SubscriptionName + ">") -ForegroundColor "Green"
        az account set --subscription "$SubscriptionName"
        $CurrentCLIUserAccount = (az account show) | ConvertFrom-Json
        $SubscriptionID = $CurrentCLIUserAccount.id
        $UserNameUPN = $CurrentCLIUserAccount.user.name
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
$Location = (az account list-locations --query "[?displayName=='$LocationDisplayName']" --output json | ConvertFrom-Json).name
$AzPSAadaKeyv = (az keyvault secret show `
                --vault-name $KeyvaultName `
                --name ("azps-" + $Environment + "-aada")) `
| ConvertFrom-Json
$AzPSAadaSecret = $AzPSAadaKeyv.value
$Pwd = ConvertTo-SecureString "$AzPSAadaSecret" -AsPlainText -Force
$PSCreds = New-Object System.Management.Automation.PSCredential(("http://azps-" + $Environment + "-aada"), $Pwd)
Connect-AzAccount -ServicePrincipal -Credential $PSCreds -Tenant $TenantID
Select-AzSubscription -SubscriptionName "$SubscriptionName"
#
##########################################################################
# Update
##########################################################################
#
If ($DeployBaseSetup) {

}
<#
##########################################################################
# DeployBaseSetup
##########################################################################
This part of the script deploys the base setup of AzMon. Actual delployments are doen via ARM templates and deployments are started via AzCLI commands. The following templates are being deployed here:
       - azmon-basic-tmpl
       - azmon-svchealth-tmpl
       - azmon-nwrules-tmpl
       - azmon-vmworkbook-tmpl
       - azmon-backupsol-tmpl
The location of these templates is fixed in the script and the location starts with C:\Getronics\AzMon. Under this folder there should be a subfolder for each template. For the 1st one in the list this would then be C:\Getronics\AzMon\azmon-basic-tmpl. Below that folder there should be a '_working' folder that contains the actual template file. The process is the same for every template in the list. This folder setup is also used during developoment of the templates. In future versions we will probably get the templates from Github.

Besides the templates there's 2 other type of activities that are executed:
       - Creation of a resource group
       - Creation of a service principal for AzMon
The name of the resource group is constructed from the Project and Environment variables. If the project is AzMon and environment is Prod then the resource group will be called azmon-prod-rg. This resource group should be used to group all base resources and not the actual resources that need to be monitored.

NOTE: Keep the name of the project as short as possible or leave it to AzMon when monitoring is independent of projects.
NOTE: Re-deployment of the base setup with the same project and environment combination will fail if deployed in the same subscription.

Finally the service principal is created and given Contributor rights to the subscription. This service principal can be used by monitoring in case remediation tasks need to be executed. In the current version of the solution there's no such tasks yet.
#>
If ($DeployBaseSetup) {
        <#
        RESOURCE GROUP
        -----------------
        Assuming that the AzGov has also been deployed via the provided script a set of policies were introduced to add tags to resources and resource groups. Because of these policies resources in a resource group will inherit the values set in the tags on the resource group. That's why the creation of the resource group also adds tag values so they can be inherited by the resources created later in the group.
        #>
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
        Write-Host ("Resource Group: " + $ResourceGroup.id) -ForegroundColor "White"
        $ParametersJSON.Outputs.azMonResGroupId = $ResourceGroup.id
        <#
        BASIC (azmon-basic-tmpl)
        ---------------------------
        The purpose of this template is to deploy a basic setup of Azure Monitor. It contains the following resources:
         - Log Analytics workspace
         - Automation Account
         - Storage Account
        For the storage account and automation account there's no initial configuration but the log analytics workspace has initial configurations set in the template for the following:
         - Datasources
         - Saved searches
         - Solutions
         - Linked services
        The template also contains an 'outputs' section of which the output is captured in variables listed below.
        #>
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-basic-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-basic-tmpl...") -ForegroundColor "White"
        $AzMonBasic = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-basic-tmpl\_working\template.json") `
                        --name ("azmon-basic-" + $TemplateJSON.variables.TemplateVersion) `
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
        Write-Host ("   " + $AzMonBasic.properties.provisioningState + " (" + $AzMonBasic.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonBasicTmpl = ($AzMonBasic.properties.provisioningState + "-" + $AzMonBasic.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $WorkspaceName = $AzMonBasic.properties.outputs.workspacename.value
        $ParametersJSON.Outputs.workspaceName = $WorkspaceName
        $WorkspaceId = $AzMonBasic.properties.outputs.workspaceid.value
        $ParametersJSON.Outputs.workspaceID = $WorkspaceId
        $StorAcctName = $AzMonBasic.properties.outputs.storageaccountname.value
        $ParametersJSON.Outputs.storAcctName = $StorAcctName
        $AutoAcctName = $AzMonBasic.properties.outputs.automationaccountname.value
        $ParametersJSON.Outputs.autoAcctName = $AutoAcctName
        $AutoAcctId = $AzMonBasic.properties.outputs.automationaccountid.value
        $ParametersJSON.Outputs.autoAcctId = $AutoAcctId

        # Add RunAsAccount to the automation account
        Write-Host ("   Adding Automation RunAs Account...") -ForegroundColor "White"
        $RunAsAcctAadaName = $AutoAcctName -replace "auto", "aada"
        $ScriptFileName = $AzMonLocalPath + "\_deployment\" + "Create-RunAsAccount.ps1"
        $ScriptParameters = "-ResourceGroup '$ResourceGroupName' -AutomationAccountName '$AutoAcctName' -SubscriptionId '$SubscriptionID' -TenantId '$TenantId' -ApplicationDisplayName '$AzAutoAadaName' -SelfSignedCertPlainPassword '$AzAutoAadaName' -CreateClassicRunAsAccount 0"
        Invoke-Expression "$ScriptFileName $ScriptParameters"
        Write-Host ("   " + $AzAutoAadaName + " added as runas account with 36 month certificate validity.")
        <#
        AUTOMATION RUNBOOKS
        -------------------
        #>
        # General configuration
        Write-Host ("   Alert lifecycle automation runbook...") -ForegroundColor "White"
        Write-Host ("   Variable configuration") -ForegroundColor "White"
        New-AzAutomationVariable -Name "General_SubscriptionId" -Value $SubscriptionId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $False
        New-AzAutomationVariable -Name "General_TenantId" -Value $TenantId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $False
        New-AzAutomationVariable -Name "General_ClientId" -Value ((Get-AzADServicePrincipal -DisplayName ("azps-" + $Environment + "-aada")).ApplicationId.Guid) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $True
        New-AzAutomationVariable -Name "General_ClientSecret" -Value $AzPSAadaSecret -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $True
        # Schedules
        Write-Host ("   Schedule at 06:00") -ForegroundColor "White"
        $TimeZone = ([System.TimeZoneInfo]::Local).Id
        $StartTime = (Get-Date "06:00:00").AddDays(1)
        $ScheduleName = "daily-0600"
        New-AzAutomationSchedule -Name $ScheduleName -StartTime $StartTime -DayInterval 1 -TimeZone $TimeZone -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
        # azmon-alertlifecycle-rbok
        Write-Host ("   Adding azmon-alertlifecycle-rbok runbook") -ForegroundColor "White"
        $RunbookName = "azmon-alertlifecycle-rbok"
        $RunbookDescription = "Manage the lifecycle of an alert New-Acknowledged-Closed."
        $RunbookPath = ($AzMonLocalPath + "\_deployment\" + $RunbookName + ".ps1")
        New-AzAutomationVariable -Name "AlertLifeCycle_AckThreshold" -Value $RBOKAlertLifeCycleAckThreshold -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $False
        New-AzAutomationVariable -Name "AlertLifeCycle_CloseThreshold" -Value $RBOKAlertLifeCycleCloseThreshold -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Encrypted $False
        Import-AzAutomationRunbook -Path $RunbookPath -Name $RunbookName -Description $RunbookDescription -Type PowerShell -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName -Force -Published
        Register-AzAutomationScheduledRunbook -Name $RunbookName -ScheduleName $ScheduleName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutoAcctName
        Write-Host ("   Done.") -ForegroundColor "White"
        <#
        WORKSPACE MONITORING
        ----------------------
        This template deploys a set of rules and action group that all contribute to the monitoring of the workspace and the service itself. The areas that are being monitored are:
          - Workspace data usage: If data ingestion is above a threshold for 2 consecutive days then an alert is raised and this should be investigated.
        #>
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-basicrules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-basicrules-tmpl...") -ForegroundColor "White"
        $AzMonBasicRules = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-basicrules-tmpl\_working\template.json") `
                        --name ("azmon-basicrules-" + $TemplateJSON.variables.TemplateVersion) `
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
        Write-Host ("   " + $AzMonBasicRules.properties.provisioningState + " (" + $AzMonBasicRules.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonBasicRulesTmpl = ($AzMonBasicRules.properties.provisioningState + "-" + $AzMonBasicRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $BasicRulesActionGroupId = $AzMonBasicRules.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.basicRulesActionGroupId = $BasicRulesActionGroupId
        <#
        DIAGNOSTICS SETTINGS
        ------------------------
        Most Azure resources emit logs that can be capture by a log analytics workspace. In this section we configure diagnostics settings for some AzGov and AzMon resources.
        #>
        Write-Host ("Diagnostics Settings...")
        # Subscription
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-subdiag-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("   azmon-subdiag-tmpl...") -ForegroundColor "White"
        $AzMonSubDiag = (az deployment sub create `
                        --template-file ($AzMonLocalPath + "\azmon-subdiag-tmpl\_working\template.json") `
                        --name ("azmon-subdiag-" + $TemplateJSON.variables.TemplateVersion) `
                        --location $Location `
                        --parameters `
                        "workspaceId=$WorkspaceId" `
                        "settingName=$WorkspaceName") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonSubDiag.properties.provisioningState + " (" + $AzMonSubDiag.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonSubDiagTmpl = ($AzMonSubDiag.properties.provisioningState + "-" + $AzMonSubDiag.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        # AzGov.Keyvault
        $KeyvDiagSet = '[{ \"category\": \"AuditEvent\", \"enabled\": true, \"retentionPolicy\": { \"enabled\": false, \"days\": 0 }}]'
        $KeyvaultId = (az keyvault show --name "$KeyvaultName" --resource-group "$KeyvaultRGName" | ConvertFrom-Json).id
        $KeyvDiagnostics = (az monitor diagnostic-settings create `
                        --name "$WorkspaceName" `
                        --resource "$KeyvaultId" `
                        --workspace "$WorkspaceId" `
                        --logs "$KeyvDiagSet") `
        | ConvertFrom-Json
        Write-Host ("   $KeyvaultName diagnostic settings: ") -ForegroundColor "White" -NoNewline 
        Write-Host ($KeyvDiagnostics.id) -ForegroundColor "Gray"
        # AzMon.AutomationAccount
        $AutoAcctDiagSet = '[{ \"category\": \"JobLogs\", \"enabled\": true, \"retentionPolicy\": { \"enabled\": false, \"days\": 0 }}]'
        $AutoAcctDiagnostics = (az monitor diagnostic-settings create `
                        --name "$WorkspaceName" `
                        --resource "$AutoAcctId" `
                        --workspace "$WorkspaceId" `
                        --logs "$AutoAcctDiagSet") `
        | ConvertFrom-Json
        Write-Host ("   $AutoAcctName diagnostic settings: ") -ForegroundColor "White" -NoNewline 
        Write-Host ($AutoAcctDiagnostics.id) -ForegroundColor "Gray"
        # AzGov.AutomationAccount
        $AzGovAutoAcctId = $AutoAcctId -replace "azmon", "azgov"
        $AzGovAutoAcctName = $AutoAcctName -replace "azmon", "azgov"
        $AutoAcctDiagnostics = (az monitor diagnostic-settings create `
                        --name "$WorkspaceName" `
                        --resource "$AzGovAutoAcctId" `
                        --workspace "$WorkspaceId" `
                        --logs "$AutoAcctDiagSet") `
        | ConvertFrom-Json
        Write-Host ("   $AzGovAutoAcctName diagnostic settings: ") -ForegroundColor "White" -NoNewline 
        Write-Host ($AutoAcctDiagnostics.id) -ForegroundColor "Gray"
        # Azure Active Directory
        <#$TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-aaddiags-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("   azmon-aaddiags-tmpl...")
        $AzMonSvcHealth = (az deployment tenant create `
                        --location "$Location" `
                        --template-file ($AzMonLocalPath + "\azmon-aaddiags-tmpl\_working\template.json") `
                        --name ("azmon-aaddiags-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "workspaceId=$WorkspaceId" `
                        "workspaceName=$WorkspaceName")
        #>
        <#
        ASC ONBOARDING
        ---------------
        #>
        if ($ParametersJSON.General.ASCOnboard -eq "Free" -or $ParametersJSON.General.ASCOnboard -eq "Standard") {
                Write-Host ("Onboarding " + $WorkspaceName + " to ASC...") -ForegroundColor "White"
                #Install-Module -Name Az.Security -Force
                #Set-AzContext -Subscription "$SubscriptionId"
                Register-AzResourceProvider –ProviderNamespace 'Microsoft.Security' | Out-Null
                Set-AzSecurityPricing -Name "VirtualMachines" -PricingTier $ParametersJSON.General.ASCOnboard | Out-Null
                Set-AzSecurityWorkspaceSetting -Name "default" -Scope "/subscriptions/$SubscriptionId" -WorkspaceId "$WorkspaceId" | Out-Null
                Set-AzSecurityContact -Name "default1" -Email $ParametersJSON.General.ASCContactEmail -Phone $ParametersJSON.General.ASCContactPhone -AlertAdmin -NotifyOnAlert | Out-Null
                $Policy = Get-AzPolicySetDefinition -Name '1f3afdf9-d0c9-4c3d-847f-89da613e70a8'
                $Assignment = New-AzPolicyAssignment -Name "ASCOnboading" -DisplayName "AzMon: Enable Security Center for subscription $SubscriptionName" -PolicySetDefinition $Policy –Scope "/subscriptions/$SubscriptionId"
                Write-Host ("   " + $Assignment.ResourceId) -ForegroundColor "Gray"
                $ParametersJSON.Outputs.ASCOnboarding = $ASsignment.ResourceId
        }
        <#
        SVCHEALTH (azmon-svchealth-tmpl)
        -----------------------------------
        Azure is comprised of managed services that are offered to the customer. These services hosted in Azure all run of course on hardware. It is Microsoft's task to monitor that hardware and also the software that delivers the service to the customer. We can't and shouldn't monitor the hardware or the software that hosts the services but we should at least be aware of the health state of the different services.
        This template aims to notify us when a service has issues or when there's planned downtime or maintenance scheduled.
        Alert rules created in this template also need a target to work against. In this case this will be at the subscription level. Two alert rules will be created, one for Incidents and one for Information.
        #>
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-svchealth-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-svchealth-tmpl...") -ForegroundColor "White"
        $AzMonSvcHealth = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-svchealth-tmpl\_working\template.json") `
                        --name ("azmon-svchealth-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonSvcHealth.properties.provisioningState + " (" + $AzMonSvcHealth.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonSvcHealthTmpl = ($AzMonSvcHealth.properties.provisioningState + "-" + $AzMonSvcHealth.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $SvcHealthActionGroupId = $AzMonSvcHealth.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.svcHealthActionGroupId = $SvcHealthActionGroupId
        <#
        NWRULES (azmon-nwrules-tmpl)
        -------------------------------
        The purpose of this template is to deploy network monitoring alert rules that are used to alert if one or more of the three tests detected network issues. These tests are:
         - AzVnet2OnPrem: Azure VNet to on-premise infrastructure communication.
         - AzVnet2Web: Azure VNet to internet communication.
         - AzVnet2AzVnet: Azure VNet to Azure VNet communication
        These tests need to be configured manually in the log analytics workspace via a set of steps that are separately available.
        #>
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-nwrules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-nwrules-tmpl...") -ForegroundColor "White"
        $AzMonNWRules = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-nwrules-tmpl\_working\template.json") `
                        --name ("azmon-nwrules-" + $TemplateJSON.variables.TemplateVersion) `
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
        Write-Host ("   " + $AzMonNWRules.properties.provisioningState + " (" + $AzMonNWRules.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonNWRulesTmpl = ($AzMonNWRules.properties.provisioningState + "-" + $AzMonNWRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $NWRulesActionGroupId = $AzMonNWRules.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.nwRulesActionGroupId = $NWRulesActionGroupId
        <#
        VMWORKBOOK (azmon-vmworkbook-tmpl)
        -------------------------------------
        The vmworkbook template is used to deploy an Azure monitor workbook to report on computer health and base performance counters. The location or region where the workbook is deployed is the same as the one where the target resource group is located. As a resource group it's best to select the same resource group as the one where the log analytics workspace was deployed.
        #>
        Write-Host ("azmon-vmworkbook-tmpl...") -ForegroundColor "White"
        $TemplateContents = Get-Content -Path ($AzMonLocalPath + "\azmon-vmworkbook-tmpl\_working\template.json")
        $NewTemplateContents = $TemplateContents -replace "a53c5946-e76d-4ca2-bee2-57cfbb3eee7a", $SubscriptionID -replace "azmon-prod-mydur", $VMWorkbookName -replace "azmon2437-prod-lana", $WorkspaceName -replace "azmon-prod-rg", $ResourceGroupName
        $NewTemplateContents | Out-File -FilePath ($AzMonLocalPath + "\azmon-vmworkbook-tmpl\_working\template.json") -Force  -Encoding ascii
        $AzMonVMWorkbook = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-vmworkbook-tmpl\_working\template.json") `
                        --name "azmon-vmworkbook" ) `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonVMWorkbook.properties.provisioningState + " (" + $AzMonVMWorkbook.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonVMWorkbookTmpl = ($AzMonVMWorkbook.properties.provisioningState + "-" + $AzMonVMWorkbook.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        <#
        BACKUPSOL (azmon-backupsol-tmpl)
        -----------------------------------
        The template deploys an additional solution to the log analytics workspace to monitor Azure backup.
        #>
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-backupsol-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-backupsol-tmpl...") -ForegroundColor "White"
        $AzMonBackupSol = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-backupsol-tmpl\_working\template.json") `
                        --name ("azmon-backupsol-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "Environment=$Environment" `
                        "workspaceName=$WorkspaceName" `
                        "Location=$Location") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonBackupSol.properties.provisioningState + " (" + $AzMonBackupSol.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonBackupSolTmpl = ($AzMonBackupSol.properties.provisioningState + "-" + $AzMonBackupSol.properties.outputs.templateVersion.value + "-" + $AzMonBackupSol.properties.outputs.templateDate.value)
        <#
        INCLUDE DRM
        ------------
        Deploy DRM for resources belonging to the monitoring service if the monitoring service is being deployed itself, and only then. This means that DRM can’t be added via the script after that the base deployment has been done.
        #>
        if ($IncludeDRM) {
                $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\parameters.json") -Raw | ConvertFrom-Json
                Write-Host ("azmon-delegatedrights-tmpl...") -ForegroundColor "White"
                $ContributorGroupId = $ParametersJSON.DRM.ContributorGroupId
                $MSPTenantId = $ParametersJSON.DRM.MSPTenantId 
                $TemplateContents = Get-Content -Path ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\parameters.json")
                $NewTemplateContents = $TemplateContents -replace "###MSPTenantID###", $MSPTenantID -replace "###ContributorGroupId###", $ContributorGroupId
                $NewTemplateContents | Out-File -FilePath ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\parameters.json") -Force  -Encoding ascii
                $AzMonDRM = (az deployment sub create `
                                --location "$Location" `
                                --template-file ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\template.json") `
                                --parameters ($AzMonLocalPath + "\azmon-delegatedrights-tmpl\_working\parameters.json") `
                                --name ("azmon-delegatedrights-" + $TemplateJSON.variables.TemplateVersion) ) `
                | ConvertFrom-Json
                Write-Host ("   " + $AzMonDRM.properties.provisioningState + " (" + $AzMonDRM.properties.correlationId + ")") -ForegroundColor "Gray"
                $ParametersJSON.Outputs.AzMonDRMTmpl = ( $AzMonDRM.properties.provisioningState + "-" + $AzMonDRM.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        } # End -IncludeDRM
} # End of DeployBaseSetup
<#
##########################################################################
# IncludeLinux (Base setup)
##########################################################################
Optionally the Azure Monitoring service also supports Linux machines hosted in Azure. Although the agent deployment policy (activated when the first resource group is added to monitoring) also supports Linux machines, the workspace still needs to be prepared for Linux monitoring. This is why we use this template. It does the following:
- Activates Syslog monitoring for
  - kern
  - daemon
  - cron
  - auth
  - syslog
- Activates performance counter collection for:
  - Memory
  - Logical Disk
  - Processor
  - Network
  - Process
#>
If ($IncludeLinux -and $WorkspaceName -ne "tbd" -and (-Not ($ParametersJSON.Outputs.azMonBasicLinuxTmpl.Contains("Succeeded")))) {
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-basiclinux-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-basiclinux-tmpl...") -ForegroundColor "White"
        $AzMonBasicLinux = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-basiclinux-tmpl\_working\template.json") `
                        --name ("azmon-basiclinux-" + $TemplateJSON.variables.TemplateVersion) `
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
        Write-Host ("   " + $AzMonBasicLinux.properties.provisioningState + " (" + $AzMonBasicLinux.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonBasicLinuxTmpl = ( $AzMonBasicLinux.properties.provisioningState + "-" + $AzMonBasicLinux.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
} # End of IncludeLinux for base setup
<#
##########################################################################
# NonAzureVMs
##########################################################################
Optionally the service can also monitor non-Azure VMs. Because our main grouping for Azure VMs is the resource group we need another way to group non-Azure VMs since they don't have a resource group they belong to. To solve this we created new alert rule queries, based on existing VMRules queries, that have an additional criteria. This additional criteria makes sure that only non-Azure VMs are taken into account for the query. The original queries check for the resource group name, for NonAzureVMs we replace this with _ResourceId = "". An empty ResourceIs means that the machine is not hosted in Azure and thus can be considered as non-Azure. This also means that ALL non-Azure VMs are conisdered as 1 group that is targetted with the same set of alert rules.

This section deploys these alert rules to the same resource group as where the workspace is hosted. The deployment is controlled by a swith to the script called NonAzureVMs. We don't deploy the rules by default because even if there's no non-Azure VM the presence of the rules will still incur costs each time the query is fired.

This template is used to deploy a set of monitoring rules that will be used for all virtual machines that are Non-Azure. These alert rules are stored in the same resource group as where the workspace resides. There's only 1 set of rules when it comes to non-azure virtual machine monitoring and that set contains the same rules as for monitoring virtual machines in a resource group.
#>
If ($NonAzureVMs) {
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-nonazurevms-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-nonazurevms-tmpl...") -ForegroundColor "White"
        $AzMonOnpremRules = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-nonazurevms-tmpl\_working\template.json") `
                        --name ("azmon-nonazurevms-" + $TemplateJSON.variables.TemplateVersion) `
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
        Write-Host ("   " + $AzMonOnpremRules.properties.provisioningState + " (" + $AzMonOnpremRules.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonNonAzureVMsTmpl = ($AzMonOnpremRules.properties.provisioningState + "-" + $AzMonOnpremRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $NonAzureVMsActionGroupId = $AzMonOnpremRules.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.nonAzureVMsActionGroupId = $NonAzureVMsActionGroupId
} # End of NonAzureVMs
<#
##########################################################################
# AddVMResGroup
##########################################################################
The resource group is the smallest collection that we use to identify resources to be monitored. What this means is that for each resource group that contains virtual machines to be monitored this part of the script will need to be executed. It deploys the following templates:
 - azmon-vmrules-tmpl
 - azmon-rschealth-tmpl
 - azmon-vault-tmpl
 - azmon-vmbkup-tmpl
The last template, azmon-vmbkup-tmpl, is used to add virtual machines to the backup. This template should be used for all machines that require backup by the backup vault that is hosted in the same resource group as the virtual machines themselves. 

The location of these templates is fixed in the script and the location starts with C:\Getronics\AzMon. Under this folder there should be a subfolder for each template. For the 1st one in the list this would then be C:\Getronics\AzMon\azmon-basic-tmpl. Below that folder there should be a '_working' folder that contains the actual template file. The process is the same for every template in the list. This folder setup is also used during developoment of the templates. In future versions we will probably get the templates from Github.

NOTE: The method of deployment for azmon-vmbkup-tmpl is different from all the other templates. See later in this script for more information.

Besides the template deployments there also the creation of a resource group that is done in this section of the script. This is the resource group that will contain or contains the virtual machines to be monitored. If the resource group already exists then the script will see this and retrieve the details of the group that are needed later in the script. The name of the resource group is part of the paramaters JSON file and should be changed in that location for every time this part of the script is executed for another resource group containing virtual machines to be monitored.
#>
If ($AddVMResGroup) {
        # This action created a resource group to host the virtual machines that will be monitored. If it already exists the script will just retrieve details needed later in the script.
        $VMResourceGroup = (az group create `
                        --name "$VMResourceGroupName" `
                        --location "$Location") `
        | ConvertFrom-Json
        Write-Host ("VM Resource Group: " + $VMResourceGroup.id) -ForegroundColor "White"
        <#
        VMRULES (azmon-vmrules-tmpl)
        -------------------------------
        This template is used to deploy a set of monitoring rules that will be used for all virtual machines in the resource group. These alert rules are stored in the resource group together with the virtual machines so that when the resource group gets decomissioned the alert rules are deleted also. Remember that we use log analytics to monitor the virtual machines and that before a virtual machines can be monitored by a log analytics workspace an agent needs to be installed on the virtual machine that reports to the workspace. That's why in this section of the script we also enable a policy-set (initiative) that is used to deploy the Microsoft Monitoring Agent (MMA) to all supported virtual machines in the resource group. The scope for the policy is the resource group which means that we will have a policy for every resource group containing virtual machines to be monitored. The policy contains a DeployIfNotExist action which means that we need credentials to perform the actual deployment. We leave it to Azure to create a managed identity for us but we need to give that identity rights to perform its actions. Two roles are given to the managed identity:
          - Contributor - scoped to resoruce group containing virtual machines
          - Log Analytics Contributor - scoped to resource group containig the log analytics workspace
        #>
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-vmrules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-vmrules-tmpl...") -ForegroundColor "White"
        $AzMonVMRules = (az deployment group create `
                        --resource-group "$VMResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-vmrules-tmpl\_working\template.json") `
                        --name ("azmon-vmrules-" + $TemplateJSON.variables.TemplateVersion) `
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
        Write-Host ("   " + $AzMonVMRules.properties.provisioningState + " (" + $AzMonVMRules.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonVMRulesTmpl = ($AzMonVMRules.properties.provisioningState + "-" + $AzMonVMRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $VMRulesActionGroupId = $AzMonVMRules.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.vmRulesActionGroupId = $VMRulesActionGroupId
        Write-Host ("   Adding DeployWinMMA policy assignment for " + $VMResourceGroupName)
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
        Write-Host ("     VM Role assignment: " + $VMRoleAssignment.id) -ForegroundColor "Gray"
        Start-Sleep -Seconds 15
        $ParametersJSON.Outputs.VMRoleAssignment = $VMRoleAssignment.id
        $RoleAssignment = (az role assignment create `
                        --role "Log Analytics Contributor" `
                        --assignee-object-id $Assignment.Identity.PrincipalId `
                        --scope $ParametersJSON.Outputs.azMonResGroupId) `
        | ConvertFrom-Json
        Write-Host ("     LANA Role assignment: " + $RoleAssignment.id) -ForegroundColor "Gray"
        $ParametersJSON.Outputs.LANARoleAssignment = $RoleAssignment.id
        <#
        RSCHEALTH (azmon-rschealth-tmpl)
        ------------------------------------
        The purpose of this template is to put all resources (alert rules and action groups) in place to monitor health of resources. Not every type of Azure resource emits health information but for those types who do this is an easy way to be kept aware of the health state of your individual resources.
        #>
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-rschealth-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-rschealth-tmpl...") -ForegroundColor "White"
        $AzMonRscHealth = (az deployment group create `
                        --resource-group "$VMResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-rschealth-tmpl\_working\template.json") `
                        --name ("azmon-rschealth-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonRscHealth.properties.provisioningState + " (" + $AzMonRscHealth.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonRSCHealthTmpl = ($AzMonRscHealth.properties.provisioningState + "-" + $AzMonRscHealth.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $RscHealthActionGroupId = $AzMonRscHealth.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.rscHealthActionGroupId = $RscHealthActionGroupId
        <#
        VAULT (azmon-vault-tmpl)
        ----------------------------
        This template is used to deploy a Azure Recovery Services vault together with diagnostics sent to a log analytics workspace. To complete the monitoring you must make sure that the backup solution is also configured in the choosen log analytics workspace.
        #>
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-vault-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-vault-tmpl...") -ForegroundColor "White"
        $instantRpRetentionRangeInDays = $ParametersJSON.Vault.instantRpRetentionRangeInDays
        $dailyRetentionDurationCount = $ParametersJSON.Vault.dailyRetentionDurationCount
        $weeklyRetentionDurationCount = $ParametersJSON.Vault.weeklyRetentionDurationCount
        $monthlyRetentionDurationCount = $ParametersJSON.Vault.monthlyRetentionDurationCount
        $yearlyRetentionDurationCount = $ParametersJSON.Vault.yearlyRetentionDurationCount
        $redundancyType = $ParametersJSON.Vault.redundancyType
        $AzMonVault = (az deployment group create `
                        --resource-group "$VMResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-vault-tmpl\_working\template.json") `
                        --name ("azmon-vault-" + $TemplateJSON.variables.TemplateVersion) `
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
        Write-Host ("   " + $AzMonVault.properties.provisioningState + " (" + $AzMonVault.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonVaultTmpl = ($AzMonVault.properties.provisioningState + "-" + $AzMonVault.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $BackupVaultName = $AzMonVault.properties.outputs.BackupVaultName.value
        $ParametersJSON.Outputs.backupVaultName = $BackupVaultName
        $BackupVaultId = $AzMonVault.properties.outputs.BackupVaultId.value
        $ParametersJSON.Outputs.backupVaultId = $BackupVaultId
        $VaultActionGroupId = $AzMonVault.properties.outputs.ActionGroupId.value
        $ParametersJSON.Outputs.vaultActionGroupId = $VaultActionGroupId
        <#
        IncludeLinux (VM rules)
        ------------------------
        #>
        If ($IncludeLinux -and $WorkspaceName -ne "tbd" -and $ParametersJSON.Outputs.azMonBasicLinuxTmpl.Contains("Succeeded")) {
                $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-vmlinuxrules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
                Write-Host ("azmon-vmlinuxrules-tmpl...") -ForegroundColor "White"
                $AzMonVMLinuxRules = (az deployment group create `
                                --resource-group "$VMResourceGroupName" `
                                --template-file ($AzMonLocalPath + "\azmon-vmlinuxrules-tmpl\_working\template.json") `
                                --name ("azmon-vmlinuxrules-" + $TemplateJSON.variables.TemplateVersion) `
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
                Write-Host ("   " + $AzMonVMLinuxRules.properties.provisioningState + " (" + $AzMonVMLinuxRules.properties.correlationId + ")") -ForegroundColor "Gray"
                $ParametersJSON.Outputs.azMonVMLinuxRulesTmpl = ($AzMonVMLinuxRules.properties.provisioningState + "-" + $AzMonVMLinuxRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        } # End of IncludeLinux for VM rules
        <#
        INCLUDE DRM
        -------------
        Deploying the azmon-delegatedvmrights-tmpl template will add the resource group containing the VM's
        to manage to the DRM setup. Members of the MSP tenant AD groups for which the Id is listed in the parameters file
        will then get Contributor rights to that resource group and ALL resources in it.
        #>
        if ($IncludeDRM) {
                $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\parameters.json") -Raw | ConvertFrom-Json
                Write-Host ("azmon-delegatedvmrights-tmpl...") -ForegroundColor "White"
                $VMContributorGroupId = $ParametersJSON.DRM.VMContributorGroupId
                $MSPTenantId = $ParametersJSON.DRM.MSPTenantId 
                $TemplateContents = Get-Content -Path ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\parameters.json")
                $NewTemplateContents = $TemplateContents -replace "###MSPTenantID###", $MSPTenantID -replace "###VMContributorGroupId###", $VMContributorGroupId -replace "###VMResGroup###", $VMResourceGroupName
                $NewTemplateContents | Out-File -FilePath ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\parameters.json") -Force  -Encoding ascii
                $AzMonVMDRM = (az deployment sub create `
                                --location "$Location" `
                                --template-file ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\template.json") `
                                --parameters ($AzMonLocalPath + "\azmon-delegatedvmrights-tmpl\_working\parameters.json") `
                                --name ("azmon-delegatedvmrights-" + $TemplateJSON.variables.TemplateVersion) ) `
                | ConvertFrom-Json
                Write-Host ("   " + $AzMonVMDRM.properties.provisioningState + " (" + $AzMonVMDRM.properties.correlationId + ")") -ForegroundColor "Gray"
                $ParametersJSON.Outputs.AzMonVMDRMTmpl = ($AzMonVMDRM.properties.provisioningState + "-" + $AzMonVMDRM.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        } # End -IncludeDRM
} # End AddVMResGroup
#
<#
##########################################################################
# IncludeVMBkUp
##########################################################################
The section to include VM's in the backup has been rewritten-. At first adding VM's to backup was done via an ARM template that was first edited via the powershell script. In a more recent version of the Azure CLI the az backup command was introduced which makes it possible to add a VM to backup via a simple commandline command.
#>
If ($IncludeVmBkup) {
        $VaultName = ("azmon" + $ParametersJSON.General.UniqueNumber + "-prod-bvlt")
        $PolicyName = $ParametersJSON.VMBkUp.backupPolicyName
        Write-Host ("Adding VMs to backup...") -ForegroundColor "White"
        Write-Host ("   Target vault RG name: " + $VMResourceGroupName) -ForegroundColor "White"
        Write-Host ("   Target vault name: " + $VaultName) -ForegroundColor "White"
        foreach ($vm in $ParametersJSON.VMBkUp.existingVirtualMachines) {
                Write-Host ("   Adding " + $vm + "...") -ForegroundColor "White" -NoNewline
                $AzMonVMBkUp = (az backup protection enable-for-vm `
                                --resource-group "$VMResourceGroupName" `
                                --vault-name "$VaultName" `
                                --vm "$vm" `
                                --policy-name "$Policyname" ) `
                | ConvertFrom-Json
                Write-Host ("     " + $AzMonVMBkUp.properties.status) -ForegroundColor "Gray"
        }
} # End IncludeVMBkUp
#

#
##########################################################################
# IncludeK8S (Kubernetes)
##########################################################################
#
If ($IncludeK8S -and $WorkspaceName -ne "tbd") {
        $K8SClusterName = $ParametersJSON.K8S.ClusterName
        $K8SClusterRGName = $ParametersJSON.K8S.ClusterRGName
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-k8srules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-k8srules-tmpl...") -ForegroundColor "White"
        $AzMonK8SRules = (az deployment group create `
                        --resource-group "$K8SClusterRGName" `
                        --template-file ($AzMonLocalPath + "\azmon-k8srules-tmpl\_working\template.json") `
                        --name ("azmon-k8srules-" + $TemplateJSON.variables.TemplateVersion) `
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
        Write-Host ("   " + $AzMonK8SRules.properties.provisioningState + " (" + $AzMonK8SRules.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonK8SRulesTmpl = ($AzMonK8SRules.properties.provisioningState + "-" + $AzMonK8SRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $ParametersJSON.Outputs.K8SClusterName = $K8SClusterName  
}
#
#
##########################################################################
# IncludeASR (Azure Site Recovery)
##########################################################################
#
$WorkspaceName = $ParametersJSON.Outputs.workspaceName
$azMonBasicASRTmpl = $ParametersJSON.Outputs.azMonBasicASRTmpl
If ($IncludeASR -and $WorkspaceName -ne "tbd" -and (-Not $azMonBasicASRTmpl.Contains("Succeeded"))) {
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-basicasr-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-basicasr-tmpl...") -ForegroundColor "White"
        $AzMonBasicASR = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-basicasr-tmpl\_working\template.json") `
                        --name ("azmon-basicasr-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "AMLWorkspaceName=$WorkspaceName" `
                        "AMLWorkspaceRGName=$ResourceGroupName" `
                        "dataRetention=$WorkspaceDataRetention" `
                        "Location=$LocationDisplayName" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonBasicASR.properties.provisioningState + " (" + $AzMonBasicASR.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonBasicASRTmpl = ($AzMonBasicASR.properties.provisioningState + "-" + $AzMonBasicASR.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
}
If ($IncludeASR -and $ParametersJSON.Outputs.azMonBasicASRTmpl.Contains("Succeeded")) {
        $ASRVaultName = $ParametersJSON.ASR.VaultName
        $ASRVaultRGName = $ParametersJSON.ASR.VaultRGName
        $ASRRPOCritical = $ParametersJSON.ASR.RPOCritical
        $ASRRPOWarning = $ParametersJSON.ASR.RPOWarning
        $ASRTestFailoverMissingThreshold = $ParametersJSON.ASR.TestFailoverMissingThreshold
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-asrrules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-asrrules-tmpl...") -ForegroundColor "White"
        $AzMonASRRules = (az deployment group create `
                        --resource-group "$ASRVaultRGName" `
                        --template-file ($AzMonLocalPath + "\azmon-asrrules-tmpl\_working\template.json") `
                        --name ("azmon-asrrules-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "ASRVaultName=$ASRVaultName" `
                        "ASRVaultRGName=$ASRVaultRGName" `
                        "AMLWorkspaceName=$WorkspaceName" `
                        "AMLWorkspaceRGName=$ResourceGroupName" `
                        "RPOCritical=$ASRRPOCritical" `
                        "RPOWarning=$ASRRPOWarning" `
                        "TestFailoverMissingThreshold=$ASRTestFailoverMissingThreshold" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonASRRules.properties.provisioningState + " (" + $AzMonASRRules.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonASRRulesTmpl = ($AzMonASRRules.properties.provisioningState + "-" + $AzMonASRRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $ParametersJSON.Outputs.ASRVaultName = $ASRVaultName
        Write-Host ("   Configuring diagnostics settings...") -ForegroundColor "White" -NoNewline
        $WorkspaceId = $ParametersJSON.Outputs.workspaceID
        $ASRDiagSet = '[{\"category\":\"AzureSiteRecoveryJobs\",\"enabled\": true},{\"category\":\"AzureSiteRecoveryEvents\",\"enabled\": true},{\"category\": \"AzureSiteRecoveryReplicatedItems\",\"enabled\": true},{\"category\":\"AzureSiteRecoveryReplicationStats\",\"enabled\": true},{    \"category\":\"AzureSiteRecoveryRecoveryPoints\",\"enabled\": true},{\"category\":\"AzureSiteRecoveryReplicationDataUploadRate\",\"enabled\": true},{\"category\":\"AzureSiteRecoveryProtectedDiskDataChurn\",\"enabled\": true}]'
        $ASRVaultId = (((((az backup vault show --name "$ASRVaultName"--resource-group "$ASRVaultRGName") -split "`n") | Where-Object { $_ -notmatch "etag" }) -join "`n") | ConvertFrom-Json).id
        $ASRDiagnostics = (az monitor diagnostic-settings create `
                        --name "$WorkspaceName" `
                        --resource "$ASRVaultId" `
                        --workspace "$WorkspaceId" `
                        --logs "$ASRDiagSet") `
        | ConvertFrom-Json
        Write-Host ($ASRDiagnostics.id) -ForegroundColor "Gray"
}
#
#
##########################################################################
# ASRserver (Azure Site Recovery)
##########################################################################
#
If ($ASRserver -and $ParametersJSON.Outputs.azMonBasicASRTmpl.Contains("Succeeded")) {
        $ASRVaultRGName = $ParametersJSON.ASR.VaultRGName
        $ASRvmName = $ParametersJSON.ASR.ASRvmName
        $ASRcacheDrive = $ParametersJSON.ASR.ASRcacheDrive
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-asrvmrules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-asrvmrules-tmpl...") -ForegroundColor "White"
        $AzMonASRVMRules = (az deployment group create `
                        --resource-group "$ASRVaultRGName" `
                        --template-file ($AzMonLocalPath + "\azmon-asrvmrules-tmpl\_working\template.json") `
                        --name ("azmon-asrvmrules-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "AZMONBasicRGName=$ResourceGroupName" `
                        "workspaceName=$WorkspaceName" `
                        "ASRvmName=$ASRvmName" `
                        "ASRcacheDrive=$ASRcacheDrive" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonASRVMRules.properties.provisioningState + " (" + $AzMonASRVMRules.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.ASRvmName = ($AzMonASRVMRules.properties.provisioningState + "-" + $AzMonASRVMRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
}
#
#
##########################################################################
# IncludeAFS (Azure File Sync)
##########################################################################
#
$WorkspaceName = $ParametersJSON.Outputs.workspaceName
$azMonBasicAFSTmpl = $ParametersJSON.Outputs.azMonBasicAFSTmpl
$ServerEndpoint = $ParametersJSON.AFS.ServerEndpoint
If ($IncludeAFS -and $WorkspaceName -ne "tbd" -and (-Not $azMonBasicAFSTmpl.Contains("Succeeded"))) {
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-basicfile-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-basicfile-tmpl...") -ForegroundColor "White"
        $AzMonBasicAFS = (az deployment group create `
                        --resource-group "$ResourceGroupName" `
                        --template-file ($AzMonLocalPath + "\azmon-basicfile-tmpl\_working\template.json") `
                        --name ("azmon-basicfile-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "AMLWorkspaceName=$WorkspaceName" `
                        "AMLWorkspaceRGName=$ResourceGroupName" `
                        "dataRetention=$WorkspaceDataRetention" `
                        "Location=$LocationDisplayName" `
                        "ServerEndpoint=$ServerEndpoint" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonBasicAFS.properties.provisioningState + " (" + $AzMonBasicAFS.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonBasicAFSTmpl = ($AzMonBasicAFS.properties.provisioningState + "-" + $AzMonBasicAFS.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
}
If ($IncludeAFS -and $ParametersJSON.Outputs.azMonBasicAFSTmpl.Contains("Succeeded")) {
        $AFSstorAcctName = $ParametersJSON.AFS.StorAcctName
        $AFSstorAcctRGName = $ParametersJSON.AFS.StorAcctRGName
        $AFSfileCapacityThresholdMBWarning = $ParametersJSON.AFS.FileCapacityThresholdMBWarning
        $AFSfileCapacityThresholdMBCritical = $ParametersJSON.AFS.FileCapacityThresholdMBCritical
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-filerules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-filerules-tmpl...") -ForegroundColor "White"
        $AzMonAFSRules = (az deployment group create `
                        --resource-group "$AFSstorAcctRGName" `
                        --template-file ($AzMonLocalPath + "\azmon-filerules-tmpl\_working\template.json") `
                        --name ("azmon-filerules-" + $TemplateJSON.variables.TemplateVersion) `
                        --parameters `
                        "Project=$TagProject" `
                        "Environment=$Environment" `
                        "storAcctName=$AFSstorAcctName" `
                        "fileCapacityThresholdMBWarning=$AFSfileCapacityThresholdMBWarning" `
                        "fileCapacityThresholdMBCritical=$AFSfileCapacityThresholdMBCritical" `
                        "AMLWorkspaceName=$WorkspaceName" `
                        "AMLWorkspaceRGName=$ResourceGroupName" `
                        "ServerEndpoint=$ServerEndpoint" `
                        "CreatedOn=$TagCreatedOn" `
                        "EndsOn=$TagEndsOn" `
                        "CreatedBy=$UserDisplayName" `
                        "OwnedBy=$TagOwnedBy") `
        | ConvertFrom-Json
        Write-Host ("   " + $AzMonAFSRules.properties.provisioningState + " (" + $AzMonAFSRules.properties.correlationId + ")") -ForegroundColor "Gray"
        $ParametersJSON.Outputs.azMonAFSRulesTmpl = ($AzMonAFSRules.properties.provisioningState + "-" + $AzMonAFSRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
        $ParametersJSON.Outputs.AFSstorAcctName = $AFSstorAcctName
}
#
#
##########################################################################
# IncludeNSG (Network Security Group)
##########################################################################
#
$WorkspaceName = $ParametersJSON.Outputs.workspaceName
$WorkspaceId = $ParametersJSON.Outputs.workspaceID
$NSGRulesFileLocation = $ParametersJSON.NSG.NSGRulesFileLocation
$NSGDiagSet = '[{\"category\":\"NetworkSecurityGroupEvent\",\"enabled\": true},{\"category\":\"NetworkSecurityGroupRuleCounter\",\"enabled\": true}]'

If ($IncludeNSG -and $WorkspaceName -ne "tbd" -and (Test-Path $NSGRulesFileLocation)) {
        $NSGRulesJSON = Get-Content -Path "$NSGRulesFileLocation" -Raw | ConvertFrom-Json
        $TemplateJSON = Get-Content -Path ($AzMonLocalPath + "\azmon-nsgrules-tmpl\_working\template.json") -Raw | ConvertFrom-Json
        Write-Host ("azmon-nsgrules-tmpl...") -ForegroundColor "White"
        foreach ($nsgrule in $NSGRulesJSON.nsgrules) {
                $NSGName = $nsgrule.NSGName
                $NSGRGName = $nsgrule.NSGRGName
                $NSGId = (((((az network nsg show --name "$NSGName"--resource-group "$NSGRGName") -split "`n") | Where-Object { $_ -notmatch "etag" }) -join "`n") | ConvertFrom-Json).id
                $NSGDiagnostics = (az monitor diagnostic-settings create `
                                --name "$WorkspaceName" `
                                --resource "$NSGId" `
                                --workspace "$WorkspaceId" `
                                --logs "$NSGDiagSet") `
                | ConvertFrom-Json
                if ($nsgrule.IPV4 -ne "") {
                        $NSGalertRuleName = "Network - NSG - {0} for {1} ({2})" -f $nsgrule.NSGRuleName, $nsgrule.IPV4, $nsgrule.NSGName
                }
                else {
                        $NSGalertRuleName = "Network - NSG - {0} for {1} ({2})" -f $nsgrule.NSGRuleName, ($nsgrule.Subnet -replace '/', '-'), $nsgrule.NSGName
                }
                if ($nsgrule.Log -eq "") {
                        $NSGRuleName = $nsgrule.NSGRuleName
                        $NSGRuleDescription = $nsgrule.Description
                        $NSGActionGroupName = $nsgrule.ActionGroupName
                        $NSGActionGroupRGName = $nsgrule.ActionGroupRGName
                        $NSGType = $nsgrule.Type
                        $NSGDirection = $nsgrule.Direction
                        $NSGIPV4 = $nsgrule.IPV4
                        $NSGSubnet = $nsgrule.Subnet
                        $NSGFrequency = $nsgrule.Frequency
                        $NSGThreshold = $nsgrule.Threshold
                        $NSGBreach = $nsgrule.Breach
                        $AzMonNSGRules = (az deployment group create `
                                        --resource-group "$NSGRGName" `
                                        --template-file ($AzMonLocalPath + "\azmon-nsgrules-tmpl\_working\template.json") `
                                        --name ("azmon-nsgrules-" + $TemplateJSON.variables.TemplateVersion) `
                                        --parameters `
                                        "Project=$TagProject" `
                                        "NSGName=$NSGName" `
                                        "NSGRuleName=$NSGRuleName" `
                                        "Description=$NSGRuleDescription" `
                                        "Direction=$NSGDirection" `
                                        "Type=$NSGType" `
                                        "IPV4=$NSGIPV4" `
                                        "Subnet=$NSGSubnet" `
                                        "Frequency=$NSGFrequency" `
                                        "Threshold=$NSGThreshold" `
                                        "Breach=$NSGBreach" `
                                        "NSGAlertRuleName=$NSGAlertRuleName" `
                                        "AZMONBasicRGName=$ResourceGroupName" `
                                        "workspaceName=$WorkspaceName" `
                                        "actionGroupName=$NSGActionGroupName" `
                                        "actionGroupRGName=$NSGActionGroupRGName" `
                                        "Environment=$Environment" `
                                        "CreatedOn=$TagCreatedOn" `
                                        "EndsOn=$TagEndsOn" `
                                        "CreatedBy=$UserDisplayName" `
                                        "OwnedBy=$TagOwnedBy") `
                        | ConvertFrom-Json
                        Write-Host ("   " + $NSGRuleName + "-" + $AzMonNSGRules.properties.provisioningState + " (" + $AzMonNSGRules.properties.correlationId + ")") -ForegroundColor "Gray"
                        $nsgrule.Log = ($AzMonNSGRules.properties.provisioningState + "-" + $AzMonNSGRules.properties.outputs.templateVersion.value + "-" + (Get-Date -Format "yyyyMMdd"))
                }
        }
        $NSGRulesJSON | ConvertTo-Json | Out-File -FilePath "$NSGRulesFileLocation" -Force -Encoding ascii
}
#
# The next line outputs the ParametersJSON variable, that was modified with some output data from the template deployments, backup to its original .json parameter file.
$ParametersJSON | ConvertTo-Json | Out-File -FilePath "$ParametersFile" -Force -Encoding ascii
