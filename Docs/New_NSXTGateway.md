# KBA: Managing NSX-T Gateways with the `New-NSXTGateway` PowerShell Script

## Overview

The `New-NSXTGateway` script automates the creation of NSX‑T gateways based on the specified Tier ("tier0" or "tier1"). It checks if a gateway with the given display name already exists using `Get-NSXTGateway`. If found, it returns the existing gateway with an action of "Found" without making changes. Otherwise, if the operation is approved by `ShouldProcess` (or when using `-WhatIf`), the script retrieves a creation specification, populates it with the supplied parameters, and creates a new gateway.

## Purpose

- **Create or Update Gateways:**  
  The script either creates a new NSX‑T gateway or returns/updates an existing one based on the specified parameters.

- **Tier-Based Operation:**  
  Supports both Tier-0 and Tier-1 gateways by using different service methods depending on the value of the `Tier` parameter.

- **Conditional Execution:**  
  Utilizes PowerShell’s WhatIf functionality (and `ShouldProcess`) to simulate changes before applying them.

## Key Features

- **Existing Gateway Check:**  
  Uses `Get-NSXTGateway` to determine if a gateway with the specified `GatewayName` exists in the given domain and with the specified gateway policy.

- **Parameter Comparison and Force Update:**  
  If an existing gateway is found, the script returns it without changes. If parameters differ and the `-Force` switch is used, it updates the gateway accordingly.

- **Flexible Input Parameters:**  
  Accepts key parameters such as:
  - `GatewayName`: The display name for the gateway.
  - `Tier`: The gateway tier, with valid options "tier0" or "tier1".
  - `Description`: Optional description.
  - `Tags`: Optional array of tag objects.
  - `LinkedTier0Gateway`: (For Tier-1 gateways) ID of the linked Tier-0 gateway.
  - `Failover`: Failover mode ("Preemptive" or "non-preemptive").
  - `Cluster`: Cluster or cluster ID.
  - `Domain`: NSX‑T domain (default is "default").
  - `GatewayPolicyId`: Gateway policy ID (default is "default").

- **WhatIf Support:**  
  Simulates the creation of a gateway without making changes, allowing you to preview the outcome.

- **Verbose Logging and Error Handling:**  
  Provides detailed logging throughout the process and clear error messages if issues occur.

## Usage Examples

### Simulate Gateway Creation (WhatIf)

To simulate creating a new gateway without applying changes, run:

```powershell
New-NSXTGateway -GatewayName "Edge Gateway" -Tier "tier0" -Description "Primary Tier-0 gateway" `
                -Tags @(@{ scope = "environment"; tag = "production" }) -Failover "non-preemptive" -WhatIf -Verbose
```

### Create or Update a Gateway

To create a new gateway or update an existing one (forcing an update if parameters differ), run:

```powershell
New-NSXTGateway -GatewayName "Edge Gateway" -Tier "tier0" -Description "Primary Tier-0 gateway" `
                -Tags @(@{ scope = "environment"; tag = "production" }) -Failover "non-preemptive" -Verbose
```

## Troubleshooting

- **Service Retrieval Error:**  
  If the NSX‑T gateway service cannot be retrieved for the specified Tier, ensure that NSX‑T PowerCLI is correctly installed and that you are connected to the NSX‑T Manager.

- **Existing Gateway Conflict:**  
  If a gateway with the specified `GatewayName` already exists and no changes are made, verify that your input parameters are correct. Use the `-Force` switch to update the gateway if needed.

- **WhatIf Mode:**  
  When running with the `-WhatIf` switch, the script will simulate the creation process without applying any changes.

## Conclusion

The `New-NSXTGateway` script streamlines NSX‑T gateway management by automating the process of creating or updating gateways based on user-defined parameters. Its support for tier-specific operations, WhatIf simulations, and detailed logging makes it a valuable tool for administrators managing NSX‑T environments.
