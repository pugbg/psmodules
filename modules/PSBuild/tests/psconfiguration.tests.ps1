
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

function SetupContext
{
    #Import required modules
    $ModulesPath = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
    Import-Module -FullyQualifiedName "$ModulesPath\psbuild" -force -ErrorAction Stop
}

describe 'PSBConfiguration' {

    SetupContext

    context 'Get empty configuration' {
        $TestScenario = Initialize-TestScenario -Name Configurations
        $PsbConfig = Get-PsbConfiguration -Path (Join-Path -Path $TestScenario.RootFolder -ChildPath 'emptyConfig.json')
    }

    context 'Get configuration with variables' {
        $TestScenario = Initialize-TestScenario -Name Configurations
        $PsbConfig = Get-PsbConfiguration -Path (Join-Path -Path $TestScenario.RootFolder -ChildPath 'variablesConfig.json')
    }
}