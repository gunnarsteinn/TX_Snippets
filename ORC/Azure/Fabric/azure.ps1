Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process
Import-Module Az.Accounts

$loadDate = Get-Date
$tenantId = "TENANTID"

$appId = "APPID"
$appSecret = "APPSECRET"


$secureSecret = ConvertTo-SecureString -String $appSecret -AsPlainText -Force
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $appId, $secureSecret
Connect-AzAccount -ServicePrincipal -TenantId $tenantId -Credential $credential | Out-Null

$subscriptions = Get-AzSubscription 



function exds-Get-Type 
{ 
    param($type) 
 
$types = @( 
'System.Boolean', 
'System.Byte[]', 
'System.Byte', 
'System.Char',  'System.Datetime', 
'System.Decimal', 
'System.Double', 
'System.Guid', 
'System.Int16', 
'System.Int32', 
'System.Int64', 
'System.Single', 
'System.UInt16', 
'System.UInt32', 
'System.UInt64') 
 
    if ( $types -contains $type ) { 
        Write-Output "$type"
    } 
    else { 
        Write-Output 'System.String' 
         
    } 
} #Get-Type 


function exds-Out-DataTable
{
    [CmdletBinding()]
    param([Parameter(Position = 0, Mandatory =$true, ValueFromPipeline = $true)] [PSObject[]]$InputObject) 

Begin 
{ 
    $dt = new-object Data.datatable
    $First = $true  
} 
Process 
{ 
    foreach ($object in $InputObject) 
    { 
        $DR = $DT.NewRow()   
        foreach($property in $object.PsObject.get_properties()) 
        {   
        	$columnName = $property.Name.ToString() -replace '\.', '_'
            if ($First) {
                    $Col = New-Object Data.DataColumn
                    $Col.ColumnName = $columnName
                    if ($property.Value) {
                        if ($property.Value -isnot [System.DBNull]) {
                            $Col.DataType = [System.Type]::GetType($(exds-Get-Type $property.TypeNameOfValue))
                        }
                    }
                    $DT.Columns.Add($Col)
                }
                if ($property.GetType().IsArray) {
                    $DR.Item($columnName) = $property.Value | ConvertTo-XML -As String -NoTypeInformation -Depth 1
                } else {
                    $DR.Item($columnName) = $property.Value
                }
        }   
        $DT.Rows.Add($DR)   
        $First = $false 
    } 
}  
  
End 
{ 
   # Write-Output @(, ($dt)) 
   Write-Output $dt
} 

}

$allResources = @()

foreach ($sub in $subscriptions) {
    Set-AzContext -Subscription $sub.Id | Out-Null


    $allResources += Get-AzResource | Select-Object -Property @(
        @{Name='LoadDate'; Expression={$loadDate}}
	    @{Name='SubscriptionName'; Expression={$sub.Name}}
	    @{Name='SubscriptionId'; Expression={$sub.Id}}	    
	    'ResourceGroupName'
	    'Name'
	    'ResourceId'
	    'ResourceType'
	    @{Name='Tags'; Expression={$_.Tags | ConvertTo-Json -Compress}}
	    
	)

}


$allResources| exds-Out-DataTable
