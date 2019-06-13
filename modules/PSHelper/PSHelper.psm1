#region Private Functions
function Get-PSScriptContent
{
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
        #ScriptBlock
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [System.Management.Automation.Language.ScriptBlockAst]$ScriptBlock
    )
    
    Begin
    {
          
    }

    Process
    {
        $SB = New-Object -TypeName System.Text.StringBuilder -ErrorAction Stop

        #Add ParamBlcok
        if (-not [String]::IsNullOrEmpty($ScriptBlock.ParamBlock))
        {
            $null = $SB.AppendLine($ScriptBlock.ParamBlock.ToString())
        }

        #Add DynamicParamBlock
        if (-not [String]::IsNullOrEmpty($ScriptBlock.DynamicParamBlock))
        {
            $null = $SB.AppendLine($ScriptBlock.DynamicParamBlock.ToString())
        }

        #Add BeginBlock
        if (-not [String]::IsNullOrEmpty($ScriptBlock.BeginBlock))
        {
            $null = $SB.AppendLine($ScriptBlock.BeginBlock.ToString())
        }

        #Add ProcessBlock
        if (-not [String]::IsNullOrEmpty($ScriptBlock.ProcessBlock))
        {
            $null = $SB.AppendLine($ScriptBlock.ProcessBlock.ToString())
        }

        #Add EndBlock
        if (-not [String]::IsNullOrEmpty($ScriptBlock.EndBlock))
        {
            $null = $SB.AppendLine($ScriptBlock.EndBlock.ToString())
        }

        $SB.ToString()
    }

    End
    {

    }
}
#endregion

#region Public Functions
function Add-PSModulePathEntry
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Path
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [string[]]$Path,

        #Force
        [Parameter(Mandatory = $false, ParameterSetName = 'NoRemoting_Default')]
        [switch]$Force = $false,

        #Scope
        [Parameter(Mandatory = $false, ParameterSetName = 'NoRemoting_Default')]
        [System.EnvironmentVariableTarget[]]$Scope = 'Machine'
    )
   
    Process
    {
        $Scope | foreach {

            #Get Current Entries
            $CurrentEntries = Get-PSModulePath -Scope $_
            $CurPSModulePathArr = New-Object -TypeName System.Collections.ArrayList
            foreach ($Entry in $CurrentEntries)
            {
                if (-not [string]::IsNullOrEmpty($Entry))
                {
                    $null = $CurPSModulePathArr.Add($Entry)
                }
            }

            #Add Entries
            foreach ($Item in $Path)
            {
                if ($CurPSModulePathArr -notcontains $Item)
                {
                    if ((Test-Path $Item) -or ($Force.IsPresent))
                    {
                        $null = $CurPSModulePathArr.Add($Item)
                    }
                    else
                    {
                        Write-Error -Message "Path: $Item does not exits" -ErrorAction Stop
                    }
                }
            }

            [System.Environment]::SetEnvironmentVariable('PsModulePath', ($CurPsModulePathArr -join ';'), [System.EnvironmentVariableTarget]::$_)
        }
    }
}

function Set-PSModulePath
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Path
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [string[]]$Path,

        #Force
        [Parameter(Mandatory = $false, ParameterSetName = 'NoRemoting_Default')]
        [switch]$Force = $false,

        #Scope
        [Parameter(Mandatory = $false, ParameterSetName = 'NoRemoting_Default')]
        [System.EnvironmentVariableTarget[]]$Scope = 'Machine'
    )
    
    Begin
    {
          
    }

    Process
    {
        $Scope | foreach {
            $CurPsModulePathArr = New-Object System.Collections.ArrayList
            foreach ($Item in $Path)
            {
                if ((Test-Path $Item) -or ($Force.IsPresent))
                {
                    $CurPsModulePathArr += $Item
                }
                else
                {
                    Write-Error -Message "Path: $Item does not exits" -ErrorAction Stop
                }

            }
            [System.Environment]::SetEnvironmentVariable('PsModulePath', ($CurPsModulePathArr -join ';'), $_)
        }
    }

    End
    {

    }
}

function Get-PSModulePath
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param
    (
        #Scope
        [Parameter(Mandatory = $false, ParameterSetName = 'NoRemoting_Default')]
        [System.EnvironmentVariableTarget[]]$Scope = 'Machine'
    )
    
    Process
    {
        $Scope | foreach { [System.Environment]::GetEnvironmentVariable('PsModulePath', $_) -split ';' }
    }
}

function Remove-PSModulePathEntry
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Path
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [string[]]$Path,

        #Scope
        [Parameter(Mandatory = $false, ParameterSetName = 'NoRemoting_Default')]
        [System.EnvironmentVariableTarget[]]$Scope = 'Machine'
    )

    Process
    {
        $Scope | foreach {

            #Get Current Entries
            $CurrentEntries = Get-PSModulePath -Scope $_
            $CurPSModulePathArr = New-Object -TypeName System.Collections.ArrayList
            foreach ($Entry in $CurrentEntries)
            {
                if (-not [string]::IsNullOrEmpty($Entry))
                {
                    $null = $CurPSModulePathArr.Add($Entry)
                }
            }

            #Remove Entries
            foreach ($Item in $Path)
            {
                if ($CurPsModulePathArr -contains $Item)
                {
                    $CurPsModulePathArr.Remove($Item)
                }
                else
                {
                    Write-Warning "PSModulePath does not contains: $Item"
                }
            }

            [System.Environment]::SetEnvironmentVariable('PsModulePath', ($CurPsModulePathArr -join ';'), $_)
        }
    }
}

function Test-PSModule
{
    [CmdletBinding()]
    [OutputType([PSModuleValidation])]
    param
    (
        #ModulePath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [System.IO.DirectoryInfo[]]$ModulePath
    )
    
    Process
    {
        foreach ($Item in $ModulePath)
        {
            $ModuleValidation = [PSModuleValidation]::new()

            #Resolve Module Definition File
            try
            {
                Write-Verbose "Resolve Module Definition File started"
			
                $ModuleDefinitionFileName = $Item.Name + '.psd1'
                $ModuleDefinitionFile = Get-ChildItem -Path $item.FullName -Recurse -filter $ModuleDefinitionFileName -ErrorAction Stop -File
                if (-not $ModuleDefinitionFile)
                {
                    throw "$ModuleDefinitionFileName not found"
                }
                Write-Verbose "Resolve Module Definition File completed"
            }
            catch
            {
                Write-Error "Resolve Module Definition File failed. Details: $_" -ErrorAction 'Stop'
            }


            #Validate Module
            try
            {
                Write-Verbose "Validate Module started"
                $ModuleInfo = Get-Module -ListAvailable -FullyQualifiedName $ModuleDefinitionFile.FullName -Refresh -ErrorAction Stop | sort -Property Version | select -Last 1
                if ($ModuleInfo)
                {
                    $ModuleValidation.IsModule = $true
                    $ModuleValidation.ModuleInfo = $ModuleInfo
                }
      
                Write-Verbose "Validate Module completed"
            }
            catch
            {
            }


            #Validate Version Integrity
            if ($ModuleValidation.IsModule)
            {
                #Check Version Control
                try
                {
                    $ModulePsd = Import-PSDataFile -FilePath $ModuleValidation.ModuleInfo.Path -ErrorAction Stop
                    $VersionControl = $ModulePsd.PrivateData.VersionControl | ConvertFrom-Json -ErrorAction Stop
                }
                catch
                {

                }

                if ($VersionControl)
                {
                    $ModuleValidation.SupportVersonControl = $true
                    $GetFileHash_Params = @{
                        Path = (Join-Path -Path $ModuleValidation.ModuleInfo.ModuleBase -ChildPath $ModuleValidation.ModuleInfo.RootModule -ErrorAction Stop)
                    }
                    if ($VersionControl.HashAlgorithm)
                    {
                        $GetFileHash_Params.Add('Algorithm', $VersionControl.HashAlgorithm)
                    }
                    $CurrentHash = Get-FileHash @GetFileHash_Params -ErrorAction Stop

                    if ($VersionControl.Version -eq $ModuleValidation.ModuleInfo.Version)
                    {
                        if ($VersionControl.Hash -eq $CurrentHash.Hash)
                        {
                            $ModuleValidation.IsVersionValid = $true
                        }
                        else
                        {
                            $ModuleValidation.IsNewVersion = $true
                        }
                    }
                }
            }

            #Validate IsReadyForPackaging
            if ($ModuleValidation.IsModule)
            {
                if ($ModuleValidation.ModuleInfo.Author -and $ModuleValidation.ModuleInfo.Description)
                {
                    $ModuleValidation.IsReadyForPackaging = $true
                }
            }

            $ModuleValidation
        }
    }
}

function Test-PSScript
{
    [CmdletBinding()]
    [OutputType([PSModuleValidation])]
    param
    (
        #ScriptPath
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ScriptPath,
		
        #UseScriptConfigFile
        [Parameter(Mandatory = $false)]
        [switch]$UseScriptConfigFile
    )

    Process
    {
        foreach ($Item in $ScriptPath)
        {
            $ScriptValidation = [PSScriptValidation]::new()

			#Get ScriptConfig
			if ($UseScriptConfigFile.IsPresent)
			{
                $ScriptValidation.ScriptConfig = [PSScriptConfig]::new()
				$ScriptConfigFilePath = Join-Path -Path $Item.DirectoryName -ChildPath "$($Item.BaseName).config.json"
				if (Test-Path -Path $ScriptConfigFilePath)
				{
					$ScriptConfig = Get-Content -Path $ScriptConfigFilePath -raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

					#Parse RequiredModules
					if ($ScriptConfig.RequiredModules)
					{
						$ScriptConfig.RequiredModules | foreach {
							$ScriptValidation.ScriptConfig.RequiredModules.add($_)
						}
					}
				}
			}

            #Validate Script
            try
            {
                Write-Verbose "Validate Script started"
                $ScriptInfo = Test-ScriptFileInfo -Path $Item.FullName -ErrorAction Stop
                if ($ScriptInfo)
                {
                    $ScriptValidation.IsScript = $true
                    $ScriptValidation.ScriptInfo = $ScriptInfo
                }
      
                Write-Verbose "Validate Script completed"
            }
            catch
            {
                if ($_.FullyQualifiedErrorId -ilike '*ScriptParseError*')
                {
                    foreach ($item in $_.TargetObject)
                    {
                        $ScriptValidation.ValidationErrors += @"
At $($item.Extent.File) line:$($item.Extent.StartLineNumber) expr:$($item.Extent)
+ [$($item.ErrorId)] $($item.Message)
"@
                    }
                }
            }

            #Validate Version Integrity
            if ($ScriptValidation.IsScript)
            {
                #Check Version Control
                try
                {
                    $VersionControl = $ScriptValidation.ScriptInfo.PrivateData | ConvertFrom-Json -ErrorAction Stop | Select-Object -ExpandProperty VersionControl
                }
                catch
                {

                }

                if ($VersionControl)
                {
                    $ScriptValidation.SupportVersonControl = $true

                    if ($VersionControl.Version -eq $ScriptValidation.ScriptInfo.Version)
                    {
                        #Calculate scriptContent hash
                        $ScriptContent_Raw = Get-Command -Name $ScriptValidation.ScriptInfo.Path -ErrorAction Stop
                        $ScriptContent = Get-PSScriptContent -ScriptBlock $ScriptContent_Raw.ScriptBlock.Ast -ErrorAction Stop
                        $ScriptContent_BA = [System.Text.Encoding]::UTF8.GetBytes($ScriptContent)
                        $ScriptContent_MemoryStream = New-Object -TypeName System.IO.MemoryStream -ArgumentList @(, $ScriptContent_BA)
                        $GetFileHash_Params = @{
                            InputStream = $ScriptContent_MemoryStream
                        }
                        if ($VersionControl.HashAlgorithm)
                        {
                            $GetFileHash_Params.Add('Algorithm', $VersionControl.HashAlgorithm)
                        }
                        $CurrentHash = Get-FileHash @GetFileHash_Params -ErrorAction Stop
                        $ScriptContent_MemoryStream.Dispose()
                        if ($VersionControl.Hash -eq $CurrentHash.Hash)
                        {
                            $ScriptValidation.IsVersionValid = $true
                        }
                        else
                        {
                            $ScriptValidation.IsNewVersion = $true
                        }
                    }
                }
            }

            #Validate IsReadyForPackaging
            if ($ScriptValidation.IsScript)
            {
                if ($ScriptValidation.ScriptInfo.Author -and $ScriptValidation.ScriptInfo.Description)
                {
                    $ScriptValidation.IsReadyForPackaging = $true
                }
            }

            $ScriptValidation
        }
    }
}

function Update-PSModuleVersion
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #ModulePath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [System.IO.DirectoryInfo[]]$ModulePath
    )
    
    Begin
    {
          
    }

    Process
    {
        $ModuleValidation = Test-PSModule -ModulePath $ModulePath -ErrorAction Stop
        if ($ModuleValidation.IsModule)
        {
            $ModuleInfo = $ModuleValidation.ModuleInfo
            $CurrentVersion = Get-Version -InputObject $ModuleInfo.Version
            $NewVersion = [System.Version]::new($CurrentVersion.Major, $CurrentVersion.Minor, $CurrentVersion.Build, ($CurrentVersion.Revision + 1))
            $NewHash = Get-FileHash -Path (Join-Path -Path $ModuleValidation.ModuleInfo.ModuleBase -ChildPath $ModuleValidation.ModuleInfo.RootModule -ErrorAction Stop) -ErrorAction Stop
            $VersionControlAsJson = ConvertTo-Json -InputObject ([pscustomobject]@{
                    Hash          = $NewHash.Hash
                    HashAlgorithm = $NewHash.Algorithm
                    Version       = $NewVersion.ToString()
                }) -ErrorAction Stop -Compress
            Update-ModuleManifest -Path $ModuleValidation.ModuleInfo.Path -ModuleVersion $NewVersion -PrivateData @{
                VersionControl = $VersionControlAsJson
            } -ErrorAction Stop
        }
    }

    End
    {

    }
}

function Update-PSScriptVersion
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #ModulePath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [System.IO.FileInfo[]]$ScriptPath
    )
    
    Begin
    {
          
    }

    Process
    {
        foreach ($item in $ScriptPath)
        {
            $ScriptValidation = Test-PSScript -ScriptPath $item -ErrorAction Stop
            if ($ScriptValidation.IsScript)
            {
                $ScriptInfo = $ScriptValidation.ScriptInfo
                $CurrentVersion = [System.Version]::Parse($ScriptInfo.Version)
                $NewVersion = [System.Version]::new($CurrentVersion.Major, $CurrentVersion.Minor, $CurrentVersion.Build, ($CurrentVersion.Revision + 1))

                #Calculate scriptContent hash
                $ScriptContent_Raw = Get-Command -Name $ScriptInfo.Path -ErrorAction Stop
                $ScriptContent = Get-PSScriptContent -ScriptBlock $ScriptContent_Raw.ScriptBlock.Ast -ErrorAction Stop
                $ScriptContent_BA = [System.Text.Encoding]::UTF8.GetBytes($ScriptContent)
                $ScriptContent_MemoryStream = New-Object -TypeName System.IO.MemoryStream -ArgumentList @(, $ScriptContent_BA)
                $NewHash = Get-FileHash -InputStream $ScriptContent_MemoryStream -ErrorAction Stop
                $ScriptContent_MemoryStream.Dispose()
                $VersionControlAsJson = ConvertTo-Json -InputObject ([pscustomobject]@{
                        VersionControl = [pscustomobject]@{
                            Hash          = $NewHash.Hash
                            HashAlgorithm = $NewHash.Algorithm
                            Version       = $NewVersion.ToString()
                        }
                    }) -ErrorAction Stop -Compress
                Update-ScriptFileInfo -Path $ScriptInfo.path -PrivateData $VersionControlAsJson -Version $NewVersion -ErrorAction Stop
            }
        }
    }

    End
    {

    }
}

function Update-PSScriptConfig
{
    [CmdletBinding()]
    param
    (
        #ScriptPath
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$ScriptPath,

        #ScriptConfig
        [Parameter(Mandatory = $true)]
        [PSScriptConfig]$ScriptConfig
    )

    process
    {
        $ScriptConfigFilePath = Join-Path -Path $ScriptPath.DirectoryName -ChildPath "$($ScriptPath.BaseName).config.json"
        out-File -FilePath $ScriptConfigFilePath -InputObject ($ScriptConfig | ConvertTo-Json -ErrorAction Stop) -Force
    }
}
#endregion

#region Public Classes

class PSModuleValidation
{

    [psmoduleinfo]$ModuleInfo
    [bool]$IsModule = $false
    [bool]$IsVersionValid = $false
    [bool]$IsNewVersion = $false
    [bool]$SupportVersonControl = $false
    [bool]$IsReadyForPackaging = $false
    hidden [bool]$_test = (Add-Member -InputObject $this -MemberType ScriptProperty -Name IsValid -Value {
            if ($this.IsModule -and $this.IsVersionValid -and $this.SupportVersonControl)
            {
                $true
            }
            else
            {
                $false
            }
        } -SecondValue { })

}

class PSScriptConfig
{
	[System.Collections.Generic.List[psobject]]$RequiredModules = ([System.Collections.Generic.List[psobject]]::new())
}

class PSScriptValidation
{

	[PSCustomObject]$ScriptInfo
	[PSScriptConfig]$ScriptConfig = $Null
    [bool]$IsScript = $false
    [bool]$IsVersionValid = $false
    [bool]$IsNewVersion = $false
    [bool]$SupportVersonControl = $false
    [bool]$IsReadyForPackaging = $false
    [string[]]$ValidationErrors = ''
    hidden [bool]$_test = (Add-Member -InputObject $this -MemberType ScriptProperty -Name IsValid -Value {
            if ($this.IsScript -and $this.IsVersionValid -and $this.SupportVersonControl)
            {
                $true
            }
            else
            {
                $false
            }
        } -SecondValue { })

}
#endregion