$SubscriptionId = "a53c5946-e76d-4ca2-bee2-57cfbb3eee7a"
$TenantId = "9e087d00-55f5-4dc2-bcc4-cfdacca00ab5" 
$ClientID = "f5d40c6c-6822-46db-9eaa-e9e3f3a5a652"      
$ClientSecret = "1f358a23-14ed-4cd3-ba44-6af2e184d053"  
$TenantDomain = "contorso123.onmicrosoft.com" 
$LoginURL = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$AckThreshold = 3
$ClosedThreshold = 20
 
$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'


$AlertsApiUri = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.AlertsManagement/alerts?api-version=2018-05-05&timeRange=30d"

$Headers = @{ }
$Headers.Add("Authorization", "$($Token.token_type) " + " " + "$($Token.access_token)")

$Alerts = Invoke-RestMethod -Method Get -Uri $AlertsApiUri -Headers $Headers
$NumAcked = 0
$NumClosed = 0
Write-Host -NoNewLine "Working."
foreach ($Alert in $Alerts.value) {  
    $DiffInDays = ((Get-Date) - ($Alert.properties.essentials.lastModifiedDateTime -as [DateTime])).Days
    Write-Host -NoNewline "."
    If (($DiffInDays -gt $ClosedThreshold) -and ($Alert.properties.essentials.alertState -eq "Acknowledged")) {
        $AlertStateApiUri = "https://management.azure.com" + $Alert.id + "/changestate?api-version=2018-05-05&newState=Closed"
        $AlertStateApiUri
        $AlertState = Invoke-RestMethod -Method Post -Uri $AlertStateApiUri -Headers $Headers
        $NumClosed += 1
    }

    If (($DiffInDays -gt $AckThreshold) -and ($Alert.properties.essentials.alertState -eq "New")) {
        $AlertStateApiUri = "https://management.azure.com" + $Alert.id + "/changestate?api-version=2018-05-05&newState=Acknowledged"
        $AlertStateApiUri
        $AlertState = Invoke-RestMethod -Method Post -Uri $AlertStateApiUri -Headers $Headers
        $NumAcked += 1
    }
}
Write-Host "."
Write-Host -ForegroundColor Green "Closed: $NumClosed"
Write-Host -ForegroundColor Blue "Acked: $NumAcked" 