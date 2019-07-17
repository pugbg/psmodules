
describe ManagementGroups {
    It "Retrive all groups recursively" {
        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $r = Get-AzeManagementGroup -Recurse
    }
}

describe 'AzeOAuthToken' {
    It "Get token for AzureRm api not using AzContext" {
        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        #Connect-AzAccount -TenantId '098ebab6-0ca3-4735-973c-7e8b14e101ac'
        $r = Get-AzeOAuthToken -TenantId '098ebab6-0ca3-4735-973c-7e8b14e101ac' -AccountId 'gogbg@outlook.com'
    }

    It "Get token for AzureRm api using AzContext" {
        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $AzContext = Get-AzContext
        $r = Get-AzeOAuthToken -AzContext $AzContext -ErrorAction Stop
    }
}

describe 'ResourceGroup' {
    it "Create" {
        $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
        Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

        $oAuthToken = Get-AzeOAuthToken -TenantId '098ebab6-0ca3-4735-973c-7e8b14e101ac' -AccountId 'gogbg@outlook.com'
        $RG = New-AzeResourceGroup -passthru -Proxy 'http://10.180.0.8:8080' -SubscriptionId '512d7608-908d-4b85-be6a-36ecdf28734d' -Name 'test-resg02' -Location 'northeurope' -Tag @{Tag1='1'} -oAuthToken $oAuthToken
    }
}