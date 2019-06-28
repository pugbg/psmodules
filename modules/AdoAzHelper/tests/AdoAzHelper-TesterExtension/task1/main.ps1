[CmdletBinding()]
param
(

)

process
{
    'PSBoundParameters:'
    $PSBoundParameters

    'Variables:'
    Get-Variable

    'PS Vault data'
    $VstsTaskSdkModule = Get-module -Name VstsTaskSdk
    if ($VstsTaskSdkModule)
    {
        & $VstsTaskSdkModule {$script:vault}
    }

    'Environment Variables for Process:'
    [System.Environment]::GetEnvironmentVariables('Process') | convertto-json

    'Input: '
    $SCParam = Get-VstsInput -Name ServiceConnection
    $SCParam | convertto-json

    'Connection: '
    $SC = Get-VstsEndpoint -Name $SCParam 
    $SC | convertto-json
    
    'Connection AuthType'
    $SC.Auth.parameters.authenticationType.ToCharArray()

    'Connection RAW: '
    
    #Connecto to ServiceConnection
    'Connecting to ServiceConnection'
    import-module -FullyQualifiedName "$PSScriptRoot\ps_modules\Az.Accounts"
    import-module -FullyQualifiedName "$PSScriptRoot\ps_modules\AdoAzHelper"
    $ServiceConnectionId = Get-Vstsinput -Name ServiceConnection -Require
    $AzConnectResult = Connect-AahServiceConnection -ServiceConnectionId $ServiceConnectionId -PassThru -InformationAction Continue

    $AzConnectResult | convertto-json
}