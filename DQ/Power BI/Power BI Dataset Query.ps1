
$groupId = "cab20807-dc6f-4bf5-8144-dabfab21c934"
$datasetId = "3c36052e-daf8-4eff-864b-b5c4f568f877"

# Import the configuration and functions
. "$PSScriptRoot\Power BI Config.ps1"


# Define your DAX query
$evaluate = "EVALUATE FILTER('Sheet', 'Sheet'[LineTotal] < 1)"

# Execute the query
$PowerBIResults = Invoke-PowerBIQuery -DaxQuery $evaluate

# Process the results
$PowerBIResults | 
    Where-Object { $_."Sheet[Quantity]" -eq 42 } | 
    Select-Object @{
        Name="SalesOrderId"; 
        Expression={$_."Sheet[SalesOrderId]"}
    },
    @{
        Name="Quantity"; 
        Expression={$_."Sheet[Quantity]"}
    },
    @{
        Name="LineTotal"; 
        Expression={$_."Sheet[LineTotal]"}
    }