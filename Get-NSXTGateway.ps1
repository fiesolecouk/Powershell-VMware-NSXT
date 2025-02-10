<#
.SYNOPSIS
    Retrieves an NSX-T gateway (Tier-0 or Tier-1) by its display name or its ID.

.DESCRIPTION
    The Get-NSXTGateway cmdlet retrieves an NSX-T gateway from the NSX-T Manager by querying both the Tier-0
    and Tier-1 gateway services. It sets the NSX-T policy context (if the helper cmdlet Set-NsxtPolicyPath is available)
    using the provided Domain and GatewayPolicyId parameters. The cmdlet supports two parameter sets:
      - **ByName:** Retrieves the gateway based on its display name.
      - **ById:** Retrieves the gateway based on its NSX-T identifier.
    The function returns a PSCustomObject with:
      - **Action:** "Found", "NotFound", or "Error".
      - **Gateway:** The retrieved NSX-T gateway object (or $null if not found).
      - **Message:** A human-readable message describing the result.

.PARAMETER GatewayName
    The display name of the NSX-T gateway to retrieve.
    (Used in the "ByName" parameter set.)

.PARAMETER GatewayId
    The NSX-T identifier of the gateway to retrieve.
    (Used in the "ById" parameter set.)

.PARAMETER Domain
    (Optional) Specifies the NSX-T domain (project) in which to search for the gateway. The default is "default".

.PARAMETER GatewayPolicyId
    (Optional) Specifies the NSX-T gateway policy ID if applicable. The default is "default".

.INPUTS
    None. This cmdlet does not accept pipeline input.

.OUTPUTS
    A PSCustomObject with the following properties:
      - Action: "Found" if the gateway is retrieved, "NotFound" if it isn’t, or "Error" if an error occurs.
      - Gateway: The retrieved NSX-T gateway object (or $null).
      - Message: A descriptive message regarding the result.

.EXAMPLE
    # Example 1: Retrieve a gateway by its display name from the default domain.
    $result = Get-NSXTGateway -GatewayName "Edge Gateway"
    if ($result.Action -eq "Found") {
        Write-Output "Gateway found. ID: $($result.Gateway.id)"
    }
    else {
        Write-Warning $result.Message
    }

.EXAMPLE
    # Example 2: Retrieve a gateway by its ID from a specific project.
    $result = Get-NSXTGateway -GatewayId "gateway-12345" -Domain "ProjectA" -GatewayPolicyId "gw-policy-01"
    Write-Output $result

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Requires: NSX-T PowerCLI and an active NSX-T session (e.g., Connect-NsxtServer)
#>

function Get-NSXTGateway {
    [CmdletBinding(DefaultParameterSetName = "ByName", SupportsShouldProcess = $false)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "ByName", Position = 0, HelpMessage = "Enter the display name of the NSX-T gateway to retrieve.")]
        [string]$GatewayName,

        [Parameter(Mandatory = $true, ParameterSetName = "ById", Position = 0, HelpMessage = "Enter the ID of the NSX-T gateway to retrieve.")]
        [string]$GatewayId,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T domain (project) in which to search. Default is 'default'.")]
        [string]$Domain = "default",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T gateway policy ID if applicable. Default is 'default'.")]
        [string]$GatewayPolicyId = "default"
    )

    # Set the NSX-T policy context if the helper cmdlet is available.
    if (Get-Command -Name Set-NsxtPolicyPath -ErrorAction SilentlyContinue) {
        Set-NsxtPolicyPath -Domain $Domain -GatewayPolicy $GatewayPolicyId
        Write-Verbose "Set NSX-T policy path to Domain '$Domain', Gateway Policy '$GatewayPolicyId'."
    }
    else {
        Write-Verbose "Set-NsxtPolicyPath cmdlet not found. Ensure you are operating in the correct NSX-T project context."
    }

    # Retrieve Tier-0 Gateways.
    try {
        $tier0Service = Get-NsxtService -Name "com.vmware.nsx.tier-0s"
        $tier0Gateways = @()
        if ($tier0Service) {
            $tier0Gateways = $tier0Service.list().results
        }
    }
    catch {
        Write-Verbose "Error retrieving Tier-0 gateways: $_"
        $tier0Gateways = @()
    }

    # Retrieve Tier-1 Gateways.
    try {
        $tier1Service = Get-NsxtService -Name "com.vmware.nsx.tier-1s"
        $tier1Gateways = @()
        if ($tier1Service) {
            $tier1Gateways = $tier1Service.list().results
        }
    }
    catch {
        Write-Verbose "Error retrieving Tier-1 gateways: $_"
        $tier1Gateways = @()
    }

    # Combine Tier-0 and Tier-1 gateways.
    $allGateways = $tier0Gateways + $tier1Gateways
    Write-Verbose "Total gateways retrieved: $($allGateways.Count)"

    # Filter by ID or Name based on parameter set.
    if ($PSCmdlet.ParameterSetName -eq "ById") {
        $foundGateway = $allGateways | Where-Object { $_.id -eq $GatewayId }
    }
    else {
        $foundGateway = $allGateways | Where-Object { $_.display_name -eq $GatewayName }
    }

    if ($foundGateway) {
        return [PSCustomObject]@{
            Action  = "Found"
            Gateway = $foundGateway
            Message = "NSX-T gateway retrieved successfully."
        }
    }
    else {
        Write-Warning "No NSX-T gateway found using the provided criteria."
        return [PSCustomObject]@{
            Action  = "NotFound"
            Gateway = $null
            Message = "No NSX-T gateway found using the provided criteria."
        }
    }
}
