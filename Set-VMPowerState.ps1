<#
.SYNOPSIS
    Powers on or shuts down Virtual Machines in vCenter.
.DESCRIPTION
    Connects to a vCenter Server and performs a power-on or graceful shutdown
    on all VMs in a specified cluster or datacenter.
.PARAMETER vCenterServer
    The FQDN or IP of the vCenter Server.
.PARAMETER Credential
    PSCredential for vCenter authentication.
.PARAMETER Action
    'PowerOn' or 'Shutdown'. Default is 'PowerOn'.
.PARAMETER ClusterName
    Optional. Target a specific cluster. If omitted, all VMs are targeted.
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

    [string]$ClusterName = ''
)

Import-Module VMware.PowerCLI -ErrorAction Stop
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

try {
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop

    if ($ClusterName -ne '') {
        $vms = Get-Cluster -Name $ClusterName | Get-VM
    } else {
        $vms = Get-VM
    }

    foreach ($vm in $vms) {
        if ($Action -eq 'PowerOn' -and $vm.PowerState -ne 'PoweredOn') {
            Write-Host "Powering on: $($vm.Name)" -ForegroundColor Green
            Start-VM -VM $vm -Confirm:$false -RunAsync
        }
        elseif ($Action -eq 'Shutdown' -and $vm.PowerState -eq 'PoweredOn') {
            Write-Host "Shutting down: $($vm.Name)" -ForegroundColor Yellow
            if ($vm.ExtensionData.Guest.ToolsRunningStatus -eq 'guestToolsRunning') {
                Shutdown-VMGuest -VM $vm -Confirm:$false
            } else {
                Stop-VM -VM $vm -Confirm:$false -RunAsync
            }
        } else {
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
