describe 'PSBConfiguration' {

    & "$PSScriptRoot\TestHelpers\Import-Module.ps1"

    context 'Get empty configuration' {
        $TestScenario = & "$PSScriptRoot\TestHelpers\Initialize-TestScenario.ps1" -Name Configurations
        $PsbConfig = Get-PsbConfiguration -Path (Join-Path -Path $TestScenario.RootFolder -ChildPath 'emptyConfig.json')
    }

    context 'Get configuration with variables' {
        $TestScenario = & "$PSScriptRoot\TestHelpers\Initialize-TestScenario.ps1" -Name Configurations
        $PsbConfig = Get-PsbConfiguration -Path (Join-Path -Path $TestScenario.RootFolder -ChildPath 'variablesConfig.json')
    }
}