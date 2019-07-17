#Import RequiredModules from this project
try
{
    Write-Information "Import RequiredModules from this project started" -InformationAction Continue

    $ModulesFolder = "$PSScriptRoot\modules"

    Import-Module -FullyQualifiedName "$ModulesFolder\AstExtensions" -Force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesFolder\SystemExtensions" -Force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesFolder\TypeHelper" -Force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesFolder\PSHelper" -Force -ErrorAction Stop
    Import-Module -FullyQualifiedName "$ModulesFolder\PSBuild" -Force -ErrorAction Stop

    Write-Information "Import RequiredModules from this project completed" -InformationAction Continue
}
catch
{
    throw "Import RequiredModules from this project failed. Details: $_"
}

Build-PSSolution -SolutionConfigPath "$PSScriptRoot\buildconfig.psd1" -Verbose -ErrorAction Stop