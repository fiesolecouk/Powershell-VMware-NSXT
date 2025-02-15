# NSX-T Scripts and Functions

A collection of PowerShell/PowerCLI scripts and functions designed to automate and standardise various **VMware NSX-T** operations. These scripts streamline tasks like connecting to NSX-T environments, creating and updating firewall rules, groups, IP sets, segments, gateways, and more.

## Overview

This repository contains scripts that address different aspects of **NSX-T management**:

- **Connection/Environment** scripts for authenticating to NSX-T Managers.
- **Firewall scripts** for creating, updating, and retrieving sections and rules.
- **Grouping scripts** for managing NSX-T groups (dynamic or static).
- **IP set scripts** for handling IP addresses or ranges.
- **Segment and Gateway** scripts for network and routing constructs.

By leveraging **PowerCLI** and best practices, these scripts reduce administrative overhead and improve workflow consistency in NSX-T deployments.

---

## Contents

1. **[Connect-NSXTEnvironment](#connect-nsxtenvironment)**
2. **[Check-NSXTConnections](#check-nsxtconnections)**
3. **[New-NSXTGateway](#new-nsxtgateway)**  

---

## Connect-NSXTEnvironment

**Purpose**  
Authenticates to an NSX‑T Manager environment specified by environment name (e.g., "Management", "Workload"), loading environment/server details from a JSON lookup file.

**Key Features**  
- **JSON Lookup:** Loads environment → server mappings from `NSXT_ServerLookup.json`.  
- **Dynamic Environment Validation:** Blocks invalid environment inputs.  
- **Retry & Timeout:** Automatic connection retries with a defined delay and total timeout.  
- **Stored vs. Prompted Credentials:** Uses stored credentials if available; prompts if not.

**Usage**:
```powershell
# Connect to the "Management" environment
Connect-NSXTEnvironment Management -Verbose

# Connect using explicit credentials
$cred = Get-Credential
Connect-NSXTEnvironment Workload -Credential $cred -Verbose
```
## Check-NSXTConnections

**Purpose**
Check-NSXTConnections is a PowerShell script for VMware NSX-T PowerCLI that retrieves all active NSX-T connections, displays them, and interactively prompts you to set a default connection if one is not already set.

**Key Features**
- **Automatic Retrieval** – Collects all active NSX-T connections from the current PowerCLI session.
- **Interactive Selection** – Prompts to set a default connection when necessary.
- **Verbose Logging** – Supports detailed logging with `-Verbose` for easier troubleshooting.
- **Easy Integration** – Returns a structured object for use in automation scripts.

**Usage**:
```powershell
# Check what NSXT Connection are already established
$result = Check-NSXTConnections

# Returned output
$result.AllConnections       # List all active connections
$result.DefaultConnection    # Displays the default connection
$result.Message              # Summary of the connection status
```

## Final Notes

Feel free to **clone** this repository, **customise** these scripts, and **extend** them for your environment. Contributions are always welcome—please open an [issue](../../issues) or submit a [pull request](../../pulls) if you have any improvements or bug fixes. 


## Disclaimer

These scripts and any associated documentation (“Materials”) are provided “as is” and “as available,” without warranties or conditions of any kind, whether express or implied. By using the Materials, you agree and acknowledge the following:

1. You are solely responsible for determining the appropriateness of the Materials for your purposes and assume any risks associated with their use.
2. We make no representations or warranties regarding the Materials, including without limitation implied warranties of merchantability, fitness for a particular purpose, or non-infringement.
3. In no event shall we be liable for any claim, damages, or other liability—whether in contract, tort, or otherwise—arising from or connected with the Materials or your use of them.
4. You release us from all liability and agree to hold us harmless for any direct, indirect, incidental, or consequential damages associated with the use of the Materials.
