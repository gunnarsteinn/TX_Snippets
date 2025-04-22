# Power BI API Configuration - Default empty values
# Replace with Global Parameters in TimeXtender DQ
$appId = ""
$appSecret = ""
$tenantId = ""

# Try to import local configuration if it exists
# Remove this part when using in TimeXtender DQ
$localConfigPath = Join-Path $PSScriptRoot "..\\..\\Azure App Registration.local.ps1"
if (Test-Path $localConfigPath) {
    . $localConfigPath
}

# Get access token
function Get-PowerBIAccessToken {
    $tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
    $body = @{
        grant_type = "client_credentials"
        client_id = $appId
        client_secret = $appSecret
        scope = "https://analysis.windows.net/powerbi/api/.default"
    }
    $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $body
    return $response.access_token
}

# Execute DAX Query
function Invoke-PowerBIQuery {
    param(
        [string]$DaxQuery
    )
    
    $accessToken = Get-PowerBIAccessToken
    $endpointUrl = "https://api.powerbi.com/v1.0/myorg/groups/$groupId/datasets/$datasetId/executeQueries"
    
    $headers = @{
        Authorization = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }
    
    $daxQueryBody = @"
{
  "queries": [
    {
      "query": "$DaxQuery"
    }
  ],
  "serializerSettings": {
    "includeNulls": true
  }
}
"@
    
    $apiResponse = Invoke-RestMethod -Uri $endpointUrl -Method Post -Headers $headers -Body $daxQueryBody
    return $apiResponse.results.tables[0].rows
}