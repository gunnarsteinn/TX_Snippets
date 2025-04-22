# Add config here
$tenantId = ""
$appId = ""
$appSecret = ""


# Try to import local configuration if it exists
# Remove this part when using in TimeXtender DQ
$localConfigPath = Join-Path $PSScriptRoot "..\\..\\..\\Azure App Registration.local.ps1"
if (Test-Path $localConfigPath) {
    . $localConfigPath
}

$subscriptionId = "XXXXXXXX" # Replace with your subscription ID
$resourceGroupName = "XXXXXXXX" # Replace with your resource group name
$capacityName = "avwfabric"
$operation = "resume" #$operation = "resume" # or "suspend" for pausing


# Get access token
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$body = @{
    grant_type    = "client_credentials"
    client_id     = $appId
    client_secret = $appSecret
    resource      = "https://management.azure.com/"
}
$response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body
$accessToken = $response.access_token

# Set API version and URI
$apiVersion = "2023-11-01"
$uri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Fabric/capacities/$capacityName/$operation`?api-version=$apiVersion"

# Set headers
$headers = @{
    Authorization  = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

# Send request
Invoke-RestMethod -Method Post -Uri $uri -Headers $headers