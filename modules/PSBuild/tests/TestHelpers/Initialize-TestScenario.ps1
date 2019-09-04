[Cmdletbinding()]
param
(
    [Parameter(Mandatory = $true)]
    [String]$Name
)

process
{
    $ExpectedPath = Split-Path -path $PSScriptRoot -Parent | Join-Path -ChildPath "TestScenarios\$Name"
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