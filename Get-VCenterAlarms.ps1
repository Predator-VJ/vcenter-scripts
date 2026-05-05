<#
.SYNOPSIS
    Retrieves all triggered alarms from a vCenter Server.
.DESCRIPTION
    Connects to vCenter and reports all currently triggered alarms across
    datacenters, clusters, hosts, and VMs. Exports the results to a CSV file.
.PARAMETER vCenterServer
    The FQDN or IP of the vCenter Server.
.PARAMETER Credential
    PSCredential for vCenter authentication.
.EXAMPLE
    .\Get-VCenterAlarms.ps1 -vCenterServer 'vcenter.domain.local'
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$vCenterServer,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential
)

Import-Module VMware.PowerCLI -ErrorAction Stop
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

try {
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop
    Write-Host "Collecting triggered alarms..." -ForegroundColor Cyan

    $alarms = @()
    $entities = Get-Inventory

    foreach ($entity in $entities) {
        $triggeredAlarms = $entity.ExtensionData.TriggeredAlarmState
        foreach ($alarm in $triggeredAlarms) {
            $alarmInfo = [PSCustomObject]@{
                Entity      = $entity.Name
                EntityType  = $entity.GetType().Name
                AlarmName   = (Get-View $alarm.Alarm).Info.Name
                Status      = $alarm.OverallStatus
                Time        = $alarm.Time
                Acknowledged = $alarm.Acknowledged
            }
            $alarms += $alarmInfo
        }
    }

    if ($alarms.Count -eq 0) {
        Write-Host "No triggered alarms found." -ForegroundColor Green
    } else {
        $alarms | Format-Table -AutoSize
        $outputPath = ".\VCenterAlarms_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $alarms | Export-Csv -Path $outputPath -NoTypeInformation
        Write-Host "Exported $($alarms.Count) alarm(s) to $outputPath" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Failed to retrieve alarms: $_"
}
finally {
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false -ErrorAction SilentlyContinue
}
