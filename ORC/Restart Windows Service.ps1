$serviceName = 'TimeXtender_Ingest_Service_6844.1'
 
try {
    # Check if the service exists
    $service = Get-Service -Name $serviceName -ErrorAction Stop | 
               Select-Object DisplayName, Status, @{label="NewStatus"; expression = {$_.Status}}
 
    # Restart the service
    Restart-Service -Name $serviceName -Force
 
    # Update status after restart
    $service.NewStatus = (Get-Service -Name $serviceName).Status
 
    # Return the service object with updated status
    $service
} catch {
    # Handle errors if the service does not exist or restart fails
    Throw "Could not restart the service '$serviceName'. Error: $_"
}
