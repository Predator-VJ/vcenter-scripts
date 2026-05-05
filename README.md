# vcenter-scripts

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![VMware](https://img.shields.io/badge/VMware-vCenter-brightgreen?logo=vmware)
![License](https://img.shields.io/badge/License-MIT-yellow)

A collection of PowerShell scripts for managing and automating VMware vCenter Server environments. These scripts leverage the **VMware PowerCLI** module to simplify day-to-day vCenter administration tasks.

---

## Prerequisites

- PowerShell 5.1 or PowerShell 7+
- VMware PowerCLI module installed:
  ```powershell
  Install-Module -Name VMware.PowerCLI -Scope CurrentUser
  ```
- Network access to your vCenter Server
- Valid vCenter credentials with appropriate privileges

---

## Scripts

| Script | Description |
|--------|-------------|
| [Get-VCenterVMs.ps1](./Get-VCenterVMs.ps1) | Retrieves all VMs with details (Name, CPU, RAM, Datastore, Host) and exports to CSV |
| [Manage-VMSnapshots.ps1](./Manage-VMSnapshots.ps1) | Creates or cleans up VM snapshots based on age threshold |
| [Get-VCenterAlarms.ps1](./Get-VCenterAlarms.ps1) | Reports all triggered alarms across the vCenter inventory |
| [Set-VMPowerState.ps1](./Set-VMPowerState.ps1) | Powers on or gracefully shuts down VMs in a cluster or datacenter |
| [Get-DatastoreCapacity.ps1](./Get-DatastoreCapacity.ps1) | Generates a datastore capacity report with usage warnings |

---

## Usage

### Get-VCenterVMs.ps1
Retrieves all Virtual Machines and exports a CSV report.
```powershell
$cred = Get-Credential
.\Get-VCenterVMs.ps1 -vCenterServer 'vcenter.domain.local' -Credential $cred
```

### Manage-VMSnapshots.ps1
Create snapshots for all VMs or clean up snapshots older than N days.
```powershell
# Clean up snapshots older than 7 days
.\Manage-VMSnapshots.ps1 -vCenterServer 'vcenter.domain.local' -Credential $cred -Action Cleanup -DaysOld 7

# Create snapshots for all VMs
.\Manage-VMSnapshots.ps1 -vCenterServer 'vcenter.domain.local' -Credential $cred -Action Create
```

### Get-VCenterAlarms.ps1
Retrieves all currently triggered alarms and exports them to CSV.
```powershell
.\Get-VCenterAlarms.ps1 -vCenterServer 'vcenter.domain.local' -Credential $cred
```

### Set-VMPowerState.ps1
Power on or shut down VMs in a specific cluster.
```powershell
# Shut down all VMs in a cluster
.\Set-VMPowerState.ps1 -vCenterServer 'vcenter.domain.local' -Credential $cred -Action Shutdown -ClusterName 'Prod-Cluster'

# Power on all VMs
.\Set-VMPowerState.ps1 -vCenterServer 'vcenter.domain.local' -Credential $cred -Action PowerOn
```

### Get-DatastoreCapacity.ps1
Generates a capacity report and warns if usage exceeds threshold.
```powershell
.\Get-DatastoreCapacity.ps1 -vCenterServer 'vcenter.domain.local' -Credential $cred -WarningThresholdPercent 85
```

---

## Notes

- All scripts automatically disconnect from vCenter after execution.
- SSL certificate warnings are suppressed using `-InvalidCertificateAction Ignore`. For production environments, configure proper certificates.
- Run scripts with an account that has the minimum required vCenter privileges.

---

## Author

**Predator-VJ** - PowerShell Scripting | IT SysAdmin | VMware Automation

---

## License

This project is licensed under the MIT License.
