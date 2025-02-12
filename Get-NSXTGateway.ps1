function New-NSXTGateway {
    <#
    .SYNOPSIS
        Creates an NSX-T gateway (Tier-0 or Tier-1) using NSX-T PowerCLI service methods.

    .DESCRIPTION
        This cmdlet creates a new NSX-T gateway using the appropriate NSX-T service
        based on the specified Tier ("tier0" or "tier1"). It accepts parameters for Tags,
        LinkedTier0Gateway (for Tier-1 gateways), failover mode, and cluster.
        
        The cmdlet calls the Get-NSXTGateway cmdlet to check if a matching gateway already exists
        (searching by GatewayName only). If found, it returns the existing gateway with an action of "Found"
        and makes no changes. Otherwise, if the ShouldProcess check passes (including -WhatIf), it proceeds with creation.

    .PARAMETER GatewayName
        The display name for the gateway.

    .PARAMETER Tier
        Specifies the gateway tier. Valid options are "tier0" or "tier1".

    .PARAMETER Description
        (Optional) A description for the gateway.

    .PARAMETER Tags
        (Optional) An array of tag objects for the gateway.

    .PARAMETER LinkedTier0Gateway
        (Optional) For Tier-1 gateways, the ID of the linked Tier-0 gateway.

    .PARAMETER Failover
        Specifies the failover mode for the gateway. Valid options are "Preemptive" or "non-preemptive".
        The default is "non-preemptive".

    .PARAMETER Cluster
        (Optional) The cluster (or cluster ID) to associate with the gateway.

    .PARAMETER Domain
        (Optional) Specifies the NSX-T domain (project) in which the gateway exists. Default is "default".

    .PARAMETER GatewayPolicyId
        (Optional) Specifies the NSX-T gateway policy ID. Default is "default".

    .EXAMPLE
        # Example 1: Create a new Tier-0 gateway.
        $result = New-NSXTGateway -GatewayName "Edge Gateway" -Tier "tier0" -Description "Primary Tier-0 gateway" `
                   -Tags @(@{ scope="environment"; tag="production" }) -Failover "non-preemptive" -Verbose
        Write-Output $result

    .EXAMPLE
        # Example 2: Return an existing Tier-1 gateway by display name without making any changes.
        $result = New-NSXTGateway -GatewayName "Branch Gateway" -Tier "tier1" -Verbose
        Write-Output $result

    .EXAMPLE
        # Example 3: Simulate (WhatIf) creation of a new Tier-0 gateway.
        $result = New-NSXTGateway -GatewayName "New Gateway" -Tier "tier0" -Description "Test gateway" `
                   -Failover "non-preemptive" -WhatIf -Verbose
        Write-Output $result

    .NOTES
        Author: Your Name
        Date: YYYY-MM-DD
        Requires: NSX-T PowerCLI and an active NSX-T session (e.g., Connect-NsxtServer)
    #>

    [CmdletBinding(DefaultParameterSetName = "Default", ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Enter the display name for the gateway.")]
        [string]$GatewayName,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the gateway tier. Valid options are 'tier0' or 'tier1'.")]
        [ValidateSet("tier0", "tier1")]
        [string]$Tier,
        
        [Parameter(Mandatory = $false, HelpMessage = "Enter an optional description for the gateway.")]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false, HelpMessage = "An array of tag objects for the gateway.")]
        [object[]]$Tags,
        
        [Parameter(Mandatory = $false, HelpMessage = "For Tier-1 gateways, the ID of the linked Tier-0 gateway.")]
        [string]$LinkedTier0Gateway,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the failover mode for the gateway. Valid options are 'Preemptive' or 'non-preemptive'.")]
        [ValidateSet("Preemptive", "non-preemptive")]
        [string]$Failover = "non-preemptive",
        
        [Parameter(Mandatory = $false, HelpMessage = "The cluster (or cluster ID) to associate with the gateway.")]
        [string]$Cluster,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T domain (project) in which the gateway exists. Default is 'default'.")]
        [string]$Domain = "default",
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T gateway policy ID. Default is 'default'.")]
        [string]$GatewayPolicyId = "default"
    )

    Write-Verbose "Starting New-NSXTGateway process..."
    Write-Verbose "Received parameters: GatewayName='$GatewayName', Tier='$Tier', Description='$Description', Domain='$Domain', GatewayPolicyId='$GatewayPolicyId'."

    # Check ShouldProcess (handles WhatIf) once.
    if (-not $PSCmdlet.ShouldProcess("NSX-T Gateway", "Creating gateway '$GatewayName'")) {
        Write-Verbose "WhatIf mode enabled. Simulation only."
        return [PSCustomObject]@{
            Action  = "WhatIf"
            ID      = "WHATIF-GATEWAY-ID"
            Message = "[WhatIf] Would create NSX-T gateway '$GatewayName' with description '$Description' in Tier '$Tier'."
        }
    }

    Write-Verbose "Skipping NSX-T policy context setup as it is not used in this script."

    Write-Verbose "Checking for an existing NSX-T gateway using Get-NSXTGateway (search by GatewayName)..."
    $existingResult = Get-NSXTGateway -GatewayName $GatewayName -Domain $Domain -GatewayPolicyId $GatewayPolicyId -Verbose
    Write-Verbose "Existing gateway check returned action: '$($existingResult.Action)'."

    if ($existingResult.Action -eq "Found") {
        Write-Verbose "NSX-T gateway '$($existingResult.Gateway.display_name)' already exists. No changes will be made."
        return [PSCustomObject]@{
            Action  = "Found"
            ID      = $existingResult.Gateway.id
            Message = "NSX-T gateway '$($existingResult.Gateway.display_name)' already exists. No changes made."
        }
    }

    Write-Verbose "No existing gateway found. Proceeding with creation."
    Write-Verbose "Selecting the appropriate NSX-T gateway service based on Tier '$Tier'..."
    if ($Tier -eq "tier0") {
        try {
            $gwService = Get-NsxtService -Name "com.vmware.nsx.tier-0s"
            Write-Verbose "Retrieved Tier-0 gateway service successfully."
        }
        catch {
            Write-Error "Error retrieving Tier-0 gateway service: $_"
            return [PSCustomObject]@{
                Action  = "Error"
                ID      = $null
                Message = "Error retrieving Tier-0 gateway service: $_"
            }
        }
    }
    else {
        try {
            $gwService = Get-NsxtService -Name "com.vmware.nsx.tier-1s"
            Write-Verbose "Retrieved Tier-1 gateway service successfully."
        }
        catch {
            Write-Error "Error retrieving Tier-1 gateway service: $_"
            return [PSCustomObject]@{
                Action  = "Error"
                ID      = $null
                Message = "Error retrieving Tier-1 gateway service: $_"
            }
        }
    }

    if (-not $gwService) {
        Write-Error "NSX-T gateway service for Tier '$Tier' not found."
        return [PSCustomObject]@{
            Action  = "Error"
            ID      = $null
            Message = "NSX-T gateway service for Tier '$Tier' not found."
        }
    }
    Write-Verbose "NSX-T gateway service for Tier '$Tier' found. Service ID: $($gwService.Id)"

    Write-Verbose "Retrieving gateway creation specification..."
    try {
        if ($Tier -eq "tier0") {
            $gwSpec = $gwService.Help.create.tier_0_router.Create()
            Write-Verbose "Using Tier-0 creation specification."
        }
        else {
            $gwSpec = $gwService.Help.create.tier_1_router.Create()
            Write-Verbose "Using Tier-1 creation specification."
        }
    }
    catch {
        Write-Error "Error retrieving gateway creation specification: $_"
        return [PSCustomObject]@{
            Action  = "Error"
            ID      = $null
            Message = "Error retrieving gateway creation specification: $_"
        }
    }

    Write-Verbose "Populating creation specification with supplied parameters..."
    $gwSpec.display_name = $GatewayName
    Write-Verbose "Set display_name to '$GatewayName'."
    if ($Description) {
        $gwSpec.description = $Description 
        Write-Verbose "Set description to '$Description'."
    }
    if ($Tags) {
        $gwSpec.tags = $Tags 
        Write-Verbose "Set tags to '$(ConvertTo-Json $Tags)'."        
    }
    if (($Tier -eq "tier1") -and $LinkedTier0Gateway) {
        $gwSpec.linked_tier0_gateway = @{ target_id = $LinkedTier0Gateway; target_type = "Tier0" }
        Write-Verbose "Set linked_tier0_gateway to ID '$LinkedTier0Gateway'."
    }
    if ($PSBoundParameters.ContainsKey("Failover")) {
        $gwSpec.failover_mode = $Failover 
        Write-Verbose "Set failover_mode to '$Failover'."
    }
    if ($Cluster) {
        $gwSpec.cluster = $Cluster 
        Write-Verbose "Set cluster to '$Cluster'."
    }

    Write-Verbose "Attempting to create the new NSX-T gateway..."
    try {
        $newGateway = $gwService.create($gwSpec)
        Write-Verbose "Gateway '$($newGateway.display_name)' created successfully with ID '$($newGateway.id)'."
        return [PSCustomObject]@{
            Action  = "Created"
            ID      = $newGateway.id
            Message = "NSX-T gateway '$($newGateway.display_name)' created successfully."
        }
    }
    catch {
        Write-Error "Error creating NSX-T gateway: $_"
        return [PSCustomObject]@{
            Action  = "Error"
            ID      = $null
            Message = "Error creating NSX-T gateway: $_"
        }
    }
}
