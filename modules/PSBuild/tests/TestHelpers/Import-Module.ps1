[Cmdletbinding()]
param
(
)

process
{
    $ModulesPath = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent | split-Path -Parent
    Import-Module -FullyQualifiedName "$ModulesPath\psbuild" -force -ErrorAction Stop
}
