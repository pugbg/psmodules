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