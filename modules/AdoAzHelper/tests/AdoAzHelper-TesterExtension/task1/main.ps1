[CmdletBinding()]
param
(
    #ServiceConnection
    [Parameter(Mandatory=$false)]
    $ServiceConnection,

        #Param1
        [Parameter(Mandatory=$false)]
        $Param1
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

    'PS Vault data2'
    $script:vault

    'Environment Variables for Process:'
    [System.Environment]::GetEnvironmentVariables('Process') | convertto-json   
}