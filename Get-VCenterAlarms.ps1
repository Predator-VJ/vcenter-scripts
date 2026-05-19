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
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null

try {
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop
    Write-Host "Collecting triggered alarms..." -ForegroundColor Cyan

    # Pre-fetch only managed entities that actually have triggered alarms.
    # Using Get-View with a property filter avoids retrieving every folder/network/etc.
    $entities = Get-View -ViewType ManagedEntity -Property Name, TriggeredAlarmState |
        Where-Object { $_.TriggeredAlarmState -and $_.TriggeredAlarmState.Count -gt 0 }

    # Pre-fetch every alarm definition once into a hashtable keyed by MoRef
    # to avoid an N+1 Get-View call per triggered alarm.
    $alarmDefinitions = @{}
    foreach ($alarmView in (Get-View -ViewType Alarm -Property Info.Name)) {
        $alarmDefinitions[$alarmView.MoRef.ToString()] = $alarmView.Info.Name
    }

    # Build the result list using the pipeline (avoids the O(n^2) `+=` pattern).
    $alarms = foreach ($entity in $entities) {
        foreach ($triggered in $entity.TriggeredAlarmState) {
            $alarmKey  = $triggered.Alarm.ToString()
            $alarmName = if ($alarmDefinitions.ContainsKey($alarmKey)) {
                $alarmDefinitions[$alarmKey]
            } else {
                # Fallback if the alarm definition was added between fetches.
                (Get-View -Id $triggered.Alarm -Property Info.Name).Info.Name
            }

            # Friendly entity type derived from the MoRef (e.g. VirtualMachine, HostSystem).
            $entityType = $triggered.Entity.Type

            [PSCustomObject]@{
                Entity       = $entity.Name
                EntityType   = $entityType
                AlarmName    = $alarmName
                Status       = $triggered.OverallStatus
                Time         = $triggered.Time
                Acknowledged = $triggered.Acknowledged
            }
        }
    }

    # Force array semantics so .Count is reliable even with 0 or 1 result.
    $alarms = @($alarms)

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
