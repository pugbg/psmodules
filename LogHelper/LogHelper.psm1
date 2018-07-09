#region Public Functions

function Register-LhConfiguration
{
    [CmdletBinding()]
    param 
    (
        #ConfigurationDefinition
        [Parameter(Mandatory = $true)]
        [hashtable[]]$ConfigurationDefinition
    )

    process
    {
        #Validate ConfigurationDefinition
        try
        {
            #Check if Only one definition is set as default
            if (($ConfigurationDefinition | Where-Object {$_.Default} | Measure-Object).Count -gt 1)
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
            if ($ConfigurationDefinition.Default -contains $true)
            {
                $CurrentDefaultConfiguration = $LHConfigurationStore | Where-Object {$_.Default}
                if ($CurrentDefaultConfiguration)
                {
                    $CurrentDefaultConfiguration['Default'] = $false
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
            $ConfigurationDefinition | ForEach-Object {
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
        
            $ConfigurationDefinition | foreach {
                if ($_.ContainsKey('InitializationScript'))
                {
                    Invoke-Command -ScriptBlock $_['InitializationScript'] -NoNewScope -ErrorAction Stop
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

        if ($CurrentConfiguration['MessageTypes'].ContainsKey($Type))
        {
            $InvokeCommandParams = @{
                ScriptBlock=$CurrentConfiguration['MessageTypes'][$Type]
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