describe "AdoePipelineDefinitionFile" {

    #Connect to VSTeam
    
    context "Create with single step in root folder" {

        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $BuildFilePath = Join-Path -Path $TestDrive -ChildPath 'TestPipeline.json'

        $CreateAdoePipelineDefinitionFile_Params = @{
            FilePath   = $BuildFilePath
            Name       = 'TestPipeline'
            Project    = @{
                id = '403aa895-9e23-49dd-aebd-704e85b8c165'
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
                            id='e213ff0f-5d5c-4791-802d-52ea3e7be1f1'
                            versionSpec= "2.*"
                        }
                        inputs=@{
                            filePath='Script1.ps1'
                        }
                    }
                )
                Name    = 'Job1'
                RefName = 'Job1'
            }
            
            Variables  = @{ }
            Repository = @{
                Name = 'psmodules'
            }
        }
        Create-AdoePipelineDefinitionFile @CreateAdoePipelineDefinitionFile_Params -ErrorAction Stop

    }

}