<#
.SYNOPSIS
    Checks for existing NSX-T server connections, optionally sets a default, and returns the connections.

.DESCRIPTION
    - Lists all active NSX-T connections in the PowerCLI session.
    - Displays which connection (if any) is the default.
    - If no default is set, optionally prompts the user to set one (interactive mode only).
    - If multiple connections exist, presents a selection menu (interactive mode only).
    - Returns a PSCustomObject containing:
      - AllConnections: Array of known NSX-T server connections.
      - DefaultConnection: The current default connection (if any).
      - Message: Summary output.

.NOTES
    Author: Your Name
    Requires: VMware PowerCLI, NSX-T PowerCLI

.EXAMPLE
    $result = Check-NSXTConnections -Verbose
    $result.AllConnections
    $result.DefaultConnection
    $result.Message

.EXAMPLE
    Check-NSXTConnections -NonInteractive -Verbose
#>

function Check-NSXTConnections {
    [CmdletBinding()]
    param(
        # When set, the script will not prompt the user for input.
        [switch]$NonInteractive
    )

    # Ensure that the NSX-T type is available.
    if (-not ([VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer] -as [type])) {
        Throw "NSX-T PowerCLI module is not loaded or NSX-T type is not available. Please import the module."
    }

    # Retrieve all active NSX-T connections and the default connection.
    $allConnections = [VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer]::Servers
    $defaultConnection = [VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer]::DefaultServer

    # Check if no connections exist.
    if (-not $allConnections -or $allConnections.Count -eq 0) {
        Write-Verbose "No existing NSX-T connections found."
        return [PSCustomObject]@{
            AllConnections    = @()
            DefaultConnection = $null
            Message           = "No existing NSX-T connections found."
        }
    }

    # Display NSX-T connections with index and user details.
    Write-Verbose "Existing NSX-T Connections:"
    for ($i = 0; $i -lt $allConnections.Count; $i++) {
        $conn = $allConnections[$i]
        $user = if ($conn.User) { $conn.User } else { "N/A" }
        Write-Verbose "[$($i+1)] Server: $($conn.Server); User: $user"
    }

    # Display the default connection if it exists.
    if ($defaultConnection) {
        Write-Verbose "Default NSX-T Connection: $($defaultConnection.Server) (User: $($defaultConnection.User))"
    }
    else {
        Write-Verbose "No default NSX-T connection is set."

        # If running in non-interactive mode, do not prompt the user.
        if ($NonInteractive) {
            Write-Verbose "Non-interactive mode enabled: Skipping prompt to set a default connection."
        }
        else {
            # Prompt the user to set a default connection.
            $response = Read-Host "Would you like to set a default connection now? (Y/N)"
            if ($response -match '^[Yy]$') {
                if ($allConnections.Count -eq 1) {
                    # Only one connection exists; set it automatically.
                    [VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer]::SetDefaultServer($allConnections[0])
                    Write-Verbose "Default connection set to: $($allConnections[0].Server)"
                    $defaultConnection = $allConnections[0]
                }
                else {
                    # Multiple connections available; prompt the user to select one.
                    Write-Verbose "Select the index of the connection to set as default:"
                    $choice = Read-Host "Enter a number between 1 and $($allConnections.Count)"

                    # Validate the user's input.
                    if ($choice -match '^\d+$' -and [int]$choice -le $allConnections.Count -and [int]$choice -gt 0) {
                        $chosenIndex = [int]$choice - 1
                        $chosenConn = $allConnections[$chosenIndex]
                        [VMware.VimAutomation.Vds.Types.Nsxt.NsxtServer]::SetDefaultServer($chosenConn)
                        Write-Verbose "Default connection set to: $($chosenConn.Server) (User: $($chosenConn.User))"
                        $defaultConnection = $chosenConn
                    }
                    else {
                        Write-Verbose "Invalid choice. No default connection was set."
                    }
                }
            }
            else {
                Write-Verbose "User opted not to set a default connection."
            }
        }
    }

    # Return a PSCustomObject with the connection details.
    return [PSCustomObject]@{
        AllConnections    = $allConnections
        DefaultConnection = $defaultConnection
        Message           = if ($defaultConnection) {
            "Default is set to $($defaultConnection.Server)."
        }
        else {
            "No default NSX-T connection is set."
        }
    }
}

