function Connect-NSXTEnvironment {
    <#
    .SYNOPSIS
        Connects to an NSX-T Manager with dynamic environment selection from JSON.

    .DESCRIPTION
        - Dynamically retrieves valid environments from `NSXT_ServerLookup.json`.
        - Uses `-Environment` (e.g., "Management", "Workload") to determine the correct server.
        - If no credentials are provided, tries stored credentials (-User $env:USERNAME).
        - If that fails, prompts for credentials (only on the first retry).
        - Implements a retry mechanism with fixed constants.
        - Uses Write-Verbose for detailed logging.
        - Returns a PSCustomObject with the connection status and session object.

    .PARAMETER Environment
        Specifies the NSX-T Manager environment. Must match a key in `NSXT_Servers` from the JSON.

    .PARAMETER Credential
        A PSCredential object with the username and password. If not provided, stored credentials are attempted.

    .EXAMPLE
        # Example 1: Connect to the Management NSX-T
        Connect-NSXEnvironment Management -Verbose

    .EXAMPLE
        # Example 2: Connect to the Workload NSX-T using explicit credentials
        $cred = Get-Credential
        Connect-NSXEnvironment Workload -Credential $cred -Verbose

    .NOTES
        Author: Your Name
        Date: YYYY-MM-DD
        Requires: VMware PowerCLI and an active NSX-T Manager.
    #>
    param(
        [Parameter(Position = 0, Mandatory = $true,
                   HelpMessage = "Select an NSX-T Manager environment (as defined in JSON).")]
        [string]$Environment,

        [Parameter(Mandatory = $false,
                   HelpMessage = "Enter credentials for the NSX-T Manager if needed.")]
        [PSCredential]$Credential
    )

    # JSON file path
    $jsonFilePath = ".\NSXT_ServerLookup.json"
    
    ### RETRY CONSTANTS ###
    $MaxRetries = 3
    $RetryDelay = 5
    $Timeout    = 60
    
    # Check existence of JSON file
    Write-Verbose "Checking for NSX-T Server JSON file..."
    if (-not (Test-Path $jsonFilePath)) {
        Write-Error "Server lookup JSON file not found: $jsonFilePath"
        return $null
    }

    Write-Verbose "Loading NSX-T Server environment JSON..."
    try {
        $serverLookup = Get-Content -Path $jsonFilePath | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to load JSON file: $_"
        return $null
    }

    # Validate JSON structure
    Write-Verbose "Validating JSON structure..."
    if (-not $serverLookup.PSObject.Properties.Name -contains "NSXT_Servers") {
        Write-Error "Invalid JSON structure: Missing 'NSXT_Servers' field."
        return $null
    }

    # Get valid environment names
    $validEnvironments = $serverLookup.NSXT_Servers.PSObject.Properties.Name
    if (-not $validEnvironments) {
        Write-Error "No valid environments found under 'NSXT_Servers' in the JSON file."
        return $null
    }

    # Validate user input
    if ($validEnvironments -notcontains $Environment) {
        Write-Error "Invalid environment '$Environment'. Must be one of: $($validEnvironments -join ', ')"
        return $null
    }

    Write-Verbose "Retrieving NSX-T Manager for environment '$Environment'..."
    $Server = $serverLookup.NSXT_Servers.$Environment

    # Check for VMware PowerCLI
    Write-Verbose "Checking for VMware PowerCLI module..."
    if (-not (Get-Module -ListAvailable -Name "VMware.PowerCLI")) {
        Write-Error "VMware PowerCLI module not found. Install via: Install-Module VMware.PowerCLI"
        return $null
    }

    $session   = $null
    $startTime = Get-Date
    $attempt   = 0

    while ($attempt -lt $MaxRetries -and (((Get-Date) - $startTime).TotalSeconds -lt $Timeout)) {
        Write-Verbose "Attempting connection to NSX-T Manager '$Server' (Attempt $($attempt + 1) of $MaxRetries)..."

        # Prompt for credentials only if stored credentials fail on first retry
        if (-not $Credential -and $attempt -eq 1) {
            Write-Verbose "Stored credentials failed previously. Prompting for new credentials..."
            $Credential = Get-Credential -Message "Enter NSX-T Manager credentials for $Server"
        }

        try {
            if ($Credential) {
                Write-Verbose "Using provided credentials..."
                $session = Connect-NsxtServer -Server $Server -User $Credential.UserName `
                           -Password $Credential.GetNetworkCredential().Password -SaveCredentials -ErrorAction Stop
            }
            else {
                Write-Verbose "Attempting stored credentials for user: $env:USERNAME..."
                $session = Connect-NsxtServer -Server $Server -User $env:USERNAME -ErrorAction Stop
            }

            if ($session) {
                Write-Verbose "Connection attempt succeeded."
                break
            }
        }
        catch {
            $errorMessage = $_.Exception.Message

            if ($errorMessage -match "403" -or $errorMessage -match "Permission denied") {
                Write-Verbose "Authentication failed: incorrect credentials or insufficient permissions."
            }
            elseif ($errorMessage -match "404" -or $errorMessage -match "could not be reached") {
                Write-Verbose "NSX-T Manager unreachable. Check firewall, DNS, or network connectivity."
            }
            else {
                Write-Verbose "Connection attempt failed: $_"
            }
        }

        Write-Verbose "Retrying in $RetryDelay seconds..."
        Start-Sleep -Seconds $RetryDelay
        $attempt++
    }

    if ($session) {
        Write-Verbose "Successfully connected to NSX-T Manager at '$Server'."
        return [PSCustomObject]@{
            Status  = "Success"
            Message = "Connected to NSX-T Manager at $Server."
            Session = $session
        }
    }
    else {
        Write-Verbose "Failed to connect to NSX-T Manager at '$Server' after $attempt attempt(s)."
        return [PSCustomObject]@{
            Status  = "Failed"
            Message = "Failed to connect to NSX-T Manager at $Server. Verify network connectivity, credentials, or server availability."
            Session = $null
        }
    }
}
