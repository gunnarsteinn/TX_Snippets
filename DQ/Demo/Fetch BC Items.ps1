# Description: This script fetches JSON data from a URL and converts it to PowerShell objects.
# Uncomment the file you want to fetch and make sure the other one is commented out.
$file = 'BCItems.json'
#$file = 'BCVendors.json'


$url = "https://raw.githubusercontent.com/gunnarsteinn/TX_Snippets/refs/heads/main/DQ/Demo/$file"
$results = Invoke-WebRequest -Uri $url -UseBasicParsing
$items = $results.Content | ConvertFrom-Json


# Optional: select specific columns and filter
#$items | Select-Object -Property No_,Description,"Unit Price","Unit Cost","Vendor No_" | Where-Object {$_."Unit Price" -gt 1}

# Just display the whole list
$items
