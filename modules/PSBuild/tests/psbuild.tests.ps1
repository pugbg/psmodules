function SetupContext
{
    #Import required modules
    $ModulesPath = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
    Import-Module -FullyQualifiedName "$ModulesPath\AstExtensions" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\SystemExtensions" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\TypeHelper" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\pshelper" -force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesPath\psbuild" -force -ErrorAction Stop
}

function Initialize-TestScenario
{

    [Cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Name
    )

    process
    {
        $ExpectedPath = Join-Path -Path $PSScriptRoot -ChildPath "TestScenarios\$Name"
        If (-not (test-path -Path $ExpectedPath))
        {
            throw "Scenario: $Name not found"
        }

        $TestScenarioFolder = join-path -Path $TestDrive -ChildPath 'TestScenario' -ErrorAction Stop
        if (-not (Test-Path -Path TestScenarioFolder))
        {
            $null = New-Item -Path $TestScenarioFolder -ItemType Directory -ErrorAction Stop
        }

        Copy-Item -Path "$ExpectedPath\*" -Destination $TestScenarioFolder -Recurse -ErrorAction Stop
        $result = [pscustomobject]@{
            ScenarioName      = $Name
            RootFolder        = $TestScenarioFolder
            BinFolder         = "$TestScenarioFolder\bin"
            SrcFolder         = "$TestScenarioFolder\src"
            BuildConfigFolder = "$TestScenarioFolder\src\configuration"
        }


        #return result
        $result
    }
}

describe "Build-PSSolution" {

    SetupContext

    context "when 'ScriptPath.SourcePath' does not contains scripts" {
        $TestScenario = Initialize-TestScenario -Name EmptySolution-ShouldComplete
        it "build PSSolutions" {
            Build-PSSolution -SolutionConfigPath "$($TestScenario.BuildConfigFolder)\pssolutionconfig.psd1" -ErrorAction Stop
        }
    }

    context "when 'ScriptPath.SourcePath' contains multiple scripts with the same name, and 'ScriptPath.BuildPath' is absent" {
        $TestScenario = Initialize-TestScenario -Name ScriptsWithSameName-ShouldComplete
        it "build PSSolution" {
            Build-PSSolution -SolutionConfigPath "$($TestScenario.BuildConfigFolder)\pssolutionconfig.psd1" -ErrorAction Stop
        }

        it "scriptsFolder1\examplescript1.ps1 version should be incresed" {
            $r = Test-PSScript -ScriptPath "$($TestScenario.SrcFolder)\scripts\scriptsFolder1\examplescript1.ps1"
            $r.ScriptInfo.Version | should -Be '2.0.0.13'
        }

        it "scriptsFolder2\examplescript1.ps1 version should be incresed" {
            $r = Test-PSScript -ScriptPath "$($TestScenario.SrcFolder)\scripts\scriptsFolder2\examplescript1.ps1"
            $r.ScriptInfo.Version | should -Be '1.0.0.13'
        }
    }

    context "when 'UseScriptConfigFile'=True and dependancies are present in scripts config.json" {
        $TestScenario = Initialize-TestScenario -Name ScriptConfigFiles-ShouldComplete

        it 'build PSSolution' {
            Build-PSSolution -SolutionConfigPath "$($TestScenario.BuildConfigFolder)\pssolutionconfig.psd1"
        }

        it "script should be copied to bin folder" {
            "$($TestScenario.BinFolder)\scriptsWithConfigs\examplescript1.ps1" | should -Exist
        }

        it "script config should be copied to bin folder" {
            "$($TestScenario.BinFolder)\scriptsWithConfigs\examplescript1.config.json" | should -Exist
        }
    }

    context "when 'UseScriptConfigFile'=True and dependancies are absent in script config.json" {
        $TestScenario = Initialize-TestScenario -Name ScriptConfigFiles-ShouldFail

        it 'build PSSolution' {
            { Build-PSSolution -SolutionConfigPath "$($TestScenario.BuildConfigFolder)\pssolutionconfig.psd1" } | should -Throw
        }

        it "script should not be copied to bin folder" {
            "$($TestScenario.BinFolder)\scriptsWithConfigs\examplescript1.ps1" | should -not -Exist
        }

        it "script config not should be copied to bin folder" {
            "$($TestScenario.BinFolder)\scriptsWithConfigs\examplescript1.config.json" | should -not -Exist
        }
    }

}

describe "Build-PSScript" {

    SetupContext

    context "-UseScriptConfigFile when dependancies are present" {
        $TestScenario = Initialize-TestScenario -Name ScriptConfigFiles-ShouldComplete

        it "build script" {
            $BuildPSScript_Params = @{
                SourcePath                          = "$($TestScenario.SrcFolder)\scriptsWithConfigs\examplescript1.ps1"
                DestinationPath                     = "$($TestScenario.BinFolder)\scriptsWithConfigs"
                CheckCommandReferencesConfiguration = @{
                    Enabled = $true
                }
                UseScriptConfigFile                 = $true
                PSGetRepository                     = @{
                    Name = 'PSGallery'
                }
            }
            Build-PSScript @BuildPSScript_Params -ErrorAction Stop
        }

        it "script should be copied to bin folder" {
            "$($TestScenario.BinFolder)\scriptsWithConfigs\examplescript1.ps1" | should -Exist
        }

        it "script config should be copied to bin folder" {
            "$($TestScenario.BinFolder)\scriptsWithConfigs\examplescript1.config.json" | should -Exist
        }

    }

    context "-UseScriptConfigFile when dependancies are absent" {
        $TestScenario = Initialize-TestScenario -Name ScriptConfigFiles-ShouldFail

        it "build script" {
            { 
                $BuildPSScript_Params = @{
                    SourcePath                          = "$($TestScenario.SrcFolder)\scriptsWithConfigs\examplescript1.ps1"
                    DestinationPath                     = "$($TestScenario.BinFolder)\scriptsWithConfigs"
                    CheckCommandReferencesConfiguration = @{
                        Enabled = $true
                    }
                    UseScriptConfigFile                 = $true
                    PSGetRepository                     = @{
                        Name = 'PSGallery'
                    }
                }
                Build-PSScript @BuildPSScript_Params -ErrorAction Stop
            } | should -Throw
        }

        it "script should not be copied to bin folder" {
            "$($TestScenario.BinFolder)\scriptsWithConfigs\examplescript1.ps1" | should -Not -Exist
        }

        it "script config should not be copied to bin folder" {
            "$($TestScenario.BinFolder)\scriptsWithConfigs\examplescript1.config.json" | should -Not -Exist
        }
    }

}