# Description: This script fetches JSON data from a URL and converts it to PowerShell objects.
$file = 'BCItems.json'
#$file = 'BCVendors.json'


$url = "https://raw.githubusercontent.com/gunnarsteinn/TX_Snippets/refs/heads/main/DQ/Demo/$file"
$results = Invoke-WebRequest -Uri $url -UseBasicParsing
$items = $results.Content | ConvertFrom-Json


$items #| Select-Object -Property No_,Description,"Unit Price","Unit Cost","Vendor No_"

