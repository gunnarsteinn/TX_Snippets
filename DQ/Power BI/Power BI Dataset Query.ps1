<#
.SYNOPSIS
    Queries a Power BI dataset using DAX and filters the results.
    For use in TimeXtender Data Quality (DQ) projects.

.DESCRIPTION
    This script connects to a Power BI dataset using service principal authentication
    and executes a DAX query. It then filters and formats the results.

    Usage:
    - Add the Power BI Config as a Query Snippet in TimeXtender Data Quality (DQ)
    - Add the $appId, $appSecret, $tenantId as Global Parameters in TimeXtender DQ and refer to them in the Query Snippet
    - Create a new Test Query in TimeXtender DQ that first defines the $groupId and $datasetId, then refers to the Query Snippet with {Query Snippet Name} but removing the . "$PSScriptRoot\Power BI Config.ps1" part and then has the rest of the script


.PARAMETER groupId
    The Power BI workspace (group) ID where the dataset is located

.PARAMETER datasetId
    The ID of the dataset to query

.EXAMPLE
    .\Power BI Dataset Query.ps1
    Executes the query and returns filtered results where Quantity equals 42

.NOTES
    Requires Power BI Config.ps1 and Power BI Config.local.ps1 with valid credentials
#>


# The Power BI workspace (group) ID and dataset ID
$groupId = "cab20807-dc6f-4bf5-8144-dabfab21c934"
$datasetId = "3c36052e-daf8-4eff-864b-b5c4f568f877"

# Import the configuration and functions
# In TimeXtender DQ, this should be added as a Query Snippet
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