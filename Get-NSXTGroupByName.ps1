<#
.SYNOPSIS
    Retrieves an NSX-T group by display name.

.DESCRIPTION
    The Get-NSXTGroupByName cmdlet retrieves an NSX-T group from the NSX-T Manager using the NSX-T PowerCLI service.
    It sets the NSX-T policy path (if the helper cmdlet Set-NsxtPolicyPath is available) based on the provided domain and gateway policy,
    then queries the NSX-T groups service for a group matching the specified display name. The returned group object can be used as input
    to other cmdlets (for example, as a source group for firewall rule creation).

.PARAMETER GroupName
    The display name of the NSX-T group to retrieve.

.PARAMETER Domain
    (Optional) Specifies the NSX-T domain (project) in which to search for the group. The default is "default".

.PARAMETER GatewayPolicyId
    (Optional) Specifies the NSX-T gateway policy ID if required. The default is "default".

.INPUTS
    None. This cmdlet does not accept pipeline input.

.OUTPUTS
    If found, the cmdlet returns the NSX-T group object; otherwise, it returns $null.

.EXAMPLE
    # Retrieve a group named "Web Servers" from the default NSX-T domain.
    $group = Get-NSXTGroupByName -GroupName "Web Servers"
    if ($group) {
        Write-Output "Found group with ID: $($group.id)"
    }
    else {
        Write-Warning "No group found with the name 'Web Servers'."
    
.EXAMPLE
    # Retrieve a group named "DB Servers" from a specific NSX-T project.
    $group = Get-NSXTGroupByName -GroupName "DB Servers" -Domain "ProjectDB" -GatewayPolicyId "gw-policy-01"
    Write-Output $group

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Requires: NSX-T PowerCLI and an active NSX-T session (e.g., Connect-NsxtServer)
#>

function Get-NSXTGroupByName {
    [CmdletBinding(ConfirmImpact='Low', SupportsShouldProcess=$false)]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter the display name for the group to retrieve.")]
        [string]$GroupName,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T domain (project) to search in. Default is 'default'.")]
        [string]$Domain = "default",
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T gateway policy ID if required. Default is 'default'.")]
        [string]$GatewayPolicyId = "default"
    )
    
    # Set the NSX-T policy path for multi-project support if available.
    if (Get-Command -Name Set-NsxtPolicyPath -ErrorAction SilentlyContinue) {
        Set-NsxtPolicyPath -Domain $Domain -GatewayPolicy $GatewayPolicyId
        Write-Verbose "Set NSX-T policy path to Domain '$Domain', Gateway Policy '$GatewayPolicyId'."
    }
    else {
        Write-Verbose "Set-NsxtPolicyPath cmdlet not found. Ensure you are in the correct NSX-T project context."
    }
    
    # Retrieve the NSX-T groups service.
    try {
        $groupsvc = Get-NsxtService -Name "com.vmware.nsx.groups"
    }
    catch {
        Write-Error "Error retrieving NSX-T groups service: $_"
        return $null
    }
    if (-not $groupsvc) {
        Write-Error "NSX-T groups service not found."
        return $null
    }
    Write-Verbose "NSX-T groups service found. Service ID: $($groupsvc.Id)"
    
    # Retrieve the list of existing groups.
    try {
        $groupsResponse = $groupsvc.list()
        if ($groupsResponse -and $groupsResponse.results) {
            $group = $groupsResponse.results | Where-Object { $_.display_name -eq $GroupName }
        }
        else {
            $group = $null
        }
    }
    catch {
        Write-Error "Error retrieving NSX-T groups list: $_"
        return $null
    }
    
    if ($group) {
        return $group
    }
    else {
        Write-Warning "No group found with the name '$GroupName'."
        return $null
    }
}
