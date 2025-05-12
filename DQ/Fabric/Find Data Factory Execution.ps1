Import-Module Az

# TimeXtender Data Quality
# This script is used to find the latest execution of a Data Factory pipeline
# It uses the Azure PowerShell module to connect to Azure and retrieve pipeline run information
# Since the script requires Az module, it is required to run it through the TimeXtender Gateway

# Variables from your app registration
$tenantId = ""
$appId = ""
$appSecret = ""

# Try to import local configuration if it exists
# Remove this part when using in TimeXtender DQ
$localConfigPath = Join-Path $PSScriptRoot "..\\..\\Azure App Registration.local.ps1"
if (Test-Path $localConfigPath) {
    . $localConfigPath
}


$subscriptionId = ""
$dataFactoryName = ""
$resourceGroupName = ""

# Convert secret to secure string
$securePassword = ConvertTo-SecureString $appSecret -AsPlainText -Force
# Create credential object
$psCredential = New-Object System.Management.Automation.PSCredential ($appId, $securePassword)
# Authenticate as the service principal
Connect-AzAccount -ServicePrincipal -Credential $psCredential -Tenant $tenantId | Out-Null

Set-AzContext -SubscriptionId $subscriptionId | Out-Null
# List pipeline runs in a Data Factory
Get-AzDataFactoryV2PipelineRun    -ResourceGroupName $resourceGroupName     -DataFactoryName $dataFactoryName     -LastUpdatedAfter (Get-Date).AddDays(-700)     -LastUpdatedBefore (Get-Date) |
#Where-Object {$_.PipelineName -eq "pipe_f506_report" } | # -and $_.Status -ne "InProgress"} |
Sort-Object -Property RunStart -Descending |
Select-Object -First 10

