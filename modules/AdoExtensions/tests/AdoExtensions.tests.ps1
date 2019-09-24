#requires -module @{ModuleName='VSTeam';RequiredVersion='6.3.3'}

[cmdletbinding()]
param
(
    [Parameter(Mandatory = $false)]
    $EnvironmentContext = @{
        AdoOrganizationName = 'gogbg'
        AdoProjectName      = 'psmodules'
    }
)

describe "AdoePipelineDefinitionFile" {

    #Connect to TestEnvironment
    $ConnectTestEnvironment_Params = @{
        AdoOrganizationName = $EnvironmentContext['AdoOrganizationName']
    }
    if ($EnvironmentContext.containsKey('AdoPat'))
    {
        $ConnectTestEnvironment_Params.Add('AdoPat', $EnvironmentContext['AdoPat'])
    }
    else
    {
        $ConnectTestEnvironment_Params.Add('AdoPat', (Read-Host -Prompt "Please Provide Personal Access Token for: $($EnvironmentContext['AdoOrganizationName'])"))
    }
    & "$PSScriptRoot\testhelpers\Connect-TestEnvironment.ps1" @ConnectTestEnvironment_Params -ErrorAction Stop
    
    context "Create with single step in root folder" {

        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $BuildFilePath = Join-Path -Path $TestDrive -ChildPath 'TestPipeline.json'

        $CreateAdoePipelineDefinitionFile_Params = @{
            FilePath   = $BuildFilePath
            Name       = 'TestPipeline'
            Project    = @{
                id   = '403aa895-9e23-49dd-aebd-704e85b8c165'
                name = 'psmodules'
            }
            Queue      = @{
                name = 'Hosted Windows 2019 with VS2019'
            }
            Phases     = @{
                steps   = @(
                    @{
                        enabled     = $true
                        displayName = 'Step1'
                        task        = @{
                            id          = 'e213ff0f-5d5c-4791-802d-52ea3e7be1f1'
                            versionSpec = "2.*"
                        }
                        inputs      = @{
                            filePath = 'Script1.ps1'
                        }
                    }
                )
                Name    = 'Job1'
                RefName = 'Job1'
            }
            Repository = @{
                Name = 'psmodules'
            }
        }
        Create-AdoePipelineDefinitionFile @CreateAdoePipelineDefinitionFile_Params -ErrorAction Stop

        #Create Pipeline
        $builddefinition = Add-VSTeamBuildDefinition -projectName $EnvironmentContext['AdoProjectName'] -InFile $BuildFilePath -ErrorAction Stop
        Remove-VSTeamBuildDefinition -projectName $EnvironmentContext['AdoProjectName'] -Id $builddefinition.Id -force -ErrorAction Stop
    }

    context "Create with single step and variable group" {

        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $BuildFilePath = Join-Path -Path $TestDrive -ChildPath 'TestPipeline.json'

        $CreateAdoePipelineDefinitionFile_Params = @{
            FilePath       = $BuildFilePath
            Name           = 'TestPipeline'
            Project        = @{
                id   = '403aa895-9e23-49dd-aebd-704e85b8c165'
                name = 'psmodules'
            }
            Queue          = @{
                name = 'Hosted Windows 2019 with VS2019'
            }
            Phases         = @{
                steps   = @(
                    @{
                        enabled     = $true
                        displayName = 'Step1'
                        task        = @{
                            id          = 'e213ff0f-5d5c-4791-802d-52ea3e7be1f1'
                            versionSpec = "2.*"
                        }
                        inputs      = @{
                            targetType = "filePath"
                            filePath   = 'Script1.ps1'
                        }
                    }
                )
                Name    = 'Job1'
                RefName = 'Job1'
            }
            VariableGroups = @{
                Id = 1
            }
            Repository     = @{
                Name = 'psmodules'
            }
        }
        Create-AdoePipelineDefinitionFile @CreateAdoePipelineDefinitionFile_Params -ErrorAction Stop

        #Create Pipeline
        $builddefinition = Add-VSTeamBuildDefinition -projectName $EnvironmentContext['AdoProjectName'] -InFile $BuildFilePath -ErrorAction Stop

        it "Variable Groups should be present" {
            $builddefinition.variableGroups.Count | should -be 1
            
        }

        Remove-VSTeamBuildDefinition -projectName $EnvironmentContext['AdoProjectName'] -Id $builddefinition.Id -force -ErrorAction Stop
    }

    context "Create with single step and demand in root folder" {

        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $BuildFilePath = Join-Path -Path $TestDrive -ChildPath 'TestPipeline.json'

        $CreateAdoePipelineDefinitionFile_Params = @{
            FilePath   = $BuildFilePath
            Name       = 'TestPipeline'
            Project    = @{
                id   = '403aa895-9e23-49dd-aebd-704e85b8c165'
                name = 'psmodules'
            }
            Queue      = @{
                name = 'Hosted Windows 2019 with VS2019'
            }
            Phases     = @{
                steps   = @(
                    @{
                        enabled     = $true
                        displayName = 'Step1'
                        task        = @{
                            id          = 'e213ff0f-5d5c-4791-802d-52ea3e7be1f1'
                            versionSpec = "2.*"
                        }
                        inputs      = @{
                            filePath = 'Script1.ps1'
                        }
                    }
                )
                Name    = 'Job1'
                RefName = 'Job1'
                target  = @{
                    demands = 'Agent.OS -equals Linux'
                }
            }
            Repository = @{
                Name = 'psmodules'
            }
        }
        Create-AdoePipelineDefinitionFile @CreateAdoePipelineDefinitionFile_Params -ErrorAction Stop

        #Create Pipeline
        $builddefinition = Add-VSTeamBuildDefinition -projectName $EnvironmentContext['AdoProjectName'] -InFile $BuildFilePath -ErrorAction Stop
        $builddefinition.process.phases[0].target.demands.Count | should -be 1
        $builddefinition.process.phases[0].target.demands[0] | should -be "Agent.OS -equals Linux"
        Remove-VSTeamBuildDefinition -projectName $EnvironmentContext['AdoProjectName'] -Id $builddefinition.Id -force -ErrorAction Stop
    }

}