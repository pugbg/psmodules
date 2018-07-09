function Remove-AzePolicySetDefinition
{
    [CmdletBinding()]
    param 
    (
        #PolicyId
        [Parameter(Mandatory = $true)]
        [string]$Id
    )
    
    process
    {
        #Check if PolicySetDefinition exist
        try
        {
            Write-Verbose 'Check if PolicySetDefinition exist started'
        
            $policySetDef = Get-AzureRmPolicySetDefinition -Id $Id -ErrorAction SilentlyContinue
            if (-not $policySetDef)
            {
                throw "PolicySetDefinition with Id: $Id does not exist"
            }
        
            Write-Verbose 'Check if PolicySetDefinition exist completed'
        }
        catch
        {
            Write-Error "Check if PolicySetDefinition exist failed. Details: $_" -ErrorAction Stop
        }

        #Remove Assignments
        try
        {
            Write-Verbose 'Remove Assignments started'
        
            $policySetAssignments = Get-AzureRmPolicyAssignment | Where-Object {$_.Properties.policyDefinitionId -eq $policySetDef.PolicySetDefinitionId}
            foreach ($polSetAssignment in $policySetAssignments)
            {
                Write-Verbose "Remove Assignments in progress. Removing: $($polSetAssignment.Name)"
                Remove-AzureRmPolicyAssignment -Id $polSetAssignment.PolicyAssignmentId -ErrorAction Stop
            }


            Write-Verbose 'Remove Assignments completed'
        }
        catch
        {
            Write-Error "Remove Assignments failed. Details: $_" -ErrorAction Stop
        }

        #Remove PolicySetDefinition
        try
        {
            Write-Information 'Remove PolicySetDefinition started'
        
            Remove-AzureRmPolicySetDefinition -Id $policySetDef.PolicySetDefinitionId -ErrorAction Stop -Force
        
            Write-Information 'Remove PolicySetDefinition completed'
        }
        catch
        {
            Write-Error "Remove PolicySetDefinition failed. Details: $_" -ErrorAction Stop
        }     
    }
}

function Remove-AzePolicyDefinition
{
    [CmdletBinding()]
    param 
    (
        #PolicyId
        [Parameter(Mandatory = $true)]
        [string]$Id
    )
    
    process
    {
        #Check if PolicyDefinition exist
        try
        {
            Write-Verbose 'Check if PolicyDefinition exist started'
        
            $policyDef = Get-AzureRmPolicyDefinition -Id $Id -ErrorAction SilentlyContinue
            if (-not $policyDef)
            {
                throw "PolicyDefinition with Id: $Id does not exist"
            }
        
            Write-Verbose 'Check if PolicyDefinition exist completed'
        }
        catch
        {
            Write-Error "Check if PolicyDefinition exist failed. Details: $_" -ErrorAction Stop
        }

        #Remove Assignments
        try
        {
            Write-Verbose 'Remove Assignments started'
        
            $policyAssignments = Get-AzureRmPolicyAssignment | Where-Object {$_.Properties.policyDefinitionId -eq $policyDef.PolicyDefinitionId}
            foreach ($policyAssignment in $policyAssignments)
            {
                Write-Verbose "Remove Assignments in progress. Removing: $($polSetAssignment.Name)"
                Remove-AzureRmPolicyAssignment -Id $policyAssignment.PolicyAssignmentId -ErrorAction Stop
            }

            Write-Verbose 'Remove Assignments completed'
        }
        catch
        {
            Write-Error "Remove Assignments failed. Details: $_" -ErrorAction Stop
        }

        #Remove PolicySetDefinitions
        try
        {
            Write-Information 'Remove PolicySetDefinitions started'
            
            $policySetDefinitions = Get-AzureRmPolicySetDefinition | Where-Object {$_.Properties.policyDefinitions.policyDefinitionId -eq $policyDef.PolicyDefinitionId}
            foreach ($policySetDefinition in $policySetDefinitions)
            {
                Write-Verbose "Remove PolicySetDefinitions in progress. Removing: $($policySetDefinition.Name)"
                Remove-AzePolicySetDefinition -Id $policySetDefinition.PolicySetDefinitionId -ErrorAction Stop
            }
        
            Write-Information 'Remove PolicySetDefinitions completed'
        }
        catch
        {
            Write-Error "Remove PolicySetDefinitions failed. Details: $_" -ErrorAction Stop
        }
        
        #Remove PolicyDefinition
        try
        {
            Write-Information 'Remove PolicyDefinition started'
                    
            Remove-AzureRmPolicyDefinition -Id $policyDef.PolicyDefinitionId -Force -ErrorAction Stop
                
            Write-Information 'Remove PolicyDefinition completed'
        }
        catch
        {
            Write-Error "Remove PolicyDefinition failed. Details: $_" -ErrorAction Stop
        }
    }
}