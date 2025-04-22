[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = 'https://raw.githubusercontent.com/gunnarsteinn/staticwebapp/refs/heads/main/books.json'
$results = Invoke-WebRequest -Uri $url -UseBasicParsing
$items = $results.Content | ConvertFrom-Json
$items | Select-Object -Property ID,Name,Description,Price #| Where-Object {$_.Price -gt 20 }

