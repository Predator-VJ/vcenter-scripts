<#
.SYNOPSIS
    Retrieves all Virtual Machines from a vCenter Server.
.DESCRIPTION
    Connects to a VMware vCenter Server and retrieves a list of all VMs
    with details such as Name, PowerState, NumCPU, MemoryGB, and Datastore.
.PARAMETER vCenterServer
    The FQDN or IP address of the vCenter Server.
.PARAMETER Credential
    PSCredential object for vCenter authentication.
.EXAMPLE
    .\Get-VCenterVMs.ps1 -vCenterServer 'vcenter.domain.local'
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$vCenterServer,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential
)

# Import VMware PowerCLI module
Import-Module VMware.PowerCLI -ErrorAction Stop
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

try {
    Write-Host "Connecting to vCenter: $vCenterServer" -ForegroundColor Cyan
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop

    Write-Host "Retrieving all Virtual Machines..." -ForegroundColor Cyan
    $vms = Get-VM | Select-Object Name, PowerState, NumCPU,
        @{N='MemoryGB';E={[math]::Round($_.MemoryGB,2)}},
        @{N='Datastore';E={(Get-Datastore -VM $_).Name -join ','}},
        @{N='Host';E={$_.VMHost.Name}}

    $vms | Format-Table -AutoSize
    $vms | Export-Csv -Path ".\VCenterVMs_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation
    Write-Host "Export complete." -ForegroundColor Green
}
catch {
    Write-Error "Failed: $_"
}
finally {
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false -ErrorAction SilentlyContinue
}
