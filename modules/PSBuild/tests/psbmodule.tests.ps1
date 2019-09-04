describe 'Test-PsbModule' {

    & "$PSScriptRoot\TestHelpers\Import-Module.ps1"

    context 'when module is empty' {
        $TestScenario = & "$PSScriptRoot\TestHelpers\Initialize-TestScenario.ps1" -Name Modules
        $ModuleName = 'emptyModule'
        $PsbModule = Test-PsbModule -SourcePath (Join-Path -Path $TestScenario.RootFolder -ChildPath $ModuleName)
        
        it "PsbModule.Name" {
            $PsbModule.Name | should -be $ModuleName
        }
        
        it "PsbModule.Version" {
            $PsbModule.Version | should -BeOfType version
        }

        it "PsbModule.ModuleInfo.ExportedCommands" {
            $PsbModule.ModuleInfo.ExportedCommands.count | should -be 0
        }
    }
}