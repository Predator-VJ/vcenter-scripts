<#
.SYNOPSIS
    Creates or removes snapshots for VMs in vCenter.
.DESCRIPTION
    Connects to VMware vCenter and either creates a snapshot for the
    specified VMs or removes snapshots older than a defined number of days.
.PARAMETER vCenterServer
    The FQDN or IP of the vCenter Server.
.PARAMETER Credential
    PSCredential for vCenter authentication.
.PARAMETER Action
    Either 'Create' or 'Cleanup'. Default is 'Cleanup'.
.PARAMETER VMName
    One or more VM names (wildcards supported). Required for 'Create'.
    Optional for 'Cleanup' (defaults to all VMs).
.PARAMETER DaysOld
    Number of days; snapshots older than this will be removed. Default is 7.
.EXAMPLE
    .\Manage-VMSnapshots.ps1 -vCenterServer 'vcenter.domain.local' -Action Cleanup -DaysOld 7
.EXAMPLE
    .\Manage-VMSnapshots.ps1 -vCenterServer 'vcenter.domain.local' -Action Create -VMName 'web-*','db01'
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$vCenterServer,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,

    [ValidateSet('Create','Cleanup')]
    [string]$Action = 'Cleanup',

    [string[]]$VMName,

    [ValidateRange(1, 3650)]
    [int]$DaysOld = 7
)

Import-Module VMware.PowerCLI -ErrorAction Stop
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null

# Guard rail: refuse to snapshot every VM in vCenter by accident.
if ($Action -eq 'Create' -and (-not $VMName -or $VMName.Count -eq 0)) {
    throw "The 'Create' action requires -VMName so you don't accidentally snapshot every VM in vCenter."
}

try {
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop

    $vms = if ($VMName) { Get-VM -Name $VMName } else { Get-VM }
    $vms = @($vms)

    if ($Action -eq 'Create') {
        foreach ($vm in $vms) {
            $snapName = "AutoSnap_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Snapshot -VM $vm -Name $snapName -Description 'Automated snapshot' -Confirm:$false | Out-Null
            Write-Host "Snapshot created for $($vm.Name): $snapName" -ForegroundColor Green
        }
    }
    elseif ($Action -eq 'Cleanup') {
        $cutoff   = (Get-Date).AddDays(-$DaysOld)
        $oldSnaps = @($vms | Get-Snapshot | Where-Object { $_.Created -lt $cutoff })

        if ($oldSnaps.Count -eq 0) {
            Write-Host "No snapshots older than $DaysOld days found." -ForegroundColor Yellow
        } else {
            foreach ($snap in $oldSnaps) {
                Write-Host "Removing snapshot: $($snap.Name) on $($snap.VM.Name)" -ForegroundColor Red
                Remove-Snapshot -Snapshot $snap -Confirm:$false
            }
            Write-Host "Cleanup complete. Removed $($oldSnaps.Count) snapshot(s)." -ForegroundColor Green
        }
    }
}
catch {
    Write-Error "Operation failed: $_"
}
finally {
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false -ErrorAction SilentlyContinue
}
