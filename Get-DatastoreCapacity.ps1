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

    [ValidateRange(1, 100)]
    [int]$WarningThresholdPercent = 80
)

Import-Module VMware.PowerCLI -ErrorAction Stop
# Use Session scope so we don't permanently change the user's PowerCLI config.
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false | Out-Null

try {
    Connect-VIServer -Server $vCenterServer -Credential $Credential -ErrorAction Stop
    Write-Host "Gathering datastore capacity data..." -ForegroundColor Cyan

    $datastores = Get-Datastore | ForEach-Object {
        $capacity  = [double]$_.CapacityGB
        $freeSpace = [double]$_.FreeSpaceGB

        # Guard against division-by-zero for inaccessible/unmounted datastores.
        $usedPercent = if ($capacity -gt 0) {
            [math]::Round((($capacity - $freeSpace) / $capacity) * 100, 1)
        } else {
            $null
        }

        [PSCustomObject]@{
            Name        = $_.Name
            CapacityGB  = [math]::Round($capacity, 2)
            FreeSpaceGB = [math]::Round($freeSpace, 2)
            UsedSpaceGB = [math]::Round(($capacity - $freeSpace), 2)
            UsedPercent = $usedPercent
            Type        = $_.Type
            State       = $_.State
            Accessible  = $_.ExtensionData.Summary.Accessible
        }
    }

    foreach ($ds in $datastores) {
        if ($null -eq $ds.UsedPercent) {
            Write-Host "[SKIP] $($ds.Name): capacity unknown (Accessible=$($ds.Accessible))" -ForegroundColor DarkYellow
        }
        elseif ($ds.UsedPercent -ge $WarningThresholdPercent) {
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
