
# Define the list of servers and ports as combined entries
$targets = @(
    @{Host = "auth0.com"; Port = 443},
    @{Host = "eu.auth0.com"; Port = 443},
    @{Host = "cdn.auth0.com"; Port = 443},
    @{Host = "login.exmon.com"; Port = 443},
    @{Host = "login.timextender.com"; Port = 443},
    @{Host = "sql-exmon-prod-001.database.windows.net"; Port = 1433},
    @{Host = "sql-instances-prod.database.windows.net"; Port = 1433},
    @{Host = "app.timextender.com"; Port = 443},
    @{Host = "app-encryption-prod-001.azurewebsites.net"; Port = 443},
    @{Host = "sbns-customer-prod-001.servicebus.windows.net"; Port = 5671},
    @{Host = "sbns-customer-prod-001.servicebus.windows.net"; Port = 5672}

)

# Loop through each target (combined host and port)
foreach ($target in $targets) {
    $result = Test-NetConnection -ComputerName $target.Host -Port $target.Port -WarningAction SilentlyContinue

    if ($result.TcpTestSucceeded) {
        Write-Host "Server: $($target.Host), Port: $($target.Port) - Open" -ForegroundColor Green
    } else {
        Write-Host "Server: $($target.Host), Port: $($target.Port) - Closed" -ForegroundColor Red
    }
}

Pause

