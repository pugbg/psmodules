function Create-AdoePipelineDefinitionFile
{
    [CmdletBinding()]
    param
    (
        #FilePath
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        #Name
        [Parameter(Mandatory = $true)]
        [string]$Name,

        #Path
        [Parameter(Mandatory = $false)]
        [string]$Path = '\',        

        #Project
        [Parameter(Mandatory = $true)]
        [PipelineProject]$Project,

        #Queue
        [Parameter(Mandatory = $true)]
        [PipelineQueue]$Queue,

        #Steps
        [Parameter(Mandatory = $true)]
        [PipelinePhase[]]$Phases,

        #Variables
        [Parameter(Mandatory = $false)]
        [Hashtable]$Variables = @{ },

        #Variable Groups
        [Parameter(Mandatory = $false)]
        [VariableGroup]$VariableGroups,

        #Repository
        [Parameter(Mandatory = $true)]
        [PipelineRepository]$Repository
    )

    process
    {

        $PipelineDefinition = @{
            variablegroups = $VariableGroups
            variables      = $Variables
            process        = @{
                phases = $Phases
                type   = 1
            }
            queue          = $Queue
            repository     = $Repository
            name           = $Name
            path           = $Path
            project        = $Project
        }

        #Export Definition
        $PipelineDefinitionAsJson = $PipelineDefinition | Convertto-Json -Depth 20 -ErrorAction Stop
        $PipelineDefinitionAsJson | Out-File -FilePath $FilePath -Force -ErrorAction Stop
    }
}

#region Classes

class PipelineProject
{
    [string]$id
    [string]$name
}

class PipelineQueue
{
    [string]$name
}

class PipelineRepository
{
    [ValidateSet('TfsGit')]
    [string]$type = 'TfsGit'
    [string]$name
    [string]$defaultBranch = 'refs/heads/master'
}

class PipelinePhase
{
    [PipelineStep[]]$steps
    [string]$Name
    [string]$RefName
    [string]$condition = "succeeded()"
}

class PipelineStep
{
    [bool]$enabled
    [string]$displayName
    [PipelineTask]$task
    [hashtable]$Inputs = @{ }
}

class PipelineTask
{
    [string]$id
    [string]$versionSpec
    [string]$definitionType = 'task'
}

class VariableGroup
{
    [int]$id
    [string]$type
}

#endregion