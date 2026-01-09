# ====== 1. Config ======
$tenantId     = ""
$clientId     = ""
$clientSecret = ""        
$workspaceId  = ""
$pipelineId   = ""             # GUID of the pipeline item
$pollIntervalSeconds = 10                             # How often to check status
$timeoutMinutes      = 60                             # Max time to wait

$scope = "https://analysis.windows.net/powerbi/api/.default"

# ====== 2. Get access token ======
$body = @{
    client_id     = $clientId
    scope         = $scope
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

try {
    $tokenResponse = Invoke-RestMethod `
        -Method Post `
        -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
        -Body $body `
        -ContentType "application/x-www-form-urlencoded" `
        -ErrorAction Stop
    
    $accessToken = $tokenResponse.access_token
    
    $headers = @{
        Authorization = "Bearer $accessToken"
    }
}
catch {
    Write-Error "Failed to obtain access token: $($_.Exception.Message)`n"
    if ($_.ErrorDetails.Message) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($errorDetails) {
            Write-Error "Error Code: $($errorDetails.error)`n"
            Write-Error "Description: $($errorDetails.error_description)`n"
        }
    }
    throw
}

# ====== 3. Trigger the pipeline ======
$jobType = "Pipeline"
$runUri  = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/items/$pipelineId/jobs/instances?jobType=$jobType"

# Optional: pipeline parameters
$payload = @{
    executionData = @{
        parameters = @{
            # MyParam = "value"
        }
    }
} | ConvertTo-Json -Depth 5

Write-Host "Starting pipeline run...`n"
try {
    $runResponse = Invoke-RestMethod -Method Post -Uri $runUri -Headers $headers -Body $payload -ContentType "application/json" -ErrorAction Stop
    
    # The response contains the job instance id
    $jobInstanceId = $runResponse.id
    Write-Host "Pipeline job instance id: $jobInstanceId`n"
}
catch {
    Write-Error "Failed to trigger pipeline run: $($_.Exception.Message)`n"
    
    # Try to parse the error response JSON
    if ($_.ErrorDetails.Message) {
        try {
            $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
            Write-Error "Request ID: $($errorDetails.requestId)`n"
            Write-Error "Error Code: $($errorDetails.errorCode)`n"
            Write-Error "Message: $($errorDetails.message)`n"
            
            if ($errorDetails.errorCode -eq "InsufficientPrivileges") {
                Write-Error "The service principal does not have sufficient permissions.`n"
                Write-Error "Required permissions: Workspace Contributor or Admin role in Fabric workspace.`n"
            }
        }
        catch {
            Write-Error "Raw error: $($_.ErrorDetails.Message)`n"
        }
    }
    
    throw
}

# ====== 4. Poll job status until finished or timeout ======
$statusUri = "https://api.fabric.microsoft.com/v1/workspaces/$workspaceId/items/$pipelineId/jobs/instances/$jobInstanceId"

$startTime = Get-Date
$deadline  = $startTime.AddMinutes($timeoutMinutes)

$finalStatus = $null
$failureReason = $null
$startTimeUtc = $null
$endTimeUtc   = $null

do {
    Start-Sleep -Seconds $pollIntervalSeconds

    try {
        $jobInstance = Invoke-RestMethod -Method Get -Uri $statusUri -Headers $headers -ErrorAction Stop

        # Normalize response in case API returns an array or a wrapper with an array
        $job = $jobInstance
        if ($jobInstance -is [System.Array]) {
            Write-Verbose "Status API returned array with $($jobInstance.Count) items; using first."
            $job = $jobInstance | Select-Object -First 1
        } elseif ($jobInstance.PSObject.Properties.Name -contains 'value' -and $jobInstance.value -is [System.Array]) {
            Write-Verbose "Status API returned wrapper with 'value' array; using latest by startTimeUtc."
            $job = $jobInstance.value | Sort-Object startTimeUtc -Descending | Select-Object -First 1
        } elseif ($jobInstance.PSObject.Properties.Name -contains 'items' -and $jobInstance.items -is [System.Array]) {
            Write-Verbose "Status API returned wrapper with 'items' array; using latest by startTimeUtc."
            $job = $jobInstance.items | Sort-Object startTimeUtc -Descending | Select-Object -First 1
        }

        $currentStatus = $job.status
        $startTimeUtc  = $job.startTimeUtc
        $endTimeUtc    = $job.endTimeUtc
        $failureReason = $job.failureReason

        Write-Host "Current status: $currentStatus (Started: $startTimeUtc, End: $endTimeUtc)`n"

        if ($currentStatus -in @("Completed","Failed","Cancelled")) {
            $finalStatus = $currentStatus
            break
        }
    }
    catch {
        Write-Warning "Error checking job status: $($_.Exception.Message)"
        
        # Try to parse the error response
        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Warning "Error Code: $($errorDetails.errorCode) - $($errorDetails.message)"
            }
            catch {
                Write-Warning "Raw error: $($_.ErrorDetails.Message)"
            }
        }
        
        # Continue polling in case it's a transient error
        # If it persists, the timeout will handle it
    }

     $now = Get-Date;
} while ($now -lt $deadline)

if (-not $finalStatus) {
    $finalStatus = "TimedOut"
    Write-Warning "Pipeline run did not finish within $timeoutMinutes minutes."
}

# ====== 5. Log outcome ======
Write-Host "================ Pipeline Run Result ================`n"
Write-Host "Job Instance Id : $jobInstanceId`n"
Write-Host "Status          : $finalStatus`n"
Write-Host "StartTimeUtc    : $startTimeUtc`n"
Write-Host "EndTimeUtc      : $endTimeUtc`n"

if ($failureReason) {
    Write-Host "FailureReason   : $failureReason`n"
}

# Make the script fail in CI/CD if the pipeline failed
if ($finalStatus -eq "Failed") {
    throw "Fabric pipeline failed. JobInstanceId=$jobInstanceId. Reason=$failureReason"
}
