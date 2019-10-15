$SubscriptionId = "a53c5946-e76d-4ca2-bee2-57cfbb3eee7a"
$TenantId       = "9e087d00-55f5-4dc2-bcc4-cfdacca00ab5" 
$ClientID       = "c6abb8bc-5488-44ee-9871-300845596c2f"      
$ClientSecret   = "lkLr-I/rmXRt?82zt04*ZT7.hs3[Nf1h"  
$TenantDomain   = "contorso123.onmicrosoft.com" 
$loginURL       = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$resource       = "https://api.loganalytics.io"         
 
$body           = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth          = Invoke-RestMethod -Method Post -Uri $loginURL -Body $body
$headerParams   = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}
 
$Workspacename  = "azmon-test-lana"
$WorkspaceId    = "1d2a0a7d-354d-4e6a-ad93-8510fbf45537"
  
$url = "https://api.loganalytics.io/v1/workspaces/$WorkspaceId/query"
$body = @{"query" = "Heartbeat | summarize arg_max(TimeGenerated, *) by Computer | project Computer , ComputerIP , OSType , Version , ResourceGroup , ResourceId , ResourceType , TimeGenerated"; "timespan" = "P1M" } | ConvertTo-Json
$result = Invoke-RestMethod -UseBasicParsing -Headers $headerParams -Uri $url -Method Post -Body $body -ContentType "application/json"

$headerRow = $null
$headerRow = $result.tables.columns | Select-Object name
$columnsCount = $headerRow.Count
# Format the Report
$logData = @()
foreach ($row in $result.tables.rows) {
    $data = new-object PSObject
    for ($i = 0; $i -lt $columnsCount; $i++) {
        $data | add-member -membertype NoteProperty -name $headerRow[$i].name -value $row[$i]
    }
    $logData += $data
    $data = $null
}
$logData | ConvertTo-Json | Out-File "C:\Getronics\AZScripts\PS\lanaexp.json"