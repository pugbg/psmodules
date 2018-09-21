function SetupContext 
{
    $SolutionFolder = Split-Path -Path $PSScriptRoot -Parent -ErrorAction Stop
    $ModulesFolder = Join-Path -Path $SolutionFolder -ChildPath 'Modules' -ErrorAction Stop
    import-module -FullyQualifiedName "$ModulesFolder\LogHelper" -Force -ErrorAction Stop
}

Describe 'LogHelper using PSD1 configuration file' {

    SetupContext

    $ConfigurationFilePath = "$PSScriptRoot\testLogHelperPsd1Configuration.psd1"

    Register-LhConfiguration -PsdConfigurationFilePath $ConfigurationFilePath
   
    Write-LhEvent -Type 'Informational' -InputObject @{Message='Test LogHelper using configuration file';EventId='1'}
    Write-LhEvent -Type 'Error' -InputObject @{Message='Test LogHelper using configuration file';EventId='1'}
    Write-LhEvent -Type 'Warning' -InputObject @{Message='Test LogHelper using configuration file';EventId='1'}
}

Describe 'LogHelper using Json configuration file' {

    SetupContext

    $ConfigurationFilePath = "$PSScriptRoot\testLogHelperJsonConfiguration.json"

    Register-LhConfiguration -JsonConfigurationFilePath $ConfigurationFilePath
   
    Write-LhEvent -Type 'Informational' -InputObject @{Message='Test LogHelper using Json configuration file';EventId='1'}
    Write-LhEvent -Type 'Error' -InputObject @{Message='Test LogHelper using Json configuration file';EventId='1'}
    Write-LhEvent -Type 'Warning' -InputObject @{Message='Test LogHelper using Json configuration file';EventId='1'}
}