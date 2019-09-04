function Build-PsbModule
{
    [CmdletBinding()]
    Param
    (
        #SourcePath
        [Parameter(Mandatory = $true)]
        [string[]]$SourcePath,

        #SourceScope
        [Parameter(Mandatory = $true)]
        [ValidateSet('Base', 'OneLevel', 'Recurse')]
        [string]$SourceScope,

        #Configuration
        [Parameter(Mandatory = $true)]
        [PsbGlobalConfiguration]$Configuration
    )

    process
    {
        #Detect SourceModules
        try
        {
            #Detect SourceModules started

            $SourceModules = [System.Collections.Generic.List[PsbModule]]::new()
            switch ($SourceScope)
            {
                'Base'
                {
                    
                    break
                }

                'OneLevel'
                {

                    break
                }

                'Recurse'
                {

                    break
                }

                default
                {
                    throw "Unsupported SourceScope: '$_'"
                }
            }

            #Detect SourceModules completed
        }
        catch
        {
            #Detect SourceModules failed
        }
    }
}

function Test-PsbModule
{
    [CmdletBinding()]
    Param
    (
        #SourcePath
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo[]]$SourcePath
    )

    process
    {
        foreach ($SP in $SourcePath)
        {
            if (test-path -Path $sp.fullname -PathType Container)
            {
                $PsbModule = [PsbModule]::new()
                $PsbModule.Name = $sp.Name
                $PsbModule.FolderPath = $sp.FullName
                $PsbModule.DefinitionFilePath = Join-Path -Path $sp.fullname -ChildPath "$($PsbModule.Name).psd1"

                #Check for definition file
                if (-not (test-path -Path $PsbModule.DefinitionFilePath -PathType Leaf))
                {
                    throw "Module: $($PsbModule.Name) invalid. Expected definition file: '$($PsbModule.Name).psd1' not found"
                }

                $PsbModule.ModuleInfo = Get-Module -FullyQualifiedName $PsbModule.FolderPath -ListAvailable -Refresh -ErrorAction Stop
                $PsbModule.Version = $PsbModule.ModuleInfo.Version

                #return result
                $PsbModule
            }
        }
    }
}

#region classes

class PsbModule
{
    [string]$Name
    [version]$Version
    [psmoduleinfo]$ModuleInfo
    [string]$FolderPath
    [string]$DefinitionFilePath
}

#endregion