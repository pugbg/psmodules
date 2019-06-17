function SetupContext {
    #Import required modules
    $ModulesPath = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
    Import-Module -FullyQualifiedName "$ModulesPath\AstExtensions" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\SystemExtensions" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\TypeHelper" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\pshelper" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\psbuild" -force -ErrorAction Stop
}

function Initialize-TestScenario {

    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$Name
    )

    process
    {
        $ExpectedPath = Join-Path -Path $PSScriptRoot -ChildPath "TestScenarios\$Name"
        If (test-path -Path $ExpectedPath)
        {
            [pscustomobject]@{
                ScenarioName=$Name
                RootFolder=$ExpectedPath
                BinFolder="$ExpectedPath\bin"
                SrcFolder="$ExpectedPath\src"
            }
        }
        else
        {
            throw "Scenario: $Name not found"
        }
    }
}

function Reset-TestScenario {
    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [psobject]$Scenario
    )

    process
    {
        if (Test-Path -Path $Scenario.BinFolder)
        {
            Remove-Item -Path $Scenario.BinFolder -Recurse -Force -ErrorAction Stop
        }
    }
}

describe "Scripts with Config files" {

    SetupContext
    $Scenario_ShouldComplete = Initialize-TestScenario -Name ScriptConfigFiles-ShouldComplete
    $Scenario_ShouldFail = Initialize-TestScenario -Name ScriptConfigFiles-ShouldFail

    Reset-TestScenario -Scenario $Scenario_ShouldComplete
    it "Build-PSScript -UseScriptConfigFile should succeed if all dependancies are present" {

        $BuildPSScript_Params = @{
            SourcePath="$($Scenario_ShouldComplete.SrcFolder)\scriptsWithConfigs\examplescript1.ps1"
            DestinationPath="$($Scenario_ShouldComplete.BinFolder)\scriptsWithConfigs"
            CheckCommandReferencesConfiguration=@{
                Enabled=$true
            }
            UseScriptConfigFile=$true
            PSGetRepository=@{
                Name='PSGallery'
            }
        }
        Build-PSScript @BuildPSScript_Params -ErrorAction Stop
        "$($Scenario_ShouldComplete.BinFolder)\scriptsWithConfigs\examplescript1.config.json" | should -Exist
    }

    Reset-TestScenario -Scenario $Scenario_ShouldComplete
    it "Build-PSSolution using UseScriptConfigFile=True should succeed if all dependancies are present" {
        Build-PSSolution -SolutionConfigPath "$($Scenario_ShouldComplete.SrcFolder)\configuration\pssolutionconfig-example01.psd1"

        "$($Scenario_ShouldComplete.BinFolder)\scriptsWithConfigs\examplescript1.config.json" | should -Exist
    }

    Reset-TestScenario -Scenario $Scenario_ShouldFail
    it "Build-PSScript -UseScriptConfigFile should fail if missing dependancies" {

        { 
            $BuildPSScript_Params = @{
                SourcePath="$($Scenario_ShouldFail.SrcFolder)\scriptsWithConfigs\examplescript2.ps1"
                DestinationPath="$($Scenario_ShouldFail.BinFolder)\scriptsWithConfigs"
                CheckCommandReferencesConfiguration=@{
                    Enabled=$true
                }
                UseScriptConfigFile=$true
                PSGetRepository=@{
                    Name='PSGallery'
                }
            }
            Build-PSScript @BuildPSScript_Params -ErrorAction Stop
        } | should -Throw
    }

    Reset-TestScenario -Scenario $Scenario_ShouldFail
    it "Build-PSSolution using UseScriptConfigFile=True should fail if missing dependancies" {
        {
            Build-PSSolution -SolutionConfigPath "$($Scenario_ShouldFail.SrcFolder)\configuration\pssolutionconfig-example01.psd1"
        } | should -throw
    }
}