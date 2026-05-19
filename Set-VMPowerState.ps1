<#
.SYNOPSIS
    Powers on or shuts down Virtual Machines in vCenter.
.DESCRIPTION
    Connects to a vCenter Server and performs a power-on or graceful guest
    shutdown on all VMs in a specified cluster (or all VMs if no cluster is
    given). When VMware Tools is not running on a VM and -ForceStopIfNoTools
    is supplied, falls back to a hard power-off; otherwise the VM is skipped
    with a warning.
.PARAMETER vCenterServer
    The FQDN or IP of the vCenter Server.
.PARAMETER Credential
    PSCredential for vCenter authentication.
.PARAMETER Action
    'PowerOn' or 'Shutdown'. Default is 'PowerOn'.
.PARAMETER ClusterName
    Optional. Target a specific cluster. If omitted, all VMs are targeted.
.PARAMETER ForceStopIfNoTools
    For 'Shutdown' only. If VMware Tools is not running, hard-power-off the VM
    instead of skipping. Off by default to avoid unexpected forced shutdowns.
.EXAMPLE
    .\Set-VMPowerState.ps1 -vCenterServer 'vcenter.domain.local' -Action Shutdown -ClusterName 'Prod-Cluster'
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$vCenterServer,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,

    [ValidateSet('PowerOn','Shutdown')]
    [string]$Action = 'PowerOn',

    [string]$ClusterName = '',

    [switch]$ForceStopIfNoTools
)

Import-Module VMware.PowerCLI -ErrorAction Stop
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null

try {
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop

    $vms = if ($ClusterName -ne '') {
        Get-Cluster -Name $ClusterName | Get-VM
    } else {
        Get-VM
    }
    $vms = @($vms)

    foreach ($vm in $vms) {
        if ($Action -eq 'PowerOn' -and $vm.PowerState -ne 'PoweredOn') {
            Write-Host "Powering on: $($vm.Name)" -ForegroundColor Green
            Start-VM -VM $vm -Confirm:$false -RunAsync | Out-Null
        }
        elseif ($Action -eq 'Shutdown' -and $vm.PowerState -eq 'PoweredOn') {
            $toolsRunning = $vm.ExtensionData.Guest.ToolsRunningStatus -eq 'guestToolsRunning'

            if ($toolsRunning) {
                Write-Host "Gracefully shutting down: $($vm.Name)" -ForegroundColor Yellow
                Shutdown-VMGuest -VM $vm -Confirm:$false | Out-Null
            }
            elseif ($ForceStopIfNoTools) {
                Write-Warning "VMware Tools not running on $($vm.Name); forcing hard power-off."
                Stop-VM -VM $vm -Confirm:$false -RunAsync | Out-Null
            }
            else {
                Write-Warning "Skipping $($vm.Name): VMware Tools not running. Use -ForceStopIfNoTools to power off anyway."
            }
        }
        else {
            Write-Host "Skipping $($vm.Name) - already in desired state." -ForegroundColor Gray
        }
    }
    Write-Host "$Action operation complete for $($vms.Count) VM(s)." -ForegroundColor Cyan
}
catch {
    Write-Error "Power operation failed: $_"
}
finally {
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false -ErrorAction SilentlyContinue
}
