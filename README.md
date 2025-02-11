# NSX-T Scripts and Functions

A collection of PowerShell/PowerCLI scripts and functions designed to automate and standardize various **VMware NSX-T** operations. These scripts streamline tasks like connecting to NSX-T environments, creating and updating firewall rules, groups, IP sets, segments, gateways, and more.

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

1. **[Connect-NSXEnvironment](#connect-nsxenvironment)**
2. **[New-NSXTGateway](#new-nsxtgateway)**  

---

## Connect-NSXEnvironment

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
Connect-NSXEnvironment Management -Verbose

# Connect using explicit credentials
$cred = Get-Credential
Connect-NSXEnvironment Workload -Credential $cred -Verbose
