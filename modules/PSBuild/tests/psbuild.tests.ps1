function SetupContext {
    #Import required modules
    $ModulesPath = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
    Import-Module -FullyQualifiedName "$ModulesPath\pshelper" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\psbuild" -force -ErrorAction Stop
}

describe "Scripts" {

    SetupContext

    it "Build-PSScript -UseScriptConfigFile should use the scriptconfigfile for RequiredModules" {

        $BuildPSScript_Params = @{
            SourcePath="$PSScriptRoot\ExampleSolution01\src\scriptsWithConfigs\examplescript1.ps1"
            DestinationPath="$PSScriptRoot\ExampleSolution01\bin\scriptsWithConfigs"
            CheckCommandReferencesConfiguration=@{
                Enabled=$true
            }
            UseScriptConfigFile=$true
            PSGetRepository=@{
                Name='PSGallery'
            }
        }
        Build-PSScript @BuildPSScript_Params -ErrorAction Stop -Verbose
    }
}

describe "PSBuildConfiguration" {

    SetupContext

    it "Get Configuration using Get-PSSolutionConfiguration" {
        $PSSolutionConfiguration = Get-PSSolutionConfiguration -Path "$PSScriptRoot\ExampleSolution01\src\configuration\pssolutionconfig-example01.psd1" -ErrorAction Stop
    }
}