
# Add config here
$tenantId = ""
$appId = ""
$appSecret = ""
$Url = "https://api.businesscentral.dynamics.com/v2.0"


# Try to import local configuration if it exists
# Remove this part when using in TimeXtender DQ
$localConfigPath = Join-Path $PSScriptRoot "..\\Azure App Registration.local.ps1"
if (Test-Path $localConfigPath) {
    . $localConfigPath
}
function Get-AccessToken {
    param (
        [string]$tenantId,
        [string]$appId,
        [string]$appSecret
    )

    $Body = @{
        grant_type    = "client_credentials"
        client_id     = $appId
        client_secret = $appSecret
        scope         = "https://api.businesscentral.dynamics.com/.default"
    }

    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $Body
    return $TokenResponse.access_token
}

function Get-Companies {
    param (
        $Headers
    )

    $compUrl = "$Url/$Environment/api/v2.0/companies?tenant=$tenantId"
    $results = Invoke-RestMethod -Uri $compUrl -Headers $Headers -Method Get

    return $results.value
}

function Get-Action {
    param (        
    	[string]$Company,
        [string]$Action
    )

    $itemsUrl = "$Url/$Environment/api/v2.0/companies($CompanyId)/$Action"
    $results = Invoke-RestMethod -Uri $itemsUrl -Headers $Headers -Method Get

    return $results.value #| Select-Object -Property * -ExcludeProperty '@odata.etag'
}

$AccessToken = Get-AccessToken -tenantId $tenantId -appId $appId -appSecret $appSecret
$Headers = @{ Authorization = "Bearer $AccessToken" }

$Companies = Get-Companies -Headers $Headers