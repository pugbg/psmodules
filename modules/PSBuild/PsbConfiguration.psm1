function Get-PsbRawConfiguration
{
    [CmdletBinding()]
    param
    (
        #Path
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    begin
    {
        $ConfigurationVariableInKey_Regex = "\[variable\('(.*)'\)\]"
        $ConfigurationVariableKey_Regex = "`"\[variable\('(.*)'\)\]`""
    }

    process
    {
        $ConfigurationContext = @{
            Variables = @{ }
        }

        #TODO: Validate configuration against Json schema

        #Initialize Configuration Variables
        try
        {
            $ConfigurationRaw = Get-Content -Path $Path -raw -ErrorAction Stop
            $Configuration = $ConfigurationRaw | ConvertFrom-Json -ErrorAction Stop
            foreach ($Var in $Configuration.Variables.psobject.Properties)
            {
                if ($Var.TypeNameOfValue -eq 'System.String')
                {
                    $ConfigurationContext['Variables'].Add($Var.Name, (Invoke-Expression -Command "`"$($Var.Value)`""))
                }
                else
                {
                    $ConfigurationContext['Variables'].Add($Var.Name, $Var.Value)
                }
            }
        }
        catch
        {
            throw "Initialize Configuration Variables failed. Details: $_"
        }

        #Initialize Configuration
        try
        {
            #Replace Variables in Keys
            $VariablesInKey = $ConfigurationRaw | Select-String -Pattern $ConfigurationVariableInKey_Regex -AllMatches -ErrorAction Stop
            foreach ($vik in $VariablesInKey.Matches)
            {
                if ($ConfigurationContext['Variables'].ContainsKey($vik.Groups[1].Value))
                {
                    $ConfigurationRaw = $ConfigurationRaw.Replace($vik.Groups[0].Value, $ConfigurationContext['Variables'][$vik.Groups[1].Value].ToString().ToLower())
                }
                else
                {
                    throw "Variable: '$($vik.Groups[1].Value)' not found."
                }
            }

            #Replace Variables which are Keys
            $VariablesKey = $ConfigurationRaw | Select-String -Pattern $ConfigurationVariableKey_Regex -AllMatches -ErrorAction Stop
            foreach ($vk in $VariablesKey.Matches)
            {
                if ($ConfigurationContext['Variables'].ContainsKey($vk.Groups[1].Value))
                {
                    $ConfigurationRaw = $ConfigurationRaw.Replace($vk.Groups[0].Value, $ConfigurationContext['Variables'][$vk.Groups[1].Value].ToString().ToLower())
                }
                else
                {
                    throw "Variable: '$($vk.Groups[1].Value)' not found."
                }
            }

            #Return Configuration
            $ConfigurationRaw | ConvertFrom-Json -ErrorAction Stop

        }
        catch
        {
            throw "Initialize configuration failed. Details: $_"
        }

        
    }
}

function Get-PsbConfiguration
{
    [CmdletBinding()]
    param
    (
        #Path
        [Parameter(Mandatory = $true)]
        [ValidateScript( {
                if (Test-Path -Path $_)
                {
                    $true
                }
                else
                {
                    throw "Configuration file: $_ not found"
                }
            })]
        [string]$Path
    )

    process
    {
        #Get RawConfiguration
        try
        {
            $RawConfiguration = Get-PsbRawConfiguration -Path $Path -ErrorAction Stop
            [PsbConfiguration]$RawConfiguration
        }
        catch
        {
            throw "Get RawConfiguration failed. Details: $_"
        }

    }
}

#region Classes

class PsbConfiguration
{
    [psobject]$variables
    [PsbGlobalConfiguration]$globalSettings
    [System.Collections.Generic.List[PsbItemConfiguration]]$itemGroup = ([System.Collections.Generic.List[PsbItemConfiguration]]::new())
}

class PsbGlobalConfiguration
{
    [string]$DependencyPath
    [string]$OutputPath
    [PsbCommandConfiguration]$CommandSettings
    [PsbCommandReferenceConfiguration]$CommandReferenceSettings
    [PsbDependencyConfiguration]$DependencySettings
}

class PsbItemConfiguration : PsbGlobalConfiguration
{
    [String]$Name
    [ValidateSet('Scripts', 'Modules')]
    [string]$Type
    [System.Collections.Generic.List[string]]$SourcePath = ([System.Collections.Generic.List[string]]::new())
}

class PsbCommandConfiguration
{
    [ValidateSet('Enabled', 'Notify', 'Disabled')]
    [string]$CheckForDuplicateNames
}

class PsbCommandReferenceConfiguration
{
    [ValidateSet('Required', 'NotifyIfMissing', 'NotRequired')]
    [string]$Mode = 'Notify'
    [System.Collections.Generic.List[string]]$ExcludedSources = ([System.Collections.Generic.List[string]]::new())
    [System.Collections.Generic.List[string]]$ExcludedCommands = ([System.Collections.Generic.List[string]]::new())
}

class PsbDependencyConfiguration
{
    [ValidateSet('Resolve', 'DoNotResolve')]
    [string]$Mode = 'Resolve'
    [bool]$UpdateToLatestVersion = $false
}

#endregion