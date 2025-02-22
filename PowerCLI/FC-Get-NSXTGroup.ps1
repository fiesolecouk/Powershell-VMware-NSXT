<#
.SYNOPSIS
    Retrieves an NSX-T group by display name.

.DESCRIPTION
    The FC-Get-NSXTGroup cmdlet retrieves an NSX-T group from the NSX-T Manager using the NSX-T PowerCLI service.
    It sets the NSX-T policy path (if the helper cmdlet Set-NsxtPolicyPath is available) based on the provided domain and gateway policy,
    then queries the NSX-T groups service for a group matching the specified display name. The cmdlet returns a standardized PSCustomObject
    with the following properties:
      - Action: "Found", "NotFound", or "Error"
      - Group: The NSX-T group object if found; otherwise, $null.
      - Message: A descriptive message.
      - Error: (Optional) Error details if an error occurred.

.PARAMETER GroupName
    The display name of the NSX-T group to retrieve.

.PARAMETER Domain
    (Optional) Specifies the NSX-T domain (project) in which to search for the group. Default is "default".

.PARAMETER GatewayPolicyId
    (Optional) Specifies the NSX-T gateway policy ID if required. Default is "default".

.INPUTS
    None. This cmdlet does not accept pipeline input.

.OUTPUTS
    A PSCustomObject with the properties: Action, Group, Message, and optionally Error.

.EXAMPLE
    # Retrieve a group named "Web Servers" from the default NSX-T domain.
    $result = FC-Get-NSXTGroup -GroupName "Web Servers"
    if ($result.Action -eq "Found") {
        Write-Output "Found group with ID: $($result.Group.id)"
    }
    else {
        Write-Warning $result.Message
    }

.EXAMPLE
    # Retrieve a group named "DB Servers" from a specific NSX-T project.
    $result = FC-Get-NSXTGroup -GroupName "DB Servers" -Domain "ProjectDB" -GatewayPolicyId "gw-policy-01"
    Write-Output $result

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Requires: NSX-T PowerCLI and an active NSX-T session (e.g., Connect-NsxtServer)
#>

# Enable strict mode for best practices
Set-StrictMode -Version Latest

function FC-Get-NSXTGroup {
    [CmdletBinding(ConfirmImpact='Low', SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter the display name for the group to retrieve.")]
        [ValidateNotNullOrEmpty()]
        [string]$GroupName,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T domain (project) to search in. Default is 'default'.")]
        [string]$Domain = "default",
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T gateway policy ID if required. Default is 'default'.")]
        [string]$GatewayPolicyId = "default"
    )
    
    Write-Verbose "Starting FC-Get-NSXTGroup with GroupName '$GroupName', Domain '$Domain', GatewayPolicyId '$GatewayPolicyId'."
    Write-Debug "Initializing NSX-T group retrieval process."

    # Set the NSX-T policy path for multi-project support if available.
    if (Get-Command -Name Set-NsxtPolicyPath -ErrorAction SilentlyContinue) {
        try {
            Set-NsxtPolicyPath -Domain $Domain -GatewayPolicy $GatewayPolicyId
            Write-Verbose "Set NSX-T policy path to Domain '$Domain', Gateway Policy '$GatewayPolicyId'."
            Write-Debug "Policy path set successfully."
        }
        catch {
            $errorMsg = "Failed to set NSX-T policy path: $_"
            Write-Error $errorMsg
            return [PSCustomObject]@{
                Action  = "Error"
                Group   = $null
                Message = $errorMsg
                Error   = $_
            }
        }
    }
    else {
        Write-Verbose "Set-NsxtPolicyPath cmdlet not found. Ensure you are in the correct NSX-T project context."
        Write-Debug "Set-NsxtPolicyPath cmdlet missing; skipping policy path configuration."
    }
    
    # Retrieve the NSX-T groups service.
    try {
        $groupsvc = Get-NsxtService -Name "com.vmware.nsx.groups"
        Write-Debug "Retrieved NSX-T groups service."
    }
    catch {
        $errorMsg = "Error retrieving NSX-T groups service: $_"
        Write-Error $errorMsg
        return [PSCustomObject]@{
            Action  = "Error"
            Group   = $null
            Message = $errorMsg
            Error   = $_
        }
    }
    
    if (-not $groupsvc) {
        $errorMsg = "NSX-T groups service not found."
        Write-Error $errorMsg
        return [PSCustomObject]@{
            Action  = "Error"
            Group   = $null
            Message = $errorMsg
            Error   = "Service not found"
        }
    }
    Write-Verbose "NSX-T groups service found. Service ID: $($groupsvc.Id)"
    Write-Debug "NSX-T groups service details: $(ConvertTo-Json $groupsvc -Depth 3)"
    
    # Retrieve the list of existing groups.
    try {
        $groupsResponse = $groupsvc.list()
        Write-Debug "NSX-T groups list retrieved."
        if ($groupsResponse -and $groupsResponse.results) {
            $group = $groupsResponse.results | Where-Object { $_.display_name -eq $GroupName }
        }
        else {
            Write-Debug "No groups returned from service list."
            $group = $null
        }
    }
    catch {
        $errorMsg = "Error retrieving NSX-T groups list: $_"
        Write-Error $errorMsg
        return [PSCustomObject]@{
            Action  = "Error"
            Group   = $null
            Message = $errorMsg
            Error   = $_
        }
    }
    
    if ($group) {
        Write-Verbose "Group '$GroupName' found."
        Write-Debug "Group details: $(ConvertTo-Json $group -Depth 3)"
        return [PSCustomObject]@{
            Action  = "Found"
            Group   = $group
            Message = "Group '$GroupName' retrieved successfully."
        }
    }
    else {
        $warnMsg = "No group found with the name '$GroupName'."
        Write-Warning $warnMsg
        return [PSCustomObject]@{
            Action  = "NotFound"
            Group   = $null
            Message = $warnMsg
        }
    }
}
