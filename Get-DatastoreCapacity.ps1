<#
.SYNOPSIS
    Generates a datastore capacity report from vCenter.
.DESCRIPTION
    Connects to VMware vCenter and retrieves capacity, free space, and usage
    percentage for all datastores. Exports the report to CSV.
.PARAMETER vCenterServer
    The FQDN or IP of the vCenter Server.
.PARAMETER Credential
    PSCredential for vCenter authentication.
.PARAMETER WarningThresholdPercent
    Percentage of used space to flag as warning. Default is 80.
.EXAMPLE
    .\Get-DatastoreCapacity.ps1 -vCenterServer 'vcenter.domain.local' -WarningThresholdPercent 85
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$vCenterServer,

    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential]$Credential,

    [int]$WarningThresholdPercent = 80
)

Import-Module VMware.PowerCLI -ErrorAction Stop
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null

try {
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop
    Write-Host "Gathering datastore capacity data..." -ForegroundColor Cyan

    $datastores = Get-Datastore | Select-Object Name,
        @{N='CapacityGB';E={[math]::Round($_.CapacityGB,2)}},
        @{N='FreeSpaceGB';E={[math]::Round($_.FreeSpaceGB,2)}},
        @{N='UsedSpaceGB';E={[math]::Round(($_.CapacityGB - $_.FreeSpaceGB),2)}},
        @{N='UsedPercent';E={[math]::Round((($_.CapacityGB - $_.FreeSpaceGB) / $_.CapacityGB) * 100, 1)}},
        Type, State

    foreach ($ds in $datastores) {
        if ($ds.UsedPercent -ge $WarningThresholdPercent) {
            Write-Host "[WARNING] $($ds.Name): $($ds.UsedPercent)% used ($($ds.FreeSpaceGB) GB free)" -ForegroundColor Red
        } else {
            Write-Host "[OK] $($ds.Name): $($ds.UsedPercent)% used ($($ds.FreeSpaceGB) GB free)" -ForegroundColor Green
        }
    }

    $outputPath = ".\DatastoreCapacity_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $datastores | Export-Csv -Path $outputPath -NoTypeInformation
    Write-Host "`nReport exported to: $outputPath" -ForegroundColor Cyan
}
catch {
    Write-Error "Failed to retrieve datastore info: $_"
}
finally {
    Disconnect-VIServer -Server $vCenterServer -Confirm:$false -ErrorAction SilentlyContinue
}
