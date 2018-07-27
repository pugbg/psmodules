$ModulesFolder = "$PSScriptRoot\modules"

Import-Module -FullyQualifiedName "$ModulesFolder\AstExtensions" -Force -ErrorAction Stop
Import-Module -FullyQualifiedName "$ModulesFolder\PSHelper" -Force -ErrorAction Stop
Import-Module -FullyQualifiedName "$ModulesFolder\TypeHelper" -Force -ErrorAction Stop
Import-Module -FullyQualifiedName "$ModulesFolder\PSBuild" -Force -ErrorAction Stop

Build-PSSolution -SolutionConfigPath "$PSScriptRoot\buildconfig.psd1" -Verbose -ErrorAction Stop