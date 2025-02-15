<#
.SYNOPSIS
    Creates or updates an NSX-T group using NSX-T PowerCLI service methods within a specified project.

.DESCRIPTION
    The New-NSXTGroup cmdlet creates a new group in NSX-T (or updates an existing one) by using the NSX-T group service.
    It retrieves the service with Get-NsxtService, then checks if a group with the specified display name already exists in the
    specified NSX-T domain. If an existing group is found, the cmdlet compares its parameters (description and membership criteria
    expressed in the Expression parameter) with those provided. If they match, the existing group's details are returned.
    If they differ and the -Force switch is specified, the existing group is updated to match the provided parameters.
    Otherwise, a warning is issued and the existing group's details are returned. If no matching group exists, a new group is
    created using the service’s help method to generate a specification and then calling the service’s create method.
    The cmdlet supports the built-in WhatIf functionality to simulate changes.

.PARAMETER GroupName
    The display name for the new group.

.PARAMETER Description
    An optional description for the group.

.PARAMETER Expression
    The membership criteria for the group. This should be provided as an array of hashtables defining dynamic membership rules.
    For example, you can supply an expression to dynamically select all virtual machines whose display name contains a specific substring.

.PARAMETER Domain
    Specifies the NSX-T domain (project) in which to create the group. The default is "default".

.PARAMETER Force
    If specified and an existing group's parameters differ, the cmdlet updates the existing group so that its parameters match
    those provided.

.INPUTS
    None. This cmdlet does not accept pipeline input.

.OUTPUTS
    A PSCustomObject with the following properties:
      - Action: "Found", "Created", "Updated", or "WhatIf"
      - ID: The ID of the group (or a dummy ID when WhatIf is used)
      - URL: The URL for the group in NSX-T (if available)
      - Message: A human-readable description of the result.

.EXAMPLE
    New-NSXTGroup -GroupName "New Group" -Description "Created via PowerShell" `
                  -Expression @(@{ resource_type = "Condition"; field = "name"; operator = "CONTAINS"; value = "adds" }) -Verbose -WhatIf

.EXAMPLE
    New-NSXTGroup -GroupName "New Group" -Description "Updated Description" `
                  -Expression @(@{ resource_type = "Condition"; field = "name"; operator = "CONTAINS"; value = "newValue" }) -Force -Verbose

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Requires: NSX-T PowerCLI and an active NSX-T session (e.g., Connect-NsxtServer)
#>

function New-NSXTGroup {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter the display name for the group.")]
        [string]$GroupName,

        [Parameter(Mandatory = $false, HelpMessage = "Enter an optional description for the group.")]
        [string]$Description = "",

        [Parameter(Mandatory = $false, HelpMessage = "Enter the membership criteria for the group as an array of expressions (hashtables).")]
        [object[]]$Expression,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the NSX-T domain (project) in which to create the group. Default is 'default'.")]
        [string]$Domain = "default",

        [Parameter(Mandatory = $false, HelpMessage = "Force update if an existing group's parameters differ.")]
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess("NSX-T Group", "Creating/updating group '$GroupName'")) {

        # Set the NSX-T policy path for multi-project support if available.
        if (Get-Command -Name Set-NsxtPolicyPath -ErrorAction SilentlyContinue) {
            Set-NsxtPolicyPath -Domain $Domain
            Write-Verbose "Set NSX-T policy path to Domain '$Domain'."
        }
        else {
            Write-Verbose "Set-NsxtPolicyPath cmdlet not found. Ensure you are operating in the correct NSX-T project context."
        }

        # Retrieve the NSX-T groups service.
        try {
            $groupsvc = Get-NsxtService -Name "com.vmware.nsx.groups"
        }
        catch {
            Write-Error "Error retrieving NSX-T groups service: $_"
            return [PSCustomObject]@{
                Action  = "Error"
                ID      = $null
                URL     = $null
                Message = "Error retrieving NSX-T groups service: $_"
            }
        }
        if (-not $groupsvc) {
            Write-Error "NSX-T groups service 'com.vmware.nsx.groups' not found."
            return [PSCustomObject]@{
                Action  = "Error"
                ID      = $null
                URL     = $null
                Message = "NSX-T groups service 'com.vmware.nsx.groups' not found."
            }
        }
        Write-Verbose "NSX-T groups service found. Service ID: $($groupsvc.Id)"

        # Retrieve existing groups.
        try {
            $existingGroupsResponse = $groupsvc.list()
            if ($existingGroupsResponse -and $existingGroupsResponse.results) {
                $existingGroup = $existingGroupsResponse.results | Where-Object { $_.display_name -eq $GroupName }
            }
            else {
                $existingGroup = $null
            }
        }
        catch {
            Write-Verbose "Could not retrieve existing groups: $_. Proceeding with creation."
            $existingGroup = $null
        }

        # If a group with the same display name exists, compare its parameters.
        if ($existingGroup) {
            # Use Compare-Object to compare the expressions.
            $existingExpr = $existingGroup.expression
            $providedExpr = $Expression
            # Normalize by selecting only the relevant properties.
            $propsToCompare = "resource_type", "field", "operator", "value", "member_type"
            $diff = Compare-Object -ReferenceObject ($existingExpr | Select-Object $propsToCompare) `
                                   -DifferenceObject ($providedExpr | Select-Object $propsToCompare) `
                                   -ExcludeDifferent

            # If there are no differences, consider the expressions matching.
            $expressionsMatch = ($diff -eq $null -or $diff.Count -eq 0)

            $paramsMatch = (
                (( $existingGroup.description -eq $Description ) -or ((-not $Description) -and (-not $existingGroup.description))) `
                -and $expressionsMatch
            )

            if ($paramsMatch) {
                $result = [PSCustomObject]@{
                    Action  = "Found"
                    ID      = $existingGroup.id
                    URL     = "https://nsxt.example.com/groups/$($existingGroup.id)"  # Simulated URL
                    Message = "Group '$GroupName' already exists with identical parameters. No changes made."
                }
                return $result
            }
            else {
                if ($Force) {
                    Write-Verbose "Group '$GroupName' exists with different parameters. Force update requested. Updating group..."
                    try {
                        $updateSpec = $groupsvc.Help.update.group.Create()
                    }
                    catch {
                        Write-Error "Error retrieving update specification for group: $_"
                        return [PSCustomObject]@{
                            Action  = "Error"
                            ID      = $existingGroup.id
                            URL     = "https://nsxt.example.com/groups/$($existingGroup.id)"
                            Message = "Error retrieving update specification for group: $_"
                        }
                    }
                    $updateSpec.display_name = $GroupName
                    $updateSpec.description  = $Description
                    if ($Expression) {
                        $updateSpec.expression = $Expression
                    }
                    try {
                        $updatedGroup = $groupsvc.update($existingGroup.id, $updateSpec)
                        $result = [PSCustomObject]@{
                            Action  = "Updated"
                            ID      = $updatedGroup.id
                            URL     = "https://nsxt.example.com/groups/$($updatedGroup.id)"
                            Message = "Group '$GroupName' updated successfully."
                        }
                        return $result
                    }
                    catch {
                        Write-Error "Error updating group: $_"
                        return [PSCustomObject]@{
                            Action  = "Error"
                            ID      = $existingGroup.id
                            URL     = "https://nsxt.example.com/groups/$($existingGroup.id)"
                            Message = "Error updating group: $_"
                        }
                    }
                }
                else {
                    $result = [PSCustomObject]@{
                        Action  = "Found"
                        ID      = $existingGroup.id
                        URL     = "https://nsxt.example.com/groups/$($existingGroup.id)"
                        Message = "Group '$GroupName' already exists with different parameters. No update performed. Use -Force to update."
                    }
                    return $result
                }
            }
        }

        # No matching group exists; create a new group specification.
        try {
            $groupspec = $groupsvc.Help.create.group.Create()
        }
        catch {
            Write-Error "Error retrieving group creation specification: $_"
            return [PSCustomObject]@{
                Action  = "Error"
                ID      = $null
                URL     = $null
                Message = "Error retrieving group creation specification: $_"
            }
        }
        $groupspec.display_name = $GroupName
        $groupspec.description  = $Description
        if ($Expression) {
            $groupspec.expression = $Expression
        }

        # Create the group using the service's create method.
        try {
            $group = $groupsvc.create($groupspec)
            $result = [PSCustomObject]@{
                Action  = "Created"
                ID      = $group.id
                URL     = "https://nsxt.example.com/groups/$($group.id)"
                Message = "Group '$GroupName' created successfully."
            }
            return $result
        }
        catch {
            Write-Error "Error creating group: $_"
            return [PSCustomObject]@{
                Action  = "Error"
                ID      = $null
                URL     = $null
                Message = "Error creating group: $_"
            }
        }
    }
}
