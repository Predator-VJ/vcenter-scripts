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
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null

try {
    Write-Host "Connecting to vCenter: $vCenterServer" -ForegroundColor Cyan
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop

    Write-Host "Retrieving all Virtual Machines..." -ForegroundColor Cyan

    # Build a single Id -> Name map so we don't call Get-Datastore once per VM.
    $datastoreMap = @{}
    foreach ($ds in (Get-Datastore)) {
        $datastoreMap[$ds.Id] = $ds.Name
    }

    $vms = Get-VM | Select-Object Name, PowerState, NumCPU,
        @{N='MemoryGB';  E={ [math]::Round($_.MemoryGB, 2) }},
        @{N='Datastore'; E={
            ($_.DatastoreIdList | ForEach-Object {
                if ($datastoreMap.ContainsKey($_)) { $datastoreMap[$_] } else { $_ }
            }) -join ','
        }},
        @{N='Host';      E={ $_.VMHost.Name }}

    $vms = @($vms)

    $vms | Format-Table -AutoSize
    $outputPath = ".\VCenterVMs_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $vms | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Host "Export complete. $($vms.Count) VM(s) written to $outputPath" -ForegroundColor Green
}
catch {
    Write-Error "Failed: $_"
}
finally {
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false -ErrorAction SilentlyContinue
}
