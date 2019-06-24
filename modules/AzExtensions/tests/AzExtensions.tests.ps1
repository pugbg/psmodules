
describe ManagementGroups {
    It "Retrive all groups recursively" {
        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $r = Get-AzeManagementGroup -Recurse
    }
}
