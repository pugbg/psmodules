#Install RequiredModules
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
    }
    Write-Information "Install RequiredModules completed" -InformationAction Continue
}
catch
{
    throw "Install RequiredModules failed. Details: $_"
}