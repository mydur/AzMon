$SubscriptionId = Get-AutomationVariable -Name "General_SubscriptionId"
$TenantId = Get-AutomationVariable -Name "General_TenantId"
$ClientID = Get-AutomationVariable -Name "General_ClientId"
$ClientSecret = Get-AutomationVariable -Name "General_ClientSecret"
$AckThreshold = Get-AutomationVariable -Name "AlertLifeCycle_AckThreshold"
$ClosedThreshold = Get-AutomationVariable -Name "AlertLifeCycle_CloseThreshold"

Write-Output "AckThreshold: $AckThreshold"
Write-Output "ClosedThreshold: $ClosedThreshold"

$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'
$AlertsApiUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.AlertsManagement/alerts?api-version=2018-05-05&timeRange=30d"
$Headers = @{ }
$Headers.Add("Authorization", "$($Token.token_type) " + " " + "$($Token.access_token)")

$Alerts = Invoke-RestMethod -Method Get -Uri $AlertsApiUri -Headers $Headers
$NumAcked = 0
$NumClosed = 0
foreach ($Alert in $Alerts.value) {  
    $DiffInDays = ((Get-Date) - ($Alert.properties.essentials.lastModifiedDateTime -as [DateTime])).Days

    If (($DiffInDays -gt $ClosedThreshold) -and ($Alert.properties.essentials.alertState -eq "Acknowledged")) {
        $AlertStateApiUri = "https://management.azure.com" + $Alert.id + "/changestate?api-version=2018-05-05&newState=Closed"
        $AlertState = Invoke-RestMethod -Method Post -Uri $AlertStateApiUri -Headers $Headers
        $NumClosed += 1
    }

    If (($DiffInDays -gt $AckThreshold) -and ($Alert.properties.essentials.alertState -eq "New")) {
        $AlertStateApiUri = "https://management.azure.com" + $Alert.id + "/changestate?api-version=2018-05-05&newState=Acknowledged"
        $AlertState = Invoke-RestMethod -Method Post -Uri $AlertStateApiUri -Headers $Headers
        $NumAcked += 1
    }

}

Write-Output "Closed: $NumClosed"
Write-Output "Acked: $NumAcked"