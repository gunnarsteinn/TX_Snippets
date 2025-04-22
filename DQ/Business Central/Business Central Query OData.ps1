$Environment = "Production"
$CompanyId = "bc22e2ab-8ba5-ea11-a818-000d3ad8e7d3"

. "$PSScriptRoot\Business Central Config.ps1"

Get-Action -Action "customers" -CompanyId $CompanyId |
 	Where-Object { $_.email -eq ""} |
 	Select-Object -Property number, displayname, type, country, email