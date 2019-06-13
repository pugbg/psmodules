using module '..\..\PSHelper'
Describe 'Test PSScript using config file' {

    it "Script should have ScriptConfig when using -UseScriptConfigFile parameter" {
        #Import PSHelper
        $ModulePath = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModulePath -force -ErrorAction Stop
        $ModuleInfo = Test-PSScript -ScriptPath "$PSScriptRoot\example1\examplescript1.ps1" -UseScriptConfigFile -ErrorAction Stop

        $ModuleInfo.ScriptConfig | Should -BeOfType PSScriptConfig
    }

    it "Script should have PSHelper as required module" {
        #Import PSHelper
        $ModulePath = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModulePath -force -ErrorAction Stop
        $ModuleInfo = Test-PSScript -ScriptPath "$PSScriptRoot\example1\examplescript1.ps1" -UseScriptConfigFile -ErrorAction Stop
        $ModuleInfo.ScriptConfig.RequiredModules.Name | should -Contain 'PShelper'
    }

    it "Script should not have ScriptConfig when missing -UseScriptConfigFile parameter" {
        #Import PSHelper
        $ModulePath = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModulePath -force -ErrorAction Stop
        $ModuleInfo = Test-PSScript -ScriptPath "$PSScriptRoot\example1\examplescript1.ps1" -ErrorAction Stop

        $ModuleInfo.ScriptConfig | Should -BeNullOrEmpty
    }
}