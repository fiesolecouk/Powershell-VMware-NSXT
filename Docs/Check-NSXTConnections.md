# KBA: Managing NSX-T Connections with the `Check-NSXTConnections` PowerShell Script

## Overview

The `Check-NSXTConnections` script is designed to manage NSX-T server connections within a VMware PowerCLI session. It performs the following tasks:

- **Lists Active Connections**: Retrieves and displays all active NSX-T connections.
- **Identifies the Default Connection**: Indicates which connection is currently set as default.
- **Interactive Default Selection**: In interactive mode, prompts the user to set a default connection if one isn’t already defined. If multiple connections exist, the user can select the desired default.
- **Return Object**: Provides a `PSCustomObject` that includes:
  - `AllConnections`: An array of all NSX-T connections.
  - `DefaultConnection`: The default connection (if set).
  - `Message`: A summary message regarding the default connection status.

## Prerequisites

- **VMware PowerCLI**: Ensure that VMware PowerCLI is installed.
- **NSX-T PowerCLI Module**: The script depends on the NSX-T PowerCLI module. Confirm that it’s imported and that the type `[VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer]` is available.
- **Sufficient Permissions**: You must have the appropriate permissions to view and modify NSX-T connections.
- **Execution Policy**: Your PowerShell execution policy should allow running scripts.

## Script Breakdown

### 1. Module Availability Check

The script begins by verifying that the NSX-T PowerCLI module is loaded. If it is not, an error is thrown:

    if (-not ([VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer] -as [type])) {
        Throw "NSX-T PowerCLI module is not loaded or NSX-T type is not available. Please import the module."
    }

### 2. Retrieve and Display Connections

The script fetches all active NSX-T connections and the default connection using the following commands:

    $allConnections = [VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer]::Servers
    $defaultConnection = [VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer]::DefaultServer

- **No Connections**:  
  If no connections exist (or if the `$allConnections` variable is empty), the script returns a `PSCustomObject` indicating that no NSX-T connections were found.

- **Existing Connections**:  
  If connections exist, the script loops through each connection and outputs details (such as the server and user) using `Write-Verbose`.

### 3. Default Connection Handling

- **Default Exists**:  
  If a default connection is already set, it is displayed using `Write-Verbose`.

- **No Default Exists**:  
  - In **Non-Interactive Mode** (when the `-NonInteractive` switch is used), the script skips prompting.  
  - In **Interactive Mode**, the script prompts the user to set a default connection:
    - The user is asked if they would like to set a default connection.
    - If the answer is `Y` or `y`:
      - If only one connection exists, that connection is automatically set as default.
      - If multiple connections exist, the user is prompted to select one by entering the corresponding index.
    - If an invalid choice is made, no default is set.

### 4. Return Object

Finally, the script returns a `PSCustomObject` that includes:

- `AllConnections`: An array of all NSX-T connections.
- `DefaultConnection`: The default connection (if any).
- `Message`: A summary message indicating the default connection status.

### 5. Example Verbose Logging Output (Multiple Connections Found and a Default Exists)

When running the `Check-NSXTConnections` script with the `-Verbose` switch and multiple NSX-T connections are found, with one already set as default, you might see output similar to this:

    PS C:\> Check-NSXTConnections -Verbose  
    VERBOSE: Existing NSX-T Connections:  
    VERBOSE: [1] Server: nsxt01.example.com; User: admin  
    VERBOSE: [2] Server: nsxt02.example.com; User: admin2  
    VERBOSE: Default NSX-T Connection: nsxt02.example.com (User: admin2)  
    VERBOSE: Default is set to nsxt02.example.com.

## Usage Examples

### Interactive Mode

To run the script in interactive mode (allowing user prompts), execute:

    $result = Check-NSXTConnections -Verbose
    $result.AllConnections
    $result.DefaultConnection
    $result.Message

### Non-Interactive Mode

To run the script in non-interactive mode (suppressing user prompts), execute:

    Check-NSXTConnections -NonInteractive -Verbose

## Troubleshooting

- **NSX-T Module Not Loaded**  
  If you see the error "NSX-T PowerCLI module is not loaded or NSX-T type is not available. Please import the module.", ensure that the NSX-T PowerCLI module is imported before running the script.

- **No Connections Found**  
  If the script indicates that no NSX-T connections exist, verify that you have established a connection using PowerCLI.

- **Invalid Input in Interactive Mode**  
  If an invalid choice is provided when selecting a connection index, no default is set. Enter a valid number corresponding to one of the available connections.

## Conclusion

The `Check-NSXTConnections` PowerShell script simplifies the management of NSX-T server connections within a PowerCLI session by providing an overview of active connections, identifying the default connection, and allowing interactive selection when needed.

For further assistance, please consult the [VMware PowerCLI Documentation](https://code.vmware.com/web/tool/11.4.0/vmware-powercli) or contact your system administrator.

