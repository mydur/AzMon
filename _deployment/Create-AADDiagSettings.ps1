param (
  [string]$TENANTID,
  [string]$SUBSCRIPTIONID,
  [string]$LANARG,
  [string]$LANANAME
)

Import-Module Az -Force
$LANAID = '/subscriptions/{0}/resourcegroups/{1}/providers/microsoft.operationalinsights/workspaces/{2}' -f $SUBSCRIPTIONID, $LANARG, $LANANAME
$SETTINGS_NAME = '$LANANAME'

$clientId = '1b730954-1685-4b74-9bfd-dac224a7b894' #built-in client id for "azure powershell"
$redirectUri = 'urn:ietf:wg:oauth:2.0:oob' #redirectUri for built-in client
$graphUri = 'https://management.core.windows.net'
$authority = 'https://login.microsoftonline.com/{0}' -f $TENANTID
$authContext = New-Object Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext -ArgumentList $authority

$authResult = $authContext.AcquireTokenAsync($graphUri, $clientId, $redirectUri, "Always")
$token = $authResult.AccessToken

$uri = 'https://management.azure.com/providers/microsoft.aadiam/diagnosticSettings/{0}?api-version=2017-04-01-preview' -f $SETTINGS_NAME

$body = @{
  id         = "/providers/microsoft.aadiam/providers/microsoft.insights/diagnosticSettings/{0}" -f $SETTINGS_NAME
  name       = $SETTINGS_NAME
  properties = @{
    logs        = @(
      @{
        category        = "AuditLogs"
        enabled         = $true
        retentionPolicy = @{
          days    = 0
          enabled = $false
        }
      },
      @{
        category        = "SignInLogs"
        enabled         = $true
        retentionPolicy = @{
          days    = 0
          enabled = $false
        }
      }
    )
    metrics     = @()
    workspaceId = $LANAID
  }
}

Invoke-WebRequest -Uri $uri -Body $(ConvertTo-Json $body -Depth 4) -Headers @{Authorization = "Bearer $token" } -Method Put -ContentType 'application/json'