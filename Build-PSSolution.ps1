$ModulesFolder = "$PSScriptRoot\modules"

#Install RequiredModules
<#
try
{
    Write-Information "Install RequiredModules started" -InformationAction Continue
    $RequiredModules = (
        @{
            Name='PowerShellGet'
            RequiredVersion='2.1.5'
        }
    )
    foreach ($mod in $RequiredModules)
    {
        Remove-Variable -Name ModuleCheck -ErrorAction SilentlyContinue
        Remove-Variable -Name ModulePSGetInstalled -ErrorAction SilentlyContinue
        $ModulePSGetInstalled = Get-InstalledModule -Name $mod.Name -ErrorAction SilentlyContinue
        if ($ModulePSGetInstalled -and $ModulePSGetInstalled.Version -eq $mod.RequiredVersion)
        {
        }
        else
        {
            Write-Information "Install RequiredModules in progress. Module: $($mod.Name)/$($mod.RequiredVersion) previous version. Updating" -InformationAction Continue
            Update-Module @mod -ErrorAction Stop 
        }

        $ModuleCheck = Get-Module -FullyQualifiedName @{ModuleName=$mod.Name;RequiredVersion=$Mod.RequiredVersion} -ListAvailable -ErrorAction SilentlyContinue
        if ($ModuleCheck)
        {
            Write-Information "Install RequiredModules in progress. Module: $($mod.Name)/$($mod.RequiredVersion) already installed" -InformationAction Continue
        }
        else
        {
            Write-Information "Install RequiredModules in progress. Module: $($mod.Name)/$($mod.RequiredVersion) Installing" -InformationAction Continue
            Install-Module @mod -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        }
        Import-Module @mod -ErrorAction Stop
    }
    Write-Information "Install RequiredModules completed" -InformationAction Continue
}
catch
{
    throw "Install RequiredModules failed. Details: $_"
}
#>

Update-Module -Name PowerShellGet -Scope CurrentUser -Force

#Import RequiredModules from this project
try
{
    Write-Information "Import RequiredModules from this project started" -InformationAction Continue

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