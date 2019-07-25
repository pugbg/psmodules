$TestEnvironment = @{
    TenantId          = '098ebab6-0ca3-4735-973c-7e8b14e101ac'
    SubscriptionId    = 'a65a9513-cde5-4852-8b5d-4f50d3c43c58'
    ApplicationId     = '5dfc81fc-ebbd-44de-a7af-ffa730d87b62'
    ApplicationSecret = Get-AzKeyVaultSecret -VaultName 'psmodules-cicd' -Name 'psmodules-cicd' | select -ExpandProperty SecretValueText
}

describe 'AzeOAuthToken' {

    context "Using User" {
        $ConnectAzAccount_Params = @{
            TenantId         = '098ebab6-0ca3-4735-973c-7e8b14e101ac'
            SubscriptionName = 'MCT'
            Scope            = 'Process'
        }
        $null = Connect-AzAccount @ConnectAzAccount_Params -ErrorAction Stop

        It "Get token for AzureRm api not using AzContext" {
            $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
            Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

            $oAuthToken = Get-AzeOAuthToken -TenantId '098ebab6-0ca3-4735-973c-7e8b14e101ac' -AccountId 'gogbg@outlook.com'
        }

        It "Get token for AzureRm api using AzContext" {
            $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
            Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

            $AzContext = Get-AzContext
            $oAuthToken = Get-AzeOAuthToken -AzContext $AzContext -ErrorAction Stop
        }
    }

    context "Using SPN" {
        $TenantId = '098ebab6-0ca3-4735-973c-7e8b14e101ac'
        $ApplicationId = Read-Host -Prompt 'ApplicationId:'
        $ApplicationSecret = Read-Host -Prompt 'ApplicationSecret:'

        It "Get token for AzureRm api using AzContext" {
            $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
            Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop

            $oAuthToken = Get-AzeOAuthToken -TenantId $TenantId -ApplicationId $ApplicationId -ApplicationSecret $ApplicationSecret -ErrorAction Stop
        }
    }
}

describe 'ResourceGroup' {

    BeforeEach {

        #Configure Context to skip processing 'it` statements on failed 'it' statement
        $CurrentTestGroup = InModuleScope -ModuleName Pester { $Pester.CurrentTestGroup }
        if (($CurrentTestGroup.Actions.Passed -contains $false) -and ((InModuleScope -ModuleName Pester { $Name }) -ne 'Cleanup'))
        {
            Set-ItResult -Skipped -Because 'previous test failed'
        }

    }

    context "Create, Get, Remove using '-oAuthToken' parameter" {

        $TestContext = $TestEnvironment + @{
            ResourceGroupName = 'test-AzeModuleGrp01'
            Location          = 'northeurope'
            oAuthToken        = $null
        }

        it "Initialize" {
            $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
            Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop
            $TestContext['oAuthToken'] = Get-AzeOAuthToken -TenantId $TestContext['TenantId'] -ApplicationId $TestContext['ApplicationId'] -ApplicationSecret $TestContext['ApplicationSecret']
        }

        it "Create using '-oAuthToken' parameter" {
            $RG = New-AzeResourceGroup -passthru -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -Location $TestContext['Location'] -oAuthToken $TestContext['oAuthToken']
            $RG.Name | should -be $TestContext['ResourceGroupName']
            $RG.location | should -be $TestContext['Location']
        }

        it "Get using '-oAuthToken' parameter" {
            $RG = Get-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -oAuthToken $TestContext['oAuthToken']
            $RG.Name | should -be $TestContext['ResourceGroupName']
        }

        it "Remove using '-oAuthToken' parameter" {
            Remove-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -oAuthToken $TestContext['oAuthToken']
            { Get-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -oAuthToken $TestContext['oAuthToken'] -ErrorAction Stop } | should -Throw
        }
    }

    context "Create, Get, Remove not using '-oAuthToken' parameter" {

        $TestContext = $TestEnvironment + @{
            ResourceGroupName = 'test-AzeModuleGrp02'
            Location          = 'northeurope'
        }

        it "Initialize" {
            $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
            Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop
            Connect-AzeAccount -TenantId $TestContext['TenantId'] -ApplicationId $TestContext['ApplicationId'] -ApplicationSecret $TestContext['ApplicationSecret']
        }

        it "Create not using '-oAuthToken' parameter" {
            $RG = New-AzeResourceGroup -passthru -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -Location $TestContext['Location']
            $RG.Name | should -be $TestContext['ResourceGroupName']
            $RG.location | should -be $TestContext['Location']
        }

        it "Get not using '-oAuthToken' parameter" {
            $RG = Get-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] 
            $RG.Name | should -be $TestContext['ResourceGroupName']
        }

        it "Remove not using '-oAuthToken' parameter" {
            Remove-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName']
            { Get-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -ErrorAction Stop } | should -Throw
        }

    }

}

describe 'RoleAssignment' {
  
    BeforeEach {

        #Configure Context to skip processing 'it` statements on failed 'it' statement
        $CurrentTestGroup = InModuleScope -ModuleName Pester { $Pester.CurrentTestGroup }
        if (($CurrentTestGroup.Actions.Passed -contains $false) -and ((InModuleScope -ModuleName Pester { $Name }) -ne 'Cleanup'))
        {
            Set-ItResult -Skipped -Because 'previous test failed'
        }

    }

    context "Create not using '-oAuthToken' parameter" {

        $TestContext = $TestEnvironment + @{
            ResourceGroupName = 'test-AzeModuleGrp03'
            Location          = 'northeurope'
            PrincipalId       = '065920d4-336e-44e3-a44a-3b18aaf85041'
        }

        it "Initialize" {
            $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
            Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop
            Connect-AzeAccount -TenantId $TestContext['TenantId'] -ApplicationId $TestContext['ApplicationId'] -ApplicationSecret $TestContext['ApplicationSecret']
            New-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -Location $TestContext['Location']
        }

        it "Create on ResourceGroup scope" {
            $RoleDefinition = Get-AzeRoleDefinition -Name 'Contributor' -Scope "subscriptions/$($TestContext['SubscriptionId'])"
            $RoleAssignment = New-AzeRoleAssignment -PrincipalId $TestContext['PrincipalId'] -Scope "subscriptions/$($TestContext['SubscriptionId'])/resourceGroups/$($TestContext['ResourceGroupName'])" -RoleDefinitionId $RoleDefinition.Id -PassThru
        }

        it "Create on Subscription scope" {
            $RoleDefinition = Get-AzeRoleDefinition -Name 'Contributor' -Scope "subscriptions/$($TestContext['SubscriptionId'])"
            $RoleAssignment = New-AzeRoleAssignment -PrincipalId $TestContext['PrincipalId'] -Scope "subscriptions/$($TestContext['SubscriptionId'])" -RoleDefinitionId $RoleDefinition.Id -PassThru
        }

        it "Cleanup" {
            $RG = Get-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -ErrorAction SilentlyContinue
            if ($RG)
            {
                Remove-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -ErrorAction Stop
            }
        }
    }
}

describe 'KeyVault' {
  
    BeforeEach {

        #Configure Context to skip processing 'it` statements on failed 'it' statement
        $CurrentTestGroup = InModuleScope -ModuleName Pester { $Pester.CurrentTestGroup }
        if (($CurrentTestGroup.Actions.Passed -contains $false) -and ((InModuleScope -ModuleName Pester { $Name }) -ne 'Cleanup'))
        {
            Set-ItResult -Skipped -Because 'previous test failed'
        }

    }

    context "Create, Remove not using '-oAuthToken' parameter" {

        $TestContext = $TestEnvironment + @{
            ResourceGroupName = 'test-AzeModuleGrp04'
            Location          = 'northeurope'
            KeyVaultName      = 'test-aze-keyvault-01'
            properties        = @{
                TenantId = $TestEnvironment['TenantId']
                sku      = @{
                    family = 'A'
                    name   = 'standard'
                }
                accessPolicies=@()
            }
            Tags              = @{
                Tag1 = 'Value1'
            }
        }

        it "Initialize" {
            $ModuleRoot = Split-Path -Path $PSScriptRoot -Parent
            Import-Module -FullyQualifiedName $ModuleRoot -Force -ErrorAction Stop
            Connect-AzeAccount -TenantId $TestContext['TenantId'] -ApplicationId $TestContext['ApplicationId'] -ApplicationSecret $TestContext['ApplicationSecret']
            New-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -Location $TestContext['Location']
        }

        it "Create" {
            $NewAzeKeyVault_Params = @{
                SubscriptionId    = $TestContext['SubscriptionId']
                ResourceGroupName = $TestContext['ResourceGroupName']
                Name              = $TestContext['KeyVaultName']
                Location          = $TestContext['Location']
                Tags              = $TestContext['Tags']
                PassThru          = $true
                Properties        = $TestContext['Properties']
            }
            $KeyVault = New-AzeKeyVault @NewAzeKeyVault_Params -ErrorAction Stop
            $KeyVault.Name | should -be $TestContext['KeyVaultName']
            $KeyVault.Location | should -be $TestContext['Location']
            $TestContext['Tags'].Keys | foreach {
                $KeyVault.Tags."$_" | should -be $TestContext['Tags']["$_"]
            }
        }

        it "Remove" {
            $RemoveAzeKeyVault_Params = @{
                SubscriptionId    = $TestContext['SubscriptionId']
                ResourceGroupName = $TestContext['ResourceGroupName']
                Name              = $TestContext['KeyVaultName']
            }
            $KeyVault = Remove-AzeKeyVault @RemoveAzeKeyVault_Params -ErrorAction Stop
            $keyvault | should -BeNullOrEmpty
        }

        it "Cleanup" {
            $RG = Get-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -ErrorAction SilentlyContinue
            if ($RG)
            {
                Remove-AzeResourceGroup -SubscriptionId $TestContext['SubscriptionId'] -Name $TestContext['ResourceGroupName'] -ErrorAction Stop
            }
        }
    }
}