function Get-AzeManagementGroup
{
    [CmdletBinding()]
    param
    (
        #Name
        [Parameter(Mandatory=$false)]
        [string]$Name,

        #Recurse
        [Parameter(Mandatory=$false)]
        [switch]$Recurse
    )

    process
    {
        $Result = [System.Collections.Generic.List[psobject]]::new() 

        $GetAzManagementGroup_Params = @{}
        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $GetAzManagementGroup_Params = @{
                GroupName=$Name
            }
        }
        Get-AzManagementGroup @GetAzManagementGroup_Params -ErrorAction Stop | foreach {
            $Result.Add($_)
        }


        if ($Recurse.IsPresent)
        {
            $ThisLevelChildMGs = [System.Collections.Generic.List[psobject]]::new()
            foreach ($MG in $Result)
            {
                $ChildMGs = Get-AzManagementGroup -GroupName $MG.Name -Expand | select -ExpandProperty Children 

                foreach ($ChildMG in $ChildMGs)
                {
                    if ($ChildMG.Type -eq "/providers/Microsoft.Management/managementGroups")
                    {
                        Get-AzeManagementGroup -Name $ChildMG.Name -Recurse -ErrorAction Stop | foreach {
                            if ($Result.Id -notcontains $_.Id)
                            {
                                $ThisLevelChildMGs.Add($_)
                            }
                        }
                    }
                }
            }

            $ThisLevelChildMGs | foreach {$Result.Add($_)}
        }

        #Return Results
        $Result
    }
}