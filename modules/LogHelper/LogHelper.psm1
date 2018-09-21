#region Public Functions

function Register-LhConfiguration
{
    [CmdletBinding()]
    param 
    (
        #ConfigurationDefinition
        [Parameter(Mandatory = $true,ParameterSetName='Definition')]
        [hashtable[]]$ConfigurationDefinition,

        #PsdConfigurationFilePath
        [Parameter(Mandatory = $true,ParameterSetName='PsdFile')]
        [string[]]$PsdConfigurationFilePath,

        #JsonConfigurationFilePath
        [Parameter(Mandatory = $true,ParameterSetName='JsonFile')]
        [string[]]$JsonConfigurationFilePath
    )

    process
    {
        #Initialize Configurations
        try
        {
            $Configurations = New-Object -TypeName System.Collections.ArrayList -ErrorAction Stop
            switch ($PSCmdlet.ParameterSetName)
            {
                'Definition' {

                    $ConfigurationDefinition | foreach {
                        $null = $Configurations.Add([pscustomobject]$_)
                    }
                    break

                }

                'PsdFile' {

                    $PsdConfigurationFilePath | foreach {
                         $ConfigAsHT = Import-PowerShellDataFile -Path $_ -ErrorAction Stop

                         #Parse InitializationScript
                         $ConfigAsHT.InitializationScript = [scriptblock]::Create($ConfigAsHT.InitializationScript.ToString().Trim('{}'))
                         
                         #Parse MessageTypes
                         $ConfigAsHT.MessageTypes = [pscustomobject]$ConfigAsHT.MessageTypes
                         foreach ($Property in $ConfigAsHT.MessageTypes.psobject.Properties)
                         {
                            $Property.Value = [scriptblock]::Create($Property.Value.ToString().Trim('{}'))
                         }
                         
                         $null = $Configurations.Add([pscustomobject]$ConfigAsHT)
                    }
                    break

                }

                'JsonFile' {

                    foreach ($JsonConfig in $JsonConfigurationFilePath)
                    {
                        $Config = get-content -Path $JsonConfig -ErrorAction Stop -raw | ConvertFrom-Json

                        #Convert InitializationScript to ScriptBlock
                        if ($Config.InitializationScript)
                        {
                            $Config.InitializationScript = [scriptblock]::Create($Config.InitializationScript)
                        }

                        #Convert MessageTypes to ScriptBlocks
                        $Config.MessageTypes.psobject.Properties | foreach {
                            $Config.MessageTypes."$($_.Name)" = [scriptblock]::Create($_.Value)
                        }

                        $null = $Configurations.Add($Config)
                    }

                    break

                }

                default {
                    throw "Unsupported ParameterSetName: $_"
                }
            }
        }
        catch
        {
            throw "Initialize Configurations failed. Details: $_"
        }

        #Validate ConfigurationDefinition
        try
        {
            #Check if Only one definition is set as default
            if (($Configurations | Where-Object {$_.Default} | Measure-Object).Count -gt 1)
            {
                throw "Only one ConfigurationDefinition can be set as default"
            }
        }
        catch
        {
            throw "Validate ConfigurationDefinition failed. Details: $_"
        }

        #Set the default Configuration
        try
        {
            if ($Configurations.Default -contains $true)
            {
                $CurrentDefaultConfiguration = $LHConfigurationStore | Where-Object {$_.Default}
                if ($CurrentDefaultConfiguration)
                {
                    $CurrentDefaultConfiguration.Default = $false
                }
            }
        }
        catch
        {
            throw "Set the default Configuration failed. Details: $_"
        }

        #Register Configuration
        try
        {
            $Configurations | ForEach-Object {
                $null = $LHConfigurationStore.Add($_)
            }
        }
        catch
        {
            throw "Register Configuration failed. Details: $_"
        }

        #Run InitializationScripts
        try
        {
            Write-Verbose 'Run InitializationScripts started'
        
            $Configurations | foreach {
                if ($_.InitializationScript)
                {
                    Invoke-Command -ScriptBlock $_.InitializationScript -NoNewScope -ErrorAction Stop
                }
            }
                    
            Write-Verbose 'Run InitializationScripts completed'
        }
        catch
        {
            throw "Run InitializationScripts failed. Details: $_"
        }
    }
}

function Write-LhEvent
{
    [CmdletBinding()]
    param 
    (
        #Type
        [Parameter(Mandatory = $true)]
        [string]$Type,

        #LhConfigurationName
        [Parameter(Mandatory = $false)]
        [string]$LhConfigurationName,

        #Message
        [Parameter(Mandatory = $true, ParameterSetName = 'InputAsString')]
        [string]$Message,

        #InputObject
        [Parameter(Mandatory = $true, ParameterSetName = 'InputAsHashtable')]
        [hashtable]$InputObject
    )
    
    process
    {
        if ($PSBoundParameters.ContainsKey('LhConfigurationName'))
        {
            $CurrentConfiguration = $LHConfigurationStore | Where-Object {$_.Name -eq $LhConfigurationName}
        }
        else
        {
            $CurrentConfiguration = $LHConfigurationStore | Where-Object {$_.Default}
        }

        if ($CurrentConfiguration.MessageTypes."$Type")
        {
            $InvokeCommandParams = @{
                ScriptBlock=$CurrentConfiguration.MessageTypes."$Type"
                NoNewScope=$true
            }
            if ($PSBoundParameters.ContainsKey('Message'))
            {
                $InvokeCommandParams.Add('ArgumentList',@{Message=$Message})
            }
            else {
                $InvokeCommandParams.Add('ArgumentList',$InputObject)
            }
            Invoke-Command @InvokeCommandParams -ErrorAction Stop
        }
        else
        {
            throw "MessageType: $Type is not present in LhConfiguration: $($CurrentConfiguration.Name)"
        }
        
    }
}

#endregion

#region Internal Variables

$LHConfigurationStore = New-Object System.Collections.ArrayList -ErrorAction Stop

#endregion