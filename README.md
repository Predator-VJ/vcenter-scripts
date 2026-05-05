<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0d1117,50:1a1a2e,100:163020&height=200&section=header&text=vCenter%20Scripts&fontSize=48&fontColor=00ff88&animation=fadeIn&fontAlignY=35&desc=Manage.%20Automate.%20Virtualize.&descAlignY=55&descSize=18&descColor=90ffc8" />

</div>

<div align="center">

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white)
![VMware](https://img.shields.io/badge/VMware%20vCenter-607078?style=for-the-badge&logo=vmware&logoColor=white)
![PowerCLI](https://img.shields.io/badge/VMware%20PowerCLI-00B388?style=for-the-badge&logo=vmware&logoColor=white)
![Scripts](https://img.shields.io/badge/Scripts-5-blueviolet?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=for-the-badge)

</div>

<br/>

<div align="center">
<img src="https://readme-typing-svg.demolab.com?font=JetBrains+Mono&weight=700&size=20&pause=1000&color=00FF88&center=true&vCenter=true&width=650&height=40&lines=🖥️+Virtual+Machine+Inventory+%26+Export;📸+Snapshot+Management+%26+Cleanup;🚨+vCenter+Alarm+Reporting;⚡+VM+Power+State+Control;💾+Datastore+Capacity+Monitoring" alt="Features" />
</div>

<br/>

---

## 📋 &nbsp;Script Arsenal

<div align="center">

| Script | Description | Category |
|--------|-------------|----------|
| `Get-VCenterVMs.ps1` | Retrieve all VMs with CPU, RAM, Datastore info → CSV | 🖥️ Inventory |
| `Manage-VMSnapshots.ps1` | Create or clean up snapshots by age threshold | 📸 Snapshots |
| `Get-VCenterAlarms.ps1` | Report all triggered alarms across vCenter | 🚨 Alarms |
| `Set-VMPowerState.ps1` | Power on or gracefully shut down VMs | ⚡ Power |
| `Get-DatastoreCapacity.ps1` | Monitor datastore usage & free space | 💾 Storage |

</div>

---

## ⚙️ &nbsp;Prerequisites

- PowerShell 5.1 or PowerShell 7+
- VMware PowerCLI module installed:

```powershell
Install-Module -Name VMware.PowerCLI -Scope CurrentUser
```

- Network access to your vCenter Server
- Valid vCenter credentials with appropriate privileges

---

## 🚀 &nbsp;Quick Start

```powershell
# Clone the repository
git clone https://github.com/Predator-VJ/vcenter-scripts.git
cd vcenter-scripts

# Connect to vCenter first
Connect-VIServer -Server <your-vcenter-fqdn>

# Run any script
.\Get-VCenterVMs.ps1
.\Manage-VMSnapshots.ps1
.\Get-VCenterAlarms.ps1
```

---

## 👤 &nbsp;Author

<div align="center">

**Vikas Joshi** — IT SysAdmin | VMware vCenter & ESXi Engineer

[![GitHub](https://img.shields.io/badge/GitHub-Predator--VJ-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Predator-VJ)

</div>

<div align="center">
<img src="https://capsule-render.vercel.app/api?type=waving&color=0:163020,50:1a1a2e,100:0d1117&height=120&section=footer" />
</div>
