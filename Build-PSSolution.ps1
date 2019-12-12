#Import RequiredModules from this project
try
{
    Write-Information "Import RequiredModules from this project started" -InformationAction Continue

    $ModulesFolder = "$PSScriptRoot\modules"
    $RequiredModules = @(
        'AstExtensions'
        'SystemExtensions'
        'TypeHelper'
        'PSHelper'
        'PSBuild'
    )
    foreach ($rm in $RequiredModules)
    {
        Write-Information "Import RequiredModules from this project im progress. Importing: '$rm'" -InformationAction Continue
        Import-Module -FullyQualifiedName "$ModulesFolder\$rm" -Force -ErrorAction Stop

    }

    Write-Information "Import RequiredModules from this project completed" -InformationAction Continue
}
catch
{
    throw "Import RequiredModules from this project failed. Details: $([System.Environment]::NewLine)$($_ | convertto-json -Depth 5)"
}

Build-PSSolution -SolutionConfigPath "$PSScriptRoot\buildconfig.psd1" -Verbose -ErrorAction Stop