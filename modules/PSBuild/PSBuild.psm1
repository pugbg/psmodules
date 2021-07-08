#region Private Functions

function priv_Export-Artifact
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SourcePath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [ValidateScript( {
                if (-not (test-path $_))
                {
                    throw "$_ does not exist"
                }
                else
                {
                    $true
                }
            })]
        [string]$SourcePath,

        #DestinationPath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [string]$DestinationPath,

        #ModuleVersion
        [Parameter(Mandatory = $false, ParameterSetName = 'NoRemoting_Default')]
        [string]$Version,

        #Type
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [ValidateSet('Script', 'Module', 'ScriptWithConfig')]
        [string]$Type
    )

    Process
    {
        switch ($Type)
        {
            'Script'
            {
                #Check if Source and Destination are the same
                $SourceFolder = Split-Path -Path $SourcePath -Parent -ErrorAction Stop
                if ($SourceFolder -eq $DestinationPath)
                {
                    #Do nothing
                }
                else
                {
                    if (-not (Test-Path $DestinationPath))
                    {
                        $null = New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop
                    }
                    $null = Copy-Item -Path $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
                }

                break
            }

            'ScriptWithConfig'
            {
                #Check if Source and Destination are the same
                $SourceFolder = Split-Path -Path $SourcePath -Parent -ErrorAction Stop
                if ($SourceFolder -eq $DestinationPath)
                {
                    #Do nothing
                }
                else
                {
                    $ScriptConfigFileName = "$(([System.IO.FileInfo]$SourcePath).BaseName).config.json"
                    $ScriptConfigFilePath = Join-Path -Path $SourceFolder -ChildPath $ScriptConfigFileName
                    if (-not (Test-Path $DestinationPath))
                    {
                        $null = New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop
                    }
                    $null = Copy-Item -Path $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
                    $null = Copy-Item -Path $ScriptConfigFilePath -Destination $DestinationPath -Force -ErrorAction Stop
                }

                break
            }

            'Module'
            {
                $ModuleFolder = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $SourcePath
                $ObjectName = $ModuleFolder.BaseName
                #Calculcate DestinationFolder
                if ($PSBoundParameters.ContainsKey('Version'))
                {
                    $ObjectDestinationFolderTemp = Join-Path -Path $DestinationPath -ChildPath $ObjectName -ErrorAction Stop
                    $ObjectDestinationFolder = Join-Path -Path $ObjectDestinationFolderTemp -ChildPath $Version -ErrorAction Stop
                }
                else
                {
                    $ObjectDestinationFolder = Join-Path -Path $DestinationPath -ChildPath $ObjectName -ErrorAction Stop
                }

                #Check if Source and Destination are the same
                $SourceFolder = Split-Path -Path $SourcePath -Parent -ErrorAction Stop
                if ($SourceFolder -eq $ObjectDestinationFolder)
                {
                    #Do nothing
                }
                else
                {
                    #Validate DestinationFolder
                    if (Test-Path -Path $ObjectDestinationFolder)
                    {
                        Remove-Item -Path $ObjectDestinationFolder -ErrorAction Stop -Force -Confirm:$false -Recurse
                    }
                    $null = New-Item -Path $ObjectDestinationFolder -ItemType Directory -ErrorAction Stop

                    #Copy Module content
                    $ModuleFilesToExclude = @(
                        'obj'
                        'bin'
                        'CSharpAssemblies'
                        '*.pssproj'
                        '*.pssproj.user'
                        '*.csproj'
                        '*.csproj.user'
                        '*.vspscc'
                        '*.pdb'
                        '*.cs'
                        '*.tests.ps1'
                        'packages.config'
                        'Tests'
                        'System.Management.Automation.dll'
                    )
                    $null = Copy-Item -Path "$SourcePath\*" -Destination $ObjectDestinationFolder -Recurse -Exclude $ModuleFilesToExclude
                }
                break
            }

            default
            {
                throw "Unknown Type: $Type"
            }
        }
    }
}

function priv_Publish-PSModule
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #ModuleInfo
        [Parameter(Mandatory = $true)]
        [PSModuleInfo]$ModuleInfo,

        #Credential
        [Parameter(Mandatory = $false)]
        [PScredential]$Credential,

        #Repository
        [Parameter(Mandatory = $false)]
        [string]$Repository,

        #NuGetApiKey
        [Parameter(Mandatory = $false)]
        [string]$NuGetApiKey,

        #Force
        [Parameter(Mandatory = $false)]
        [switch]$Force,

        #PublishDependantModules
        [Parameter(Mandatory = $false)]
        [switch]$PublishDependantModules = $true,

        #VerbosePrefix
        [Parameter(Mandatory = $false)]
        [string]$VerbosePrefix,
		
        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )

    Process
    {
        #Resolve ModuleRootFolder
        try
        {
            $ModuleLeafFolder = Split-Path -Path $ModuleInfo.ModuleBase -Leaf
            $ModuleVersion = New-Object System.Version
            if ([System.Version]::TryParse($ModuleLeafFolder, [ref]$ModuleVersion))
            {
                $ModuleVersionFolder = Split-Path -Path $ModuleInfo.ModuleBase -Parent
                $ModuleRootFolder = Split-Path -Path $ModuleVersionFolder -Parent
            }
            else
            {
                $ModuleRootFolder = Split-Path -Path $ModuleInfo.ModuleBase -Parent
            }
        }
        catch
        {
            Write-Error "Resolve ModuleRootFolder failed. Details: $_" -ErrorAction 'Stop'
        }
		
        #Publish RequiredModules
        $ModsToPublish = $ModuleInfo.RequiredModules | Where-Object { $ModuleInfo.PrivateData.PSData.ExternalModuleDependencies -notcontains $_.Name }
        foreach ($ReqModule in $ModsToPublish)
        {
            $ReqModuleFound = $false
            #Check if Required Module is present in the same folder as the current module
            try
            {
                $ReqModuleInfo = Get-Module -ListAvailable -FullyQualifiedName "$ModuleRootFolder\$($ReqModule.Name)" -Refresh -ErrorAction Stop
                if ($ReqModuleInfo)
                {
                    #If multiple versions are available, select latest one.
                    $ReqModuleInfo = $ReqModuleInfo | Sort-Object -Property Version | select -Last 1
                    if ($ReqModule.Version -and ($ReqModule.Version -le $ReqModuleInfo.Version))
                    {
                        $ReqModuleFound = $true
                    }
                    else
                    {
                        $ReqModuleFound = $true
                    }
                }
            }
            catch
            {

            }

            #Check if Required Module is present on the machine
            if (-not $ReqModuleFound)
            {
                try
                {
                    $ReqModuleInfo = Get-Module -Name $ReqModule.Name -ErrorAction Stop
                    if ($ReqModuleInfo)
                    {
                        #If multiple versions are available, select latest one.
                        $ReqModuleInfo = $ReqModuleInfo | Sort-Object -Property Version | select -Last 1
                        if ($ReqModule.Version -and ($ReqModule.Version -le $ReqModuleInfo.Version))
                        {
                            $ReqModuleFound = $true
                        }
                        else
                        {
                            $ReqModuleFound = $true
                        }
                    }
                }
                catch
                {

                }
            }

            if ($ReqModuleFound)
            {
                $PublishModuleAndDependacies_Params = @{ } + $PSBoundParameters
                $PublishModuleAndDependacies_Params['ModuleInfo'] = $ReqModuleInfo
                priv_Publish-PSModule @PublishModuleAndDependacies_Params
            }
            else
            {
                throw "Unable to find Required Module: $($ReqModule.Name)"
            }
        }

        #Publish Module
        try
        {
            $PublishModule_CommonParams = @{
                Repository = $Repository
            }

            if ($PSBoundParameters.ContainsKey('Credential'))
            {
                $PublishModule_CommonParams.Add('Credential', $Credential)
            }
            if ($PSBoundParameters.ContainsKey('Proxy'))
            {
                $PublishModule_CommonParams.Add('Proxy', $Proxy)
            }

            #Check if module already exist on the Repository
            try
            {
                Remove-Variable -Name ModExist -ErrorAction SilentlyContinue
                $private:ModExist = Find-Module @PublishModule_CommonParams -Name $ModuleInfo.Name -RequiredVersion $ModuleInfo.Version -ErrorAction Stop
            }
            catch
            {

            }
			
            if ($ModExist)
            {
                Write-Verbose "$VerbosePrefix`Module already exist on the PSGetRepo"
            }
            else
            {
                $PublishModule_Params = @{
                    Path = $ModuleInfo.ModuleBase
                } + $PublishModule_CommonParams
                if ($PSBoundParameters.ContainsKey('NuGetApiKey'))
                {
                    $PublishModule_Params.Add('NuGetApiKey', $NuGetApiKey)
                }
                Write-Verbose "$VerbosePrefix`Publishing new version"
                Publish-Module @PublishModule_Params -Force -ErrorAction Stop
            }

        }
        catch
        {
            Write-Error "Publish Module failed. Details: $_" -ErrorAction 'Stop'
        }
    }
}

function priv_Get-ModuleDefinition
{
    [CmdletBinding()]
    param
    (
        #ModulePath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Module')]
        [string]$ModulePath,

        #DestinationPath
        [Parameter(Mandatory = $true)]
        [string[]]$DestinationPath,

        #ProactiveRequiredModuleLoading
        [Parameter(Mandatory = $false)]
        [bool]$ProactiveRequiredModuleLoading = $false
    )

    Process
    {
        try
        {
            $JobParams = @{
                ArgumentList = @(@{
                    ModulePath = $ModulePath
                    DestinationPath = $DestinationPath
                    ProactiveRequiredModuleLoading = $ProactiveRequiredModuleLoading
                })
                ScriptBlock = {
			        
                    $VerbosePreference = 'SilentlyContinue'
                    $WarningPreference = 'SilentlyContinue'

                    $cfg = $args[0]
                    $hashSet = [System.Collections.Generic.HashSet[string]]::new(([System.Environment]::GetEnvironmentVariable('PsModulePath', [System.EnvironmentVariableTarget]::Process)).Split(";", [System.StringSplitOptions]::RemoveEmptyEntries), [System.StringComparer]::OrdinalIgnoreCase)
                    $changePending = $false
                    if($cfg.DestinationPath)
                    {
                        foreach($dstPath in $cfg.DestinationPath)
                        {
                            if((-not [string]::IsNullOrEmpty($dstPath)) -and [IO.Directory]::Exists($dstPath))
                            {
                                if($hashSet.Add($dstPath))
                                {
                                    $changePending = $true
                                }
                            }
                        }
                    }

                    if($changePending)
                    {
                        [System.Environment]::SetEnvironmentVariable('PsModulePath', ($hashSet -join ';'), [System.EnvironmentVariableTarget]::Process)
                    }

                    if($cfg.ProactiveRequiredModuleLoading)
                    {
                        function priv_ImportModule
                        {
                            [CmdletBinding()]
                            Param 
	                        (
                                [Parameter(Mandatory = $true)]
                                [hashtable[]]$ModuleInfo
                            )

                            foreach($modInfo in $ModuleInfo)
                            {
                                $ReqModObj = Get-Module -Name ($modInfo.ModuleName) -ListAvailable -Refresh -ErrorAction Stop -Verbose:$false | Sort-Object -Property Version -Descending | Select-Object -First 1

                                if(-not ($ReqModObj))
                                {
                                    if(Test-Path -Path $modInfo.Path)
                                    {
                                        $ReqModObj = Get-Module -Name ($modInfo.Path) -ListAvailable -Refresh -ErrorAction Stop -Verbose:$false | Sort-Object -Property Version -Descending | Select-Object -First 1
                                    }
                                }

                                if(-not ($ReqModObj))
                                {
                                    throw "Failed to load required module '$($modInfo.ModuleName)'. Module was not found."
                                }

                                if($ReqModObj.RequiredModules)
                                {
                                    priv_ImportModule -ModuleInfo @(@($ReqModObj.RequiredModules).ForEach{ @{ ModuleName = ($_.Name); ModuleVersion = ($_.Version); Path = ($_.Path) } })
                                }

                                if(-not (Get-Module -Name $ReqModObj.Name))
                                {
                               #     Write-Verbose -Message "DEBUG: Importing required module '$($modInfo.ModuleName)'" -Verbose
                                    $null = Import-Module -FullyQualifiedName ($ReqModObj.Path) -ErrorAction Stop -WarningAction SilentlyContinue -Verbose:$false
                                }
                            }
                        }

                        [IO.DirectoryInfo]$PrimaryModulePath = ($cfg.ModulePath)
                        $PrimaryModuleDefinitionFile = Get-ChildItem -Path ($PrimaryModulePath.FullName) -Recurse -filter "$($PrimaryModulePath.Name).psd1" -ErrorAction Stop -File
                        $PrimaryModuleObj = Get-Module -ListAvailable -FullyQualifiedName ($PrimaryModuleDefinitionFile.FullName) -Refresh -ErrorAction Stop -Verbose:$false

                        if($PrimaryModuleObj.RequiredModules)
                        {
                            priv_ImportModule -ModuleInfo @(@($PrimaryModuleObj.RequiredModules).ForEach{ @{ ModuleName = ($_.Name); ModuleVersion = ($_.Version); Path = ($_.Path) } })
                        }
                    }

                    $ModFresh = Import-Module -FullyQualifiedName ($cfg.ModulePath) -PassThru -ErrorAction Stop -WarningAction SilentlyContinue -Verbose:$false -ErrorVariable er

                    if (-not $ModFresh)
                    {
                        throw "Unable to Import Module: $($args[0]). Details: $er"
                    }
                
                    $ModFresh.Definition
                }
            }

            $Job = Start-Job @JobParams -Verbose:$false

            $null = Wait-Job -Job $Job -Verbose:$false

            Receive-Job -Job $Job -ErrorAction Stop -Verbose:$false  # returns the module definition as string
        }
        catch
        {
            throw "Failed to load Module Definition. Details: $_"
        }
        finally
        {
            Remove-Job -Job $Job -Force
        }
    }
}

function priv_Get-ScriptDefinition
{
    [CmdletBinding()]
    param
    (
        #ModulePath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Module')]
        [string]$ScriptPath
    )

    Process
    {
        try
        {
            $JobParams = @{
                ArgumentList = @(@{
                    ScriptPath = $ScriptPath
                })
                ScriptBlock = {
			        
                    $VerbosePreference = 'SilentlyContinue'
                    $WarningPreference = 'SilentlyContinue'

                    $cfg = $args[0]
                
                    (Get-Command -Name $cfg.ScriptPath -ErrorAction Stop -Verbose:$false).ScriptBlock.ToString()
                }
            }

            $Job = Start-Job @JobParams -Verbose:$false

            $null = Wait-Job -Job $Job -Verbose:$false

            Receive-Job -Job $Job -ErrorAction Stop -Verbose:$false  # returns the module definition as string
        }
        catch
        {
            throw "Failed to load Script Definition. Details: $_"
        }
        finally
        {
            Remove-Job -Job $Job -Force
        }
    }
}

<#
function priv_Analyse-ItemDependancies
{
    [CmdletBinding()]
    param
    (
        #ScriptBlock
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_ScriptBlock')]
        [scriptblock]$ScriptBlock,

        #ModulePath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Module')]
        [string]$ModulePath,

        #ScriptPath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Script')]
        [string]$ScriptPath,

  #      #GlobalCommandAnalysis
  #      [Parameter(Mandatory = $true)]
  #      [ref]$GlobalCommandAnalysis,

        #PSGetRepository
        [Parameter(Mandatory = $false)]
        [hashtable[]]$PSGetRepository,

        #CurrentDependancies
        [Parameter(Mandatory = $false)]
        [string[]]$CurrentDependancies,

        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )
    
    Process
    {
        #Construct JobParams
        $JobParams = @{
            GlobalCommandAnalysisAsJson = [PSBuild.Context]::Current.CommandsToModuleMapping.ToJson()
            CurrentDependancies         = $CurrentDependancies
            PSGetRepository             = $PSGetRepository
            PSBuildDllPath              = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq 'PSBuildEntities' } | select -ExpandProperty Location
            PSBuildModulePath           = (Get-Module -Name psbuild).Path
            AstExtensionsModulePath     = (Get-Module -Name AstExtensions).Path
        }
        if ($PSBoundParameters.ContainsKey('Proxy'))
        {
            $JobParams.Add('Proxy', $Proxy)
        }
        Switch ($PSCmdlet.ParameterSetName)
        {
            'NoRemoting_ScriptBlock'
            {
                $JobParams.Add('ScriptBlock', $ScriptBlock)
                break
            }
            'NoRemoting_Module'
            {
                $JobParams.Add('ModulePath', $ModulePath)
                break
            }
            'NoRemoting_Script'
            {
                $JobParams.Add('ScriptPath', $ScriptPath)
                break
            }
            default
            {
                throw "Unknown ParameterSet: $_"
            }
        }

        try
        {
            $Job = Start-Job -ScriptBlock {
                #Wait-Debugger
                $JobParams = $Using:JobParams
                Import-Module -FullyQualifiedName $JobParams["PSBuildModulePath"]
                Import-Module -FullyQualifiedName $JobParams["AstExtensionsModulePath"]
                Add-Type -Path $JobParams['PSBuildDllPath'] -ErrorAction Stop
                $GlobalCommandAnalysis = [PSBuild.CommandAnalysisCollection]::FromJson($JobParams['GlobalCommandAnalysisAsJson'])
                $LocalCommandAnalysis = [PSBuild.CommandAnalysisCollection]::New()
			
                #Get Module ScriptBlockAst
                if ($JobParams.ContainsKey('ModulePath'))
                {
                    $OldErrorActionPreference = $ErrorActionPreference
                    $OldVerbosePreference = $VerbosePreference
                    $OldWarningPreference = $WarningPreference
                    $ErrorActionPreference = 'Continue'
                    $VerbosePreference = 'SilentlyContinue'
                    $WarningPreference = 'SilentlyContinue'
                    $ModFresh = Import-Module -FullyQualifiedName $JobParams['ModulePath'] -PassThru -ErrorAction Stop -WarningAction SilentlyContinue -Verbose:$false -ErrorVariable er
                    $ErrorActionPreference = $OldErrorActionPreference
                    $VerbosePreference = $OldVerbosePreference
                    $WarningPreference = $OldWarningPreference
                    if (-not $ModFresh)
                    {
                        throw "Unable to Import Module: $($JobParams['ModulePath']). Details: $er"
                    }
                    $ModuleSb = [scriptblock]::Create($ModFresh.Definition)
                    $ScriptBlockAst = $ModuleSb.Ast
                }
                #Get Script ScriptBlockAst
                elseif ($JobParams.ContainsKey('ScriptPath'))
                {
                    $ScriptContent = Get-Command -Name $JobParams['ScriptPath'] -ErrorAction Stop -Verbose:$false
                    $ScriptBlockAst = $ScriptContent.ScriptBlock.Ast
                }
                #GetScriptBlockAst
                elseif ($JobParams.ContainsKey('ScriptBlock'))
                {
                    $ScriptBlockAst = $ScriptBlock.Ast
                }
                else
                {
                    throw "Unknown ParameterSet"
                }

                #Identify NonLocal commands
                try
                {
                    $LocalCommands = Get-AstStatement -Ast $ScriptBlockAst -Type FunctionDefinitionAst | Select-Object -ExpandProperty Name
                    $NonLocalCommands = Get-AstStatement -Ast $ScriptBlockAst -Type CommandAst | ForEach-Object { $_.GetCommandName() } | Group-Object -NoElement | Select-Object -ExpandProperty Name | Where-Object { $LocalCommands -notcontains $_ }
                }
                catch
                {
                    Write-Error "Identify NonLocal commands failed. Details: $_" -ErrorAction 'Stop'
                }

                #Resolve NonLocal commands against GlobalCommandAnalysis
                try
                {
                    foreach ($cmd in $NonLocalCommands)
                    {
                        $CmdResult = [PSBuild.CommandAnalysis]::new()
                        #Determine CmdName and Module
                        if ($cmd.Contains('\'))
                        {
                            $tempcmd = $cmd -split '\\'
                            $CmdResult.CommandSource = $tempcmd[0]
                            $CmdResult.CommandName = $tempcmd[1]
                        }
                        else
                        {
                            $CmdResult.CommandName = $cmd
                        }

                        #Check if command is already analyzed
                        if (-not $LocalCommandAnalysis.Contains($CmdResult.CommandName))
                        {
                            #Resolve command Source
                            if ($GlobalCommandAnalysis.Contains($CmdResult.CommandName))
                            {
                                #Source already resolved
                                $CmdResult = $GlobalCommandAnalysis[$CmdResult.CommandName]
                                $CmdResult.IsReferenced = $false
                                $CmdResult.IsFound = $true
                            }
                            else
                            {
                                #Check if command is local
                                if (-not $CmdResult.IsFound)
                                {
                                    try
                                    {
                                        $GetCommandParams = @{
                                            Name = $CmdResult.CommandName 
                                        }
                                        if ($CmdResult.CommandSource)
                                        {
                                            $SourceCandidate = $CmdResult.CommandSource
                                        }
                                        else
                                        {
                                            if ($JobParams.ContainsKey('CurrentDependancies'))
                                            {
                                                $SourceCandidate = $JobParams['CurrentDependancies']
                                            }
                                            else
                                            {
                                                Remove-Variable -Name SourceCandidate -ErrorAction SilentlyContinue
                                            }
                                        }
                                        if (-not [string]::IsNullOrEmpty($CmdResult.CommandSource))
                                        {
                                            $GetCommandParams.Add('Module', $CmdResult.CommandSource)
                                        }
                                        try
                                        {
                                            Remove-Variable -Name TempFindng -ErrorAction SilentlyContinue
                                            $TempFindng = Get-Command @GetCommandParams -ErrorAction Stop -Verbose:$false
                                            if ((-not $TempFindng) -and ($SourceCandidate))
                                            {
                                                $TempFindng = Get-Command @GetCommandParams -Module $SourceCandidate -ErrorAction Stop -Verbose:$false
                                            }
                                        }
                                        catch
                                        {
                                        }
                                        if ($TempFindng)
                                        {
                                            $CmdResult.CommandType = $TempFindng.CommandType
                                            if ($TempFindng.CommandType -eq 'Alias')
                                            {
                                                $TempFinding2 = Get-Command -Name $TempFindng.Name -ErrorAction Stop -Verbose:$false
                                                $CmdResult.CommandSource = $TempFinding2.Source
                                            }
                                            else
                                            {
                                                $CmdResult.CommandSource = $TempFindng.Source
                                            }

                                            $CmdResult.IsFound = $true
                                        }
                                    }
                                    catch
                                    {
                                        Write-Error "Check if command is local failed. Details: $_" -ErrorAction 'Stop'
                                    }
                                }
                            }

                            $null = $LocalCommandAnalysis.Add($CmdResult)
                        }
                    }
                }
                catch
                {
                    Write-Error "Resolve NonLocal Commands against CommandToModuleMapping failed. Details: $_" -ErrorAction Stop
                }

                #Resolve Missing commands against Proget
                if ($JobParams.ContainsKey('PSGetRepository'))
                {
                    try
                    {
                        $MissingCommandsAnalysis = $LocalCommandAnalysis | Where-Object { $_.IsFound -eq $false }
                        if ($MissingCommandsAnalysis)
                        {
                            $AssertPSRepository_Params = @{
                                PSGetRepository = $JobParams['PSGetRepository']
                            }
                            if ($JobParams.ContainsKey('Proxy'))
                            {
                                $AssertPSRepository_Params.Add('Proxy', $JobParams['Proxy'])
                            }
                            Assert-PSRepository @AssertPSRepository_Params -ErrorAction Stop

                            foreach ($Repo in $JobParams['PSGetRepository'])
                            {
                                #Refresh MissingCommandsAnalysis
                                $MissingCommandsAnalysis = $LocalCommandAnalysis | Where-Object { $_.IsFound -eq $false }
                                if ($MissingCommandsAnalysis)
                                {
                                    #Search for All MissingCommands
                                    $FindModule_Params = @{
                                        Command    = $MissingCommandsAnalysis.CommandName
                                        Repository = $Repo.Name
                                    }
                                    if ($Repo.ContainsKey('Credential'))
                                    {
                                        $FindModule_Params.Add('Credential', $Repo.Credential)
                                    }
                                    if ($JobParams.ContainsKey('Proxy'))
                                    {
                                        $FindModule_Params.Add('Proxy', $JobParams['Proxy'])
                                    }
                                    Remove-Variable -Name TempNugetResult -ErrorAction SilentlyContinue
                                    $private:TempNugetResult = Find-Module  @FindModule_Params -ErrorAction Stop

                                    #Map search results to MissingCommands
                                    if ($TempNugetResult)
                                    {
                                        foreach ($MissingCmd in $MissingCommandsAnalysis)
                                        {
                                            $MissingCmdModule = $TempNugetResult | Where-Object { $_.Includes.Command -contains $MissingCmd.CommandName }
                                            if ($MissingCmdModule)
                                            {
                                                $LocalCommandAnalysis[$MissingCmd.CommandName].CommandSource = $MissingCmdModule.Name -join ','
                                                $LocalCommandAnalysis[$MissingCmd.CommandName].CommandType = 'Command'
                                                $LocalCommandAnalysis[$MissingCmd.CommandName].SourceLocation = [PSBuild.CommandSourceLocation]::ProGet
                                                $LocalCommandAnalysis[$MissingCmd.CommandName].IsFound = $true
                                            }
                                        }
                                    }
                                }
                            }

                        }
                    }
                    catch
                    {
                        Write-Error "Resolve Missing commands against Proget failed. Details: $_" -ErrorAction Stop
                    }
                }

                #Check commands references
                try
                {
                    foreach ($Cmd in ($LocalCommandAnalysis | Where-Object { $_.IsFound }))
                    {
                        if ($JobParams['CurrentDependancies'] -contains $cmd.CommandSource)
                        {
                            $cmd.IsReferenced = $true
                        }
                    }
                }
                catch
                {
                    Write-Error "Check commands references failed. Details: $_" -ErrorAction Stop
                }

                #Update GlobalCommandAnalysis
                try
                {
                    $FoundCommandsAnalysis = $LocalCommandAnalysis | Where-Object { $_.IsFound -eq $true }
                    foreach ($FoundCmd in $FoundCommandsAnalysis)
                    {
                        if (-not $GlobalCommandAnalysis.Contains($FoundCmd.CommandName))
                        {
                            $null = $GlobalCommandAnalysis.Add($FoundCmd)
                        }
                    }
                }
                catch
                {
                    Write-Error "Update GlobalCommandAnalysis failed. Details: $_" -ErrorAction Stop
                }

                #Return result
                [pscustomobject]@{
                    LocalCommandAnalysisAsJson  = $LocalCommandAnalysis.ToJson()
                    GlobalCommandAnalysisAsJson = $GlobalCommandAnalysis.ToJson()
                }
            }
            $null = Wait-Job -Job $Job
            $JobResult = Receive-Job -Job $Job
        }
        finally
        {
            Remove-Job -Job $Job -Force
        }

        #Update CommandsToModuleMapping
        $null = [PSBuild.Context]::Current.CommandsToModuleMapping.TryAdd([PSBuild.CommandAnalysisCollection]::FromJson($JobResult.GlobalCommandAnalysisAsJson))

        [PSBuild.CommandAnalysisCollection]::FromJson($JobResult.LocalCommandAnalysisAsJson)
    }
}
#>

function priv_Test-Module
{
    [CmdletBinding()]
    [OutputType([PSBuild.PSModuleValidation])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $false)]
        [Version]$Version
    )
    
    Process
    {
        $TestPsModule_Params = @{
             ModulePath = $ModulePath
             ErrorAction = 'Stop'
        }
        if($PSBoundParameters.ContainsKey('Version')) { $TestPsModule_Params.Add('Version', $Version) }

        $testResult = Test-PSModule @TestPsModule_Params -Verbose:$false

        $wrappedResult = [PSBuild.PSModuleValidation]::new()
        $wrappedResult.ModuleInfo           = $testResult.ModuleInfo
        $wrappedResult.IsModule             = $testResult.IsModule
        $wrappedResult.IsVersionValid       = $testResult.IsVersionValid
        $wrappedResult.IsNewVersion         = $testResult.IsNewVersion
        $wrappedResult.SupportVersonControl = $testResult.SupportVersonControl
        $wrappedResult.IsReadyForPackaging  = $testResult.IsReadyForPackaging

        $wrappedResult
    }
}

function priv_Test-Script
{
    [CmdletBinding()]
    [OutputType([PSBuild.PSScriptValidation])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
		
        #UseScriptConfigFile
        [Parameter(Mandatory = $false)]
        [switch]$UseScriptConfigFile
    )
    
    Process
    {
        $TestPsScript_Params = @{
             ScriptPath = $ScriptPath
             UseScriptConfigFile = ($UseScriptConfigFile.IsPresent)
             ErrorAction = 'Stop'
        }

        $testResult = Test-PSScript @TestPsScript_Params -Verbose:$false

        $wrappedResult = [PSBuild.PSScriptValidation]::new(@{
            ScriptInfo           = $testResult.ScriptInfo
            ScriptConfig         = $testResult.ScriptConfig
            IsScript             = $testResult.IsScript
            IsVersionValid       = $testResult.IsVersionValid
            IsNewVersion         = $testResult.IsNewVersion
            SupportVersonControl = $testResult.SupportVersonControl
            IsReadyForPackaging  = $testResult.IsReadyForPackaging
            ValidationErrors     = $testResult.ValidationErrors
        })

        $wrappedResult
    }
}

function priv_Build-SolutionModulesCache
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSBuild.PSModuleBuildInfo[]]$BuildConfiguration,

        [Parameter(Mandatory = $false)]
        [switch]$Clear
    )
    
    Process
    {
        if($Clear)
        {
            [PSBuild.Context]::Current.SolutionModulesCache.Clear()
        }

        foreach ($ModBuildCfg in $BuildConfiguration)
        {
            $testResult = priv_Test-Module -ModulePath ($ModBuildCfg.SourcePath)
            if($testResult.IsModule)
            {
                $testResult.TargetDirectory = $ModBuildCfg.DestinationPath
                [PSBuild.Context]::Current.SolutionModulesCache.Update($testResult)
            }
            else
            {
                throw "Build Solution Module Cache failed. Unsupported operation: missing ModuleInfo for module $($ModBuildCfg.Name)."
            }
        }
    }
}

function priv_Build-SolutionScriptsCache
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSBuild.PSScriptBuildInfo[]]$BuildConfiguration,
		
        #UseScriptConfigFile
        [Parameter(Mandatory = $false)]
        [switch]$UseScriptConfigFile,

        [Parameter(Mandatory = $false)]
        [switch]$Clear
    )
    
    Process
    {
        if($Clear)
        {
            [PSBuild.Context]::Current.SolutionScriptsCache.Clear()
        }

        foreach ($ScrBuildCfg in $BuildConfiguration)
        {
            Write-Verbose -Message "[Build PSScript] Analyzing '$($ScrBuildCfg.Name)'"

            $TestScript_Params = @{
                    ScriptPath = ($ScrBuildCfg.SourcePath)
                    UseScriptConfigFile = ($UseScriptConfigFile.IsPresent)
            }

            $testResult = priv_Test-Script @TestScript_Params
            if($testResult.IsScript)
            {
                $testResult.TargetDirectory = $ScrBuildCfg.DestinationPath
                $testResult.RequiredModulesTargetDirectory = $ScrBuildCfg.RequiredModulesDestinationPath
                [PSBuild.Context]::Current.SolutionScriptsCache.Update($testResult)
            }
            else
            {
                $ErrorMsg = "Build Solution Scripts Cache failed."

                if($testResult.ValidationErrors)
                {
                    $ErrorMsg += [System.Environment]::NewLine
                    $ErrorMsg += "Validation Errors:"
                    $ErrorMsg += [System.Environment]::NewLine
                    $ErrorMsg += $testResult.ValidationErrors -join "$([System.Environment]::NewLine)"
                }
                else
                {
                    $ErrorMsg += " Unsupported operation: missing ScriptInfo for script $($ScrBuildCfg.FullName)."
                }

                throw $ErrorMsg
            }


        }
    }
}

function priv_Build-CommandsToModuleMapping
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $false)]
        [switch]$Clear
    )

    Process
    {
        if($Clear)
        {
            [PSBuild.Context]::Current.CommandsToModuleMapping.Clear()
        }

        # Validate Native Commands
        try
        {
            #Add BuiltIn Comands and Aliases to CommandsToModuleMapping (from module 'Microsoft.PowerShell.Core' as they are BuiltIn to PowerShell)
            foreach($psNativeModule in $PSNativeModules)
            {
                [PSModuleInfo]$psNativeModuleObj = Get-Module -Name $psNativeModule -ListAvailable -Verbose:$false -ErrorAction Stop | Select-Object -First 1

                if($psNativeModuleObj)
                {
                    [PSBuild.Context]::Current.ExternalModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($psNativeModuleObj.Name, $psNativeModuleObj.Version, $null, $psNativeModuleObj.Path))
                }
                else
                {
                    $psNativeSnapInObj = Get-PSSnapin -Name $psNativeModule -Verbose:$false -ErrorAction SilentlyContinue | Select-Object -First 1

                    if($psNativeSnapInObj)
                    {
                        [PSBuild.Context]::Current.ExternalModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($psNativeSnapInObj.Name, $psNativeSnapInObj.Version, $null, $null))
                    }
                    else
                    {
                        Write-Warning -Message "Module '$psNativeModule' is marked as a required native module but it could not be found."
                    }
                    $psNativeSnapInObj = $null
                }
                $psNativeModuleObj = $null
            }
            
            #This also imports the module in the current session
            Get-Command -Module $PSNativeModules | ForEach-Object {

                #Add Command
                $Command = [PSBuild.CommandSource]::new($_, [PSBuild.CommandSourceLocation]::BuiltIn)
                if ($Command.CommandType -eq 'Alias')
                {
                    try
                    {
                        $currentVerbosePref = $VerbosePreference
                        $VerbosePreference = "SilentlyContinue"

                        $TempFinding2 = Get-Command -Name $Command.CommandName -ErrorAction Stop
                        $Command.Source = $TempFinding2.Source

                        $VerbosePreference = $currentVerbosePref
                    }
                    catch
                    {
                    }
                }

                #Do not validate duplicates here
                $null = [PSBuild.Context]::Current.CommandsToModuleMapping.AddCommandSource($Command, $false)

                #Add Alias if exists
                Get-Alias -Definition $_.Name -ErrorAction SilentlyContinue | foreach {
                    $Alias = [PSBuild.CommandSource]::new($_, [PSBuild.CommandSourceLocation]::BuiltIn)
                    $Alias.Source = $Command.Source
                    $null = [PSBuild.Context]::Current.CommandsToModuleMapping.AddCommandSource($Alias, $false)
                }
            }
        }
        catch
        {
            Write-Error "Validate Native Commands failed. Details: $_" -ErrorAction 'Stop'
        }


        # Add Solution Commands to CommandsToModuleMapping (from all modules in the solution)
        foreach ($ModuleObj in [PSBuild.Context]::Current.SolutionModulesCache)
        {
            priv_Update-CommandsToModuleMapping -ModuleInfo ($ModuleObj.ModuleInfo) -CommandSourceLocation Solution
        }

        # Add External Dependency Commands to CommandsToModuleMapping
        foreach($ModuleObj in [PSBuild.Context]::Current.SolutionModulesCache)
        {
            foreach($RequiredModuleExt in $ModuleObj.GetExternalModuleDependencies())
            {
                if(-not ([PSBuild.Context]::Current.ExternalModulesCache.Contains($RequiredModuleExt.Name)))
                {
                    # Search default PS locations
                    $ResolvedExtModuleObj = $null
                    $ResolvedExtModuleObj = Get-Module -Name ($RequiredModuleExt.Name) -ListAvailable -Refresh -ErrorAction SilentlyContinue -Verbose:$false | Sort-Object -Property Version | Select-Object -Last 1

                    if($ResolvedExtModuleObj)
                    {
                        priv_Update-CommandsToModuleMapping -ModuleInfo $ResolvedExtModuleObj -CommandSourceLocation Unknown
                        [PSBuild.Context]::Current.ExternalModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($ResolvedExtModuleObj.Name, $ResolvedExtModuleObj.Version, $null, $ResolvedExtModuleObj.Path))
                    }
                    else
                    {
                        # Try resolve module by path
                        if(Test-Path -Path ($RequiredModuleExt.Path))
                        {
                            $ResolvedExtModuleObj = Get-Module -Name ($RequiredModuleExt.Path) -ListAvailable -Refresh -ErrorAction SilentlyContinue -Verbose:$false | Sort-Object -Property Version | Select-Object -Last 1
                        }

                        if($ResolvedExtModuleObj)
                        {
                            priv_Update-CommandsToModuleMapping -ModuleInfo $ResolvedExtModuleObj -CommandSourceLocation Unknown
                            $mbi = [PSBuild.PSModuleBuildInfo]::new($ResolvedExtModuleObj.Name, $ResolvedExtModuleObj.Version, $null, $ResolvedExtModuleObj.Path)                            
                            $mbi.IsPortableModule = $false
                            [PSBuild.Context]::Current.ExternalModulesCache.Add($mbi)
                        }
                        else
                        {
                            throw "Failed to resolve External Dependencies for Module '$ModuleObj'. Required module '$RequiredModuleExt' was not found."
                        }
                    }
                }
            }
        }


    }
}

function priv_Update-CommandsToModuleMapping
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSModuleInfo]$ModuleInfo,

        [Parameter(Mandatory = $false)]
        [PSBuild.CommandSourceLocation]$CommandSourceLocation = [PSBuild.CommandSourceLocation]::Unknown
    )

    Process
    {
        #Validate Module Commands
        try
        {
            foreach ($cmd in $ModuleInfo.ExportedCommands.Values)
            {
                $Command = [PSBuild.CommandSource]::new($cmd, $CommandSourceLocation)

                # The command already exists in the collection
                if([PSBuild.Context]::Current.CommandsToModuleMapping.Contains($Command.CommandName))
                {
                    if([PSBuild.Context]::Current.CommandsToModuleMapping[$Command.CommandName].ContainsSource($Command.Source))
                    {
                        # This module is already present in the collection
                    }
                    elseif (-not [PSBuild.Context]::Current.AllowDuplicateCommandsInCommandToModuleMapping)
                    {
                        throw "Command with name '$($Command.CommandName)' is present in multiple modules: $([PSBuild.Context]::Current.CommandsToModuleMapping[$Command.CommandName].CommandSources[0].Source), $($Command.Source)"
                    }
                    else
                    {
                        $null = [PSBuild.Context]::Current.CommandsToModuleMapping.AddCommandSource($Command)
                    }
                }
                # The command is new
                else
                {
                    $null = [PSBuild.Context]::Current.CommandsToModuleMapping.AddCommandSource($Command)
                }
            }
        }
        catch
        {
            Write-Error "Validate Module Commands failed. Details: $_" -ErrorAction 'Stop'
        }
    }
}

function priv_Save-RequiredNugetModules
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSBuild.RequiredModuleSpecs[]]$RequiredModules,

        #PSGetRepository
        [Parameter(Mandatory = $true)]
        [hashtable[]]$PSGetRepository,

        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )

    Process
    {
        ### FIND ITEMS (At this step the goal is to know which repository hosts the required module.)
        foreach($ReqModule in $RequiredModules)
        {
            if([PSBuild.Context]::Current.PsGetModuleValidationCache.Contains($ReqModule.Name, $ReqModule.Version))
            {
                # This may happen if you call the Build-PSModule function twice
                Write-Verbose -Message "[Build PSModule] Skipping module $ReqModule (already resolved)"

                ### NOTE: This updates the original object - therefore the caller function will see the updates !!!
                $ReqModule.SourceInformation = [PSBuild.Context]::Current.PsGetModuleValidationCache.Find({param($mvc) process{($mvc.Name -eq $ReqModule.Name) -and ($mvc.Version -eq $ReqModule.Version)}})
            }
            else
            {
                $tempCollection = [PSBuild.PSRepositoryItemValidationCollection]::new()
                foreach($Repo in $PSGetRepository)
                {
                    $PSGet_Params = @{
                        Name       = ($ReqModule.Name)
                        Repository = ($Repo.Name)
                    }
                    if (-not ([PSBuild.Context]::Current.UpdateModuleReferences)) { $PSGet_Params.Add('RequiredVersion', $ReqModule.Version) }
                    if ($Repo.ContainsKey('Credential'))          { $PSGet_Params.Add('Credential', $Repo.Credential) }
                    if ($PSBoundParameters.ContainsKey('Proxy'))  { $PSGet_Params.Add('Proxy', $Proxy) }

                    try
                    {
                        $PSRepoItem = Find-Module @PSGet_Params -ErrorAction Stop -Verbose:$false
                        if($PSRepoItem)
                        {
                            $tempCollection.Add([PSBuild.PSRepositoryItemValidation]::new(@{
                                Dependencies = $PSRepoItem.Dependencies
                                Includes     = $PSRepoItem.Includes
                                Name         = $PSRepoItem.Name
                                Repository   = $PSRepoItem.Repository
                                Type         = $PSRepoItem.Type
                                Version      = $PSRepoItem.Version
                                PackageManagementProvider = $PSRepoItem.PackageManagementProvider
                                RepositorySourceLocation  = $PSRepoItem.RepositorySourceLocation
                                Priority     = $Repo.Priority
                                Credential   = $Repo.Credential
                            }))

                            Write-Verbose -Message "[Build PSModule] Module $ReqModule found in repository $($Repo.Name)"
                        }
                    }
                    catch
                    {
                        # Module not found in repo
                    }
                }

                if($tempCollection.Count -eq 0)
                {
                    Write-Warning -Message "Module $ReqModule was not found in registered repositories. The build process may still succeed if the module was previously built in the same destination folder."
                }
                elseif($tempCollection.Count -eq 1)
                {
                    ### NOTE: This updates the original object - therefore the caller function will see the updates !!!
                    $ReqModule.SourceInformation = $tempCollection[0]
                    [PSBuild.Context]::Current.PsGetModuleValidationCache.Add($ReqModule.SourceInformation)
                }
                else
                {
                    # If a module version is found in multiple repositories, use only the repo with higher priority

                    ### NOTE: This updates the original object - therefore the caller function will see the updates !!!
                    $ReqModule.SourceInformation = $($tempCollection | Sort-Object -Property Priority | Select-Object -First 1)
                    [PSBuild.Context]::Current.PsGetModuleValidationCache.Add($ReqModule.SourceInformation)
                }

                $tempCollection = $null
            }
        }


        ## SAVE ITEMS
        Write-Verbose -Message "[Build PSModule] Downloading modules from repositories..."
        foreach($ReqModule in $RequiredModules)
        {
            if(-not [IO.Directory]::Exists($ReqModule.TargetDirectory)) { $null = [IO.Directory]::CreateDirectory($ReqModule.TargetDirectory) }

            $TargetBuildPath = [IO.Path]::Combine($ReqModule.TargetDirectory, ($ReqModule.SourceInformation.Name))
            $ExistingModuleTest = $null

            $ExistingModuleTest = priv_Test-Module -ModulePath $TargetBuildPath -Version ($ReqModule.SourceInformation.Version)

            if($ExistingModuleTest.IsModule -and (( -not ($ExistingModuleTest.SupportVersonControl)) -or ($ExistingModuleTest.IsVersionValid)))
            {
                Write-Verbose -Message "[Build PSModule] Skipping module $ExistingModuleTest - a valid version already exists at target location."
                [PSBuild.Context]::Current.BuiltModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($ExistingModuleTest.ModuleName, $ExistingModuleTest.ModuleInfo.Version, $null, $ReqModule.TargetDirectory))
                priv_Update-CommandsToModuleMapping -ModuleInfo ($ExistingModuleTest.ModuleInfo) -CommandSourceLocation ProGet
            }
            elseif($ReqModule.SourceInformation)
            {
                Write-Verbose -Message "[Build PSModule] Downloading $($ReqModule.SourceInformation) (Repository: $($ReqModule.SourceInformation.Repository))"

                $SaveModule_Params = @{
                    Name            = $ReqModule.SourceInformation.Name
                    Repository      = $ReqModule.SourceInformation.Repository
                    RequiredVersion = $ReqModule.SourceInformation.Version
                    Path            = $ReqModule.TargetDirectory
                    ErrorAction     = 'Stop'
                    Verbose         = $false
                }
                if ($ReqModule.SourceInformation.Credential) { $SaveModule_Params.Add('Credential', $ReqModule.SourceInformation.Credential) }
                if ($PSBoundParameters.ContainsKey('Proxy')) { $SaveModule_Params.Add('Proxy', $Proxy) }

                Save-Module @SaveModule_Params

                $ExistingModuleTest = priv_Test-Module -ModulePath $TargetBuildPath -Version ($ReqModule.SourceInformation.Version) -Verbose:$false

                if($ExistingModuleTest.IsModule)
                {
                    if($ExistingModuleTest.SupportVersonControl -and ( -not ($ExistingModuleTest.IsVersionValid)))
                    {
                        # There is not much we can do for modules that are downloaded from repos. Show a warning and hope for the best :)
                        Write-Warning -Message "$ExistingModuleTest was successfully downloaded but it was detected that there are inconsistencies with the module's version control. Make sure the module is valid."
                    }

                    [PSBuild.Context]::Current.BuiltModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($ExistingModuleTest.ModuleName, $ExistingModuleTest.ModuleInfo.Version, $null, $ReqModule.TargetDirectory))
                    priv_Update-CommandsToModuleMapping -ModuleInfo ($ExistingModuleTest.ModuleInfo) -CommandSourceLocation ProGet
                }
                else
                {
                    throw "The module $ExistingModuleTest downloaded from $($ReqModule.SourceInformation.Repository) failed module validations."
                }
            }
            else
            {
                throw "The solution requires external module $ReqModule but it was not found in any repository."
            }
        }
    }
}

#endregion

#region Public Functions


function Build-PSModule
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SourcePath
        [Parameter(Mandatory = $true, ParameterSetName = 'BySourceAndDestinationPaths')]
        [System.IO.DirectoryInfo[]]$SourcePath,

        #DestinationPath
        [Parameter(Mandatory = $true, ParameterSetName = 'BySourceAndDestinationPaths')]
        [System.IO.DirectoryInfo]$DestinationPath,

        #ModulePathConfiguration
        [Parameter(Mandatory = $true, ParameterSetName = 'ByModulePathConfiguration')]
        [PSBuild.PSModuleBuildInfo[]]$ModulePathConfiguration,

        #ResolveDependancies
        [Parameter(Mandatory = $false)]
        [switch]$ResolveDependancies,

        #CheckCommandReferencesConfiguration
        [Parameter(Mandatory = $false)]
        [PSBuild.CheckCommandReferencesConfiguration]$CheckCommandReferencesConfiguration,

        #CheckDuplicateCommandNames
        [Parameter(Mandatory = $false)]
        [switch]$CheckDuplicateCommandNames,

        #UpdateModuleReferences
        [Parameter(Mandatory = $false)]
        [switch]$UpdateModuleReferences,

        #PSGetRepository
        [Parameter(Mandatory = $false)]
        [hashtable[]]$PSGetRepository,

        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )

    Process
    {
        ### PART 1: Prerequisites
        Write-Verbose -Message "[Build PSModule] Preparing Prerequisites..."

        $ModuleBuildCfg = [PSBuild.PSModuleBuildInfoCollection]::new()
        $ModuleDestinationList = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

        if($PsCmdlet.ParameterSetName -eq 'BySourceAndDestinationPaths')
        {
            foreach($srcPath in $SourcePath)
            {
                $ModuleBuildCfg.Add([PSBuild.PSModuleBuildInfo]::new(
                    $srcPath.Name,
                    $null,
                    $srcPath.FullName,
                    $DestinationPath.FullName
                ))
            }
            $null = $ModuleDestinationList.Add($DestinationPath.FullName)
        }
        else
        {
            foreach($modPathCfg in $ModulePathConfiguration)
            {
                $ModuleBuildCfg.Add($modPathCfg)
                $null = $ModuleDestinationList.Add($modPathCfg.DestinationPath)
            }
        }

        # Update PSModulePath environmental variable
        Add-PSModulePathEntry -Path $ModuleDestinationList -Scope Process -Force

        # Assert PSRepositories
        if ($PSBoundParameters.ContainsKey('PSGetRepository'))
        {
            $AssertPSRepository_Params = @{ PSGetRepository = $PSGetRepository }
            if ($PSBoundParameters.ContainsKey('Proxy')) { $AssertPSRepository_Params.Add('Proxy', $Proxy) }
            Assert-PSRepository @AssertPSRepository_Params -ErrorAction Stop
        }

        # Update Command References Config
        if($PSBoundParameters.ContainsKey('CheckDuplicateCommandNames'))
        {
            [PSBuild.Context]::Current.AllowDuplicateCommandsInCommandToModuleMapping = (-not ($CheckDuplicateCommandNames.IsPresent))
        }

        # Update Module References Config
        if($PSBoundParameters.ContainsKey('UpdateModuleReferences'))
        {
            [PSBuild.Context]::Current.UpdateModuleReferences = ($UpdateModuleReferences.IsPresent)
        }
        
        # Update Command References Config
        if($PSBoundParameters.ContainsKey('CheckCommandReferencesConfiguration'))
        {
            [PSBuild.Context]::Current.CheckCommandReferencesConfiguration = $CheckCommandReferencesConfiguration
        }
        

        ### PART 2: Build Cache Data

        #Validate All Modules
        priv_Build-SolutionModulesCache -BuildConfiguration $ModuleBuildCfg

        priv_Build-CommandsToModuleMapping


        ### PART 3: Analyze modules in bulk and find all required modules that are not part of this solution.
        Write-Verbose -Message "[Build PSModule] Analyzing Module Dependencies..."
        $SolutionPSGetDependencies = [PSBuild.RequiredModuleSpecsCollection]::new()
        foreach($ModuleObj in [PSBuild.Context]::Current.SolutionModulesCache)
        {
            $SolutionPSGetDependencies.AddRange($ModuleObj.GetRequiredModules([PSBuild.RequiredModulesFilterOption]::RemoveExternalDependenciesAndKnownSolutionItems))
        }

        if($SolutionPSGetDependencies.Count -gt 0)
        {
            if([PSBuild.Context]::Current.UpdateModuleReferences)
            {
                $SolutionPSGetDependencies = $SolutionPSGetDependencies.GetLatestModuleVersions()
            }
            else
            {
                $SolutionPSGetDependencies = $SolutionPSGetDependencies.GetUniqueModuleVersions()
            }

            Write-Verbose -Message "[Build PSModule] Detected $($SolutionPSGetDependencies.Count) required modules outside solution. Searching Repositories..."

            if (!$PSBoundParameters.ContainsKey('PSGetRepository'))
            {
                throw "Cannot resolve dependencies. It appears that some modules are not part of the solution but there were no specified search repositories from which to download them."
            }

            $SaveRequiredModules_Params = @{
                RequiredModules = $SolutionPSGetDependencies
                PSGetRepository = $PSGetRepository
            }
            if ($PSBoundParameters.ContainsKey('Proxy')) { $SaveRequiredModules_Params.Add('Proxy', $Proxy) }
            priv_Save-RequiredNugetModules @SaveRequiredModules_Params
        }
        

        ### PART 4: Build Local Modules. The processing order ensures dependencies are built first.
        Write-Verbose -Message "[Build PSModule] Building Local Solution Modules..."
        foreach ($ModuleObj in [PSBuild.Context]::Current.SolutionModulesCache.GetOrderedProcessingList())
        {
			if($ModuleObj.PreferredProcessingOrder -gt 1000)
			{
				throw "Detected cyclic dependency at module $ModuleObj."			
			}

            # PART 4-a: Analyze Required Modules
            # This time we expect that all required modules have already been downloaded from repos or built in advance
            # If a required module is not at the target build location, there is an unresolvable dependency and the process stops.
            Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> Validating Dependencies"
            foreach($requiredModule in $ModuleObj.GetRequiredModules([PSBuild.RequiredModulesFilterOption]::RemoveExternalDependencies))
            {
                if([PSBuild.Context]::Current.BuiltModulesCache.Contains(@{ Name=$requiredModule.Name; DestinationPath=$requiredModule.TargetDirectory }))
                {
                    # Already built
                    # At this point the built module may be the same version or newer
                }
                else
                {
                    $TargetBuildPath = [IO.Path]::Combine($requiredModule.TargetDirectory, $requiredModule.Name)
                    $ExistingModuleTest = $null
                    $ExistingModuleTest = priv_Test-Module -ModulePath $TargetBuildPath
                    
                    if($ExistingModuleTest.IsModule -and ($ExistingModuleTest.ModuleInfo.Version -ge $requiredModule.Version))
                    {
                        if($ExistingModuleTest.SupportVersonControl -and (-not ($ExistingModuleTest.IsVersionValid)))
                        {
                            # The same warning as in Step 2. Assumption is it was manually placed there or built in another process, so show the warning again:
                            Write-Warning -Message "$ExistingModuleTest was found in the target build location but it was detected that there are inconsistencies with the module's version control. Make sure the module is valid."
                        }

                        [PSBuild.Context]::Current.BuiltModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($ExistingModuleTest.ModuleName, $ExistingModuleTest.ModuleInfo.Version, $null, $requiredModule.TargetDirectory))
                    }
                    elseif([PSBuild.Context]::Current.SolutionModulesCache.Contains($requiredModule.Name))
                    {
                        # This is usually caused by a circular dependency. The Solution Modules are processed in order which ensures all required modules are built in advance.
                        # If this module is missing, the dependency tree is invalid
                        throw "Build module $ModuleObj failed. Cannot resolve module dependencies. The required module $requiredModule was not found in the build directory. This problem may be caused by a circular dependency."
                    }
                    else
                    {
                        # Note that this is a required module, not found in the solution and not found in the ps repos.
                        # This was a best effort attempt to find it in the build directory and use it.
                        throw "Build module $ModuleObj failed. Cannot resolve module dependencies. The required module $requiredModule is not part of the solution and was not found in any of the provided repositories."
                    }
                }
            }


            # PART 4-b: Update Required Modules versions in the Module Manifest
            Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> Validating Required Module Versions"
            $ModuleDependanciesDefinition = New-Object -TypeName System.Collections.ArrayList
            $UpdateModuleManifestRequired = $false
            foreach($requiredModule in $ModuleObj.ModuleInfo.RequiredModules)
            {
                $shouldUpdateVersion = $false
                $latestVersion = $null
                $reqModuleName = $requiredModule.Name

                if([PSBuild.Context]::Current.BuiltModulesCache.Contains($requiredModule.Name))
                {
                    $latestVersion = [PSBuild.Context]::Current.BuiltModulesCache.GetLatestVersion($requiredModule.Name)

                    if(($requiredModule.Version -lt $latestVersion.Version) -and ([PSBuild.Context]::Current.UpdateModuleReferences -or [PSBuild.Context]::Current.SolutionModulesCache.Contains($requiredModule.Name)))
                    {
                        $shouldUpdateVersion = $true
                    }
                }
                elseif([PSBuild.Context]::Current.ExternalModulesCache.Contains($requiredModule.Name))
                {
                    $latestVersion = [PSBuild.Context]::Current.ExternalModulesCache.GetLatestVersion($requiredModule.Name)

                    if($requiredModule.Version -lt $latestVersion.Version)
                    {
                        Write-Warning -Message "Module $ModuleObj depends on $requiredModule which is not part of this solution. $($requiredModule.Name) has a newer version ($($latestVersion.Version)) and the required module reference will be updated."
                        $shouldUpdateVersion = $true
                    }

                    if(-not ($latestVersion.IsPortableModule))
                    {
                        $reqModuleName = $latestVersion.DestinationPath
                    }
                }
                else
                {
                    throw "Required module $($requiredModule.Name) was not found in either the Built Modules Cache or the External Modules Cache. This should not be possible but you still did it! Congrats!"
                }
                

                if($shouldUpdateVersion)
                {
                    $null = $ModuleDependanciesDefinition.Add([Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                        ModuleName    = $reqModuleName
                        ModuleVersion = $latestVersion.Version
                    }))
                    Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> Required Module '$($requiredModule.Name)/$($requiredModule.Version)' has a newer version ($($latestVersion.Version))"
                    $UpdateModuleManifestRequired = $true
                }
                else
                {
                    $null = $ModuleDependanciesDefinition.Add([Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                        ModuleName    = $reqModuleName
                        ModuleVersion = $requiredModule.Version
                    }))
                }
            }

            if ($UpdateModuleManifestRequired)
            {
                Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> Updating Module Manifest"

                $currentVerbosePreference = $VerbosePreference
                $VerbosePreference = 'SilentlyContinue'

                Update-ModuleManifest -Path ($ModuleObj.ModuleInfo.Path) -RequiredModules $ModuleDependanciesDefinition -ErrorAction Stop -Verbose:$false

                $VerbosePreference = $currentVerbosePreference
            }


            ### PART 4-c: Check if all commands are referenced
            if([PSBuild.Context]::Current.CheckCommandReferencesConfiguration.Enabled)
            {
                # Update Module Definition. This is required in order to extract all commands used inside the module
                # Note that this is required independent of the fact that the module may be in the exclusion list because there may be another module which depends on this module and its validations will fail
                Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> Reading Module AST"
                $modDefiniton = priv_Get-ModuleDefinition -ModulePath ($ModuleObj.SourceDirectory) -DestinationPath $ModuleDestinationList -ProactiveRequiredModuleLoading ($ModuleObj.PreferredProcessingOrder -gt 2)
                $ModuleObj.UpdateModuleDefinitionAst($modDefiniton)

                if([PSBuild.Context]::Current.CheckCommandReferencesConfiguration.ExcludedSources -notcontains ($ModuleObj.ModuleName))
                {
                    Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> Checking if all commands are referenced"
                    foreach($NonLocalCommand in $ModuleObj.GetNonLocalCommands())
                    {
                        if([PSBuild.Context]::Current.CheckCommandReferencesConfiguration.ExcludedCommands -notcontains $NonLocalCommand)
                        {
                            if([PSBuild.Context]::Current.CommandsToModuleMapping.ContainsCommand($NonLocalCommand))  
                            {
                                $cmdIsReferenced = $false
                                foreach($cmdSrc in ([PSBuild.Context]::Current.CommandsToModuleMapping.GetCommandSources($NonLocalCommand)))
                                {
                                    if(($cmdSrc.SourceLocation -eq [PSBuild.CommandSourceLocation]::BuiltIn) -or 
                                       ($ModuleObj.GetRequiredModules([PSBuild.RequiredModulesFilterOption]::FindAll).Name -contains $cmdSrc.Source))
                                    {
                                        # Module is either BuiltIn or explicitly referenced
                                        $cmdIsReferenced = $true
                                        break
                                    }
                                }

                                if(-not $cmdIsReferenced)
                                {
                                    if([PSBuild.Context]::Current.CommandsToModuleMapping.GetCommandSources($NonLocalCommand).Count -gt 1)
                                    {
                                        throw "Build Module '$ModuleObj' failed. The command '$NonLocalCommand' was found in modules $(@([PSBuild.Context]::Current.CommandsToModuleMapping.GetCommandSources($NonLocalCommand).ForEach{ "'$($_.Source)'" }) -join ', ') but neither is referenced in the module manifest."
                                    }
                                    else
                                    {
                                        throw "Build Module '$ModuleObj' failed. The command '$NonLocalCommand' was found in module '$([PSBuild.Context]::Current.CommandsToModuleMapping.GetCommandSources($NonLocalCommand)[0].Source)' but it is not referenced in the module manifest."
                                    }
                                }
                            }
                            else
                            {
                                throw "Build Module '$ModuleObj' failed. The command '$NonLocalCommand' was not found in any of the required modules referenced in the module manifest."
                            }
                        }
                    }
                }
            }


            ### PART 4-d: Check Module Integrity
            if (-not $ModuleObj.IsReadyForPackaging)
            {
                throw "Build Module '$ModuleObj' failed. The module is not ready for packaging. Missing either Author or Description."
            }

            if (-not $ModuleObj.IsValid)
            {
                ## NOTE: This also updates the file hash
                Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> Updating Module Version"

                $currentVerbosePreference = $VerbosePreference
                $VerbosePreference = 'SilentlyContinue'

                $oldModuleVer = $ModuleObj.ModuleInfo.Version
                Update-PSModuleVersion -ModulePath ($ModuleObj.SourceDirectory) -ErrorAction Stop -Verbose:$false
						
                #Refresh ModuleValidation
                $ModuleObj.Update($(priv_Test-Module -ModulePath ($ModuleObj.SourceDirectory) -ErrorAction Stop))
                Write-Warning -Message "[Build PSModule] Processing $ModuleObj -> Updated module from version $($oldModuleVer) to version $($ModuleObj.ModuleInfo.Version)"

                $VerbosePreference = $currentVerbosePreference
            }


            ### PART 4-e: Export Module to DestinationPath
            Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> Exporting Module"

            try
            {
                priv_Export-Artifact -Type Module -SourcePath ($ModuleObj.SourceDirectory) -Version ($ModuleObj.ModuleInfo.Version) -DestinationPath ($ModuleObj.TargetDirectory) -Verbose:$false
                [PSBuild.Context]::Current.BuiltModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($ModuleObj.ModuleName, $ModuleObj.ModuleInfo.Version, $ModuleObj.SourceDirectory, $ModuleObj.TargetDirectory))
            }
            catch
            {
                throw "Build Module '$ModuleObj' failed. Cannot copy module to '$DestinationPath'. details: $_"
            }

            Write-Verbose -Message "[Build PSModule] Processing $ModuleObj -> DONE"
        }
    }
}

function Build-PSScript
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SourcePath
        [Parameter(Mandatory = $true, ParameterSetName = 'BySourceAndDestinationPaths')]
        [System.IO.FileInfo[]]$SourcePath,

        #DestinationPath
        [Parameter(Mandatory = $false, ParameterSetName = 'BySourceAndDestinationPaths')]
        [System.IO.DirectoryInfo]$DestinationPath,

        #DependencyDestinationPath
        [Parameter(Mandatory = $false, ParameterSetName = 'BySourceAndDestinationPaths')]
        [System.IO.DirectoryInfo]$DependencyDestinationPath,

        #ModulePathConfiguration
        [Parameter(Mandatory = $true, ParameterSetName = 'ByModulePathConfiguration')]
        [PSBuild.PSScriptBuildInfo[]]$ScriptPathConfiguration,

        #UseScriptConfigFile
        [Parameter(Mandatory = $false)]
        [switch]$UseScriptConfigFile,

        #ResolveDependancies
        [Parameter(Mandatory = $false)]
        [switch]$ResolveDependancies,

        #CheckCommandReferencesConfiguration
        [Parameter(Mandatory = $false)]
        [PSBuild.CheckCommandReferencesConfiguration]$CheckCommandReferencesConfiguration,

        #UpdateModuleReferences
        [Parameter(Mandatory = $false)]
        [switch]$UpdateModuleReferences,

        #PSGetRepository
        [Parameter(Mandatory = $false)]
        [hashtable[]]$PSGetRepository,

        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )
    
    Process
    {
        ### PART 1: Prerequisites
        Write-Verbose -Message "[Build PSScript] Preparing Prerequisites..."

        $ScriptBuildCfg = [PSBuild.PSScriptBuildInfoCollection]::new()
        $ModuleDestinationList = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

        if($PsCmdlet.ParameterSetName -eq 'BySourceAndDestinationPaths')
        {
            if(($ResolveDependancies.IsPresent) -and [String]::IsNullOrEmpty($DestinationPath.FullName) -and [String]::IsNullOrEmpty($DependencyDestinationPath.FullName))
            {
                throw "Build Solution Scripts failed. The Solution Configuration is invalid. ScriptPath requires you to specify at least one of the following properties: BuildPath, DependencyDestinationPath."
            }

            foreach($srcPath in $SourcePath)
            {
                $ScriptBuildCfg.Add([PSBuild.PSScriptBuildInfo]::new(@{
                    Name                           = $srcPath.Name
                    SourcePath                     = $srcPath.FullName
                    DestinationPath                = $DestinationPath.FullName
                    RequiredModulesDestinationPath = $(if($DependencyDestinationPath.FullName) {$DependencyDestinationPath.FullName} else {$DestinationPath.FullName})
                }))
            }

            if($DestinationPath.FullName) { $null = $ModuleDestinationList.Add($DestinationPath.FullName) }
            if($DependencyDestinationPath.FullName) { $null = $ModuleDestinationList.Add($DependencyDestinationPath.FullName) }
        }
        else
        {
            foreach($scrPathCfg in $ScriptPathConfiguration)
            {
                $ScriptBuildCfg.Add($scrPathCfg)
                if($scrPathCfg.DestinationPath) { $null = $ModuleDestinationList.Add($scrPathCfg.DestinationPath) }
                if($scrPathCfg.RequiredModulesDestinationPath) { $null = $ModuleDestinationList.Add($scrPathCfg.RequiredModulesDestinationPath) }
            }
        }

        # Update PSModulePath environmental variable
        if($ResolveDependancies.IsPresent)
        {
            Add-PSModulePathEntry -Path $ModuleDestinationList -Scope Process -Force
        }

        # Assert PSRepositories
        if ($PSBoundParameters.ContainsKey('PSGetRepository'))
        {
            $AssertPSRepository_Params = @{ PSGetRepository = $PSGetRepository }
            if ($PSBoundParameters.ContainsKey('Proxy')) { $AssertPSRepository_Params.Add('Proxy', $Proxy) }
            Assert-PSRepository @AssertPSRepository_Params -ErrorAction Stop
        }

        # Update Command References Config
        if($PSBoundParameters.ContainsKey('CheckDuplicateCommandNames'))
        {
            [PSBuild.Context]::Current.AllowDuplicateCommandsInCommandToModuleMapping = (-not ($CheckDuplicateCommandNames.IsPresent))
        }

        # Update Module References Config
        if($PSBoundParameters.ContainsKey('UpdateModuleReferences'))
        {
            [PSBuild.Context]::Current.UpdateModuleReferences = ($UpdateModuleReferences.IsPresent)
        }
        
        # Update Command References Config
        if($PSBoundParameters.ContainsKey('CheckCommandReferencesConfiguration'))
        {
            [PSBuild.Context]::Current.CheckCommandReferencesConfiguration = $CheckCommandReferencesConfiguration
        }
        

        ### PART 2: Build Cache Data
        Write-Verbose -Message "[Build PSScript] Building Solution Scripts Cache..."
        priv_Build-SolutionScriptsCache -BuildConfiguration $ScriptBuildCfg -UseScriptConfigFile:($UseScriptConfigFile.IsPresent)


        ### PART 3: Analyze Dependencies
        Write-Verbose -Message "[Build PSScript] Analyzing Dependencies..."

        $SolutionPSGetDependencies = [PSBuild.RequiredModuleSpecsCollection]::new()
        $ExternalModuleDependencies = [PSBuild.RequiredModuleSpecsCollection]::new()

        foreach($ScriptObj in [PSBuild.Context]::Current.SolutionScriptsCache)
        {
            $allScrReqModules =  @(if($UseScriptConfigFile.IsPresent) { $ScriptObj.ScriptConfig.RequiredModules } else { $ScriptObj.ScriptInfo.RequiredModules })
            
            foreach($reqModule in $allScrReqModules)
            {
                # At this point the required module object is the correct type but it hasn't been populated with the correct target directory yet
                $reqModule.TargetDirectory = $ScriptObj.RequiredModulesTargetDirectory

                if([PSBuild.Context]::Current.SolutionModulesCache.Contains($reqModule.Name))
                {
                    if([PSBuild.Context]::Current.BuiltModulesCache.Contains($reqModule.Name))
                    {
                        # If object is in the Built Modules Cache, it has been built in the previous step, so just skip it to save time
                        # Note: here we demand that it is built in the CORRECT directory
                        if([PSBuild.Context]::Current.BuiltModulesCache.Contains(@{ Name=$reqModule.Name; DestinationPath=$reqModule.TargetDirectory }))
                        {
                            Write-Verbose -Message "[Build PSScript] Analyzing '$($ScriptObj.Name)' -> Skipping required module '$reqModule' because it has already been built."
                        }
                        else
                        {
                            # This module has definitely been built previously because it is in the Solution Modules Cache
                            # The module, however, is not at the required Target Directory which is a problem with the Solution Configuration and not the build process
                            # Throw error here and demand that Build-PSModule uses the same target dir as required for the scripts
                            throw "Build PSScript Failed. The script '$ScriptObj' requires module '$($reqModule.Name)' which appears to be built in an incorrect location. Make sure to build solution modules in the correct destination directory. The Script Dependencies folder is '$($reqModule.TargetDirectory)'."
                        }
                    }
                    else
                    {
                        throw "Build PSScript Failed. The script '$ScriptObj' requires module '$($reqModule.Name)' which appears to be part of the solution but for some reason it is not built yet. This is an unsupported scenario. All required modules should be built in advance using the Build-PSModule command."
                    }
                }
                elseif($ScriptObj.ScriptInfo.ExternalModuleDependencies -contains $reqModule.Name)
                {
                    $ExternalModuleDependencies.Add($reqModule)
                }
                else
                {
                    $SolutionPSGetDependencies.Add($reqModule)
                }
            }
        }

        $ExternalModuleDependencies = $ExternalModuleDependencies.GetLatestModuleVersions() # Always use latest external modules
        $SolutionPSGetDependencies = if([PSBuild.Context]::Current.UpdateModuleReferences) { $SolutionPSGetDependencies.GetLatestModuleVersions() } else { $SolutionPSGetDependencies.GetUniqueModuleVersions() }

        # Download Nuget Modules
        if($SolutionPSGetDependencies.Count -gt 0)
        {
            Write-Verbose -Message "[Build PSScript] Detected $($SolutionPSGetDependencies.Count) required modules outside solution. Searching Repositories..."

            if (!$PSBoundParameters.ContainsKey('PSGetRepository'))
            {
                throw "Cannot resolve dependencies. It appears that some modules are not part of the solution but there were no specified search repositories from which to download them."
            }

            $SaveRequiredModules_Params = @{
                RequiredModules = $SolutionPSGetDependencies
                PSGetRepository = $PSGetRepository
            }
            if ($PSBoundParameters.ContainsKey('Proxy')) { $SaveRequiredModules_Params.Add('Proxy', $Proxy) }
            priv_Save-RequiredNugetModules @SaveRequiredModules_Params
        }

        # Check External Dependencies
        # Here we are only listing the exported commands, which will be used during the Command Analysis phase later. Nothing to build.
        if($ExternalModuleDependencies.Count -gt 0)
        {
            foreach($RequiredModuleExt in $ExternalModuleDependencies)
            {
                if(-not [PSBuild.Context]::Current.ExternalModulesCache.Contains($RequiredModuleExt.Name))
                {
                    # Search default PS locations
                    $ResolvedExtModuleObj = $null
                    $ResolvedExtModuleObj = Get-Module -Name ($RequiredModuleExt.Name) -ListAvailable -Refresh -ErrorAction SilentlyContinue -Verbose:$false | Sort-Object -Property Version | Select-Object -Last 1

                    if($ResolvedExtModuleObj)
                    {
                        priv_Update-CommandsToModuleMapping -ModuleInfo $ResolvedExtModuleObj -CommandSourceLocation Unknown
                        [PSBuild.Context]::Current.ExternalModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($ResolvedExtModuleObj.Name, $ResolvedExtModuleObj.Version, $null, $ResolvedExtModuleObj.Path))
                    }
                    else
                    {
                        # Try resolve module by path
                        if(Test-Path -Path ($RequiredModuleExt.Path))
                        {
                            $ResolvedExtModuleObj = Get-Module -Name ($RequiredModuleExt.Path) -ListAvailable -Refresh -ErrorAction SilentlyContinue -Verbose:$false | Sort-Object -Property Version | Select-Object -Last 1
                        }

                        if($ResolvedExtModuleObj)
                        {
                            priv_Update-CommandsToModuleMapping -ModuleInfo $ResolvedExtModuleObj -CommandSourceLocation Unknown
                            [PSBuild.Context]::Current.ExternalModulesCache.Add([PSBuild.PSModuleBuildInfo]::new($ResolvedExtModuleObj.Name, $ResolvedExtModuleObj.Version, $null, $ResolvedExtModuleObj.Path))
                        }
                        else
                        {
                            throw "Failed to resolve External Script Dependencies. Required module '$RequiredModuleExt' was not found."
                        }
                    }
                }
            }
        }


        ### PART 4: BUILD SCRIPT
        Write-Verbose -Message "[Build PSScript] Building Scripts..."
        foreach($ScriptObj in [PSBuild.Context]::Current.SolutionScriptsCache)
        {
            # PART 4-a: Update Required Module versions in the Script Manifest
            Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> Validating Required Module Versions"
            $ModuleDependanciesDefinition = New-Object -TypeName System.Collections.ArrayList
            $UpdateScriptInfoRequired = $false
            foreach($requiredModule in $ScriptObj.ScriptInfo.RequiredModules)
            {
                $shouldUpdateVersion = $false
                $latestVersion = $null
                $reqModuleName = $requiredModule.Name

                if([PSBuild.Context]::Current.BuiltModulesCache.Contains($requiredModule.Name))
                {
                    $latestVersion = [PSBuild.Context]::Current.BuiltModulesCache.GetLatestVersion($requiredModule.Name)

                    if(($requiredModule.Version -lt $latestVersion.Version) -and ([PSBuild.Context]::Current.UpdateModuleReferences -or [PSBuild.Context]::Current.SolutionModulesCache.Contains($requiredModule.Name)))
                    {
                        $shouldUpdateVersion = $true
                    }
                }
                elseif([PSBuild.Context]::Current.ExternalModulesCache.Contains($requiredModule.Name))
                {
                    $latestVersion = [PSBuild.Context]::Current.ExternalModulesCache.GetLatestVersion($requiredModule.Name)

                    if(-not ($latestVersion.IsPortableModule))
                    {
                        $reqModuleName = $latestVersion.DestinationPath
                    }

                    if($requiredModule.Version -lt $latestVersion.Version)
                    {
                        Write-Warning -Message "Script $ScriptObj depends on $requiredModule which is not part of this solution. $($requiredModule.Name) has a newer version ($($latestVersion.Version)) and the required modules reference will be updated."
                        $shouldUpdateVersion = $true
                    }
                }
                else
                {
                    throw "Required module $($requiredModule.Name) was not found in either the Built Modules Cache or the External Modules Cache. This should not be possible but you still did it! Congrats!"
                }
                
                if($shouldUpdateVersion)
                {
                    $null = $ModuleDependanciesDefinition.Add([Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                        ModuleName    = $reqModuleName
                        ModuleVersion = $latestVersion.Version
                    }))
                    Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> Required Module '$($requiredModule.Name)/$($requiredModule.Version)' has a newer version ($($latestVersion.Version))"
                    $UpdateScriptInfoRequired = $true
                }
                else
                {
                    $null = $ModuleDependanciesDefinition.Add([Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                        ModuleName    = $reqModuleName
                        ModuleVersion = $requiredModule.Version
                    }))
                }
            }

            if ($UpdateScriptInfoRequired)
            {
                if ($UseScriptConfigFile.IsPresent)
                {
                    Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> Updating Script Configuration"
    
                    # Config File Format
                    $cfg = [PSCustomObject]@{
                        RequiredModules = @($ModuleDependanciesDefinition.ForEach{ [PSCustomObject]@{ Name = $_.Name; Version = $_.Version } })
                    }

                    # Save File
                    $cfg | ConvertTo-Json | Out-File -FilePath ([IO.Path]::Combine($ScriptObj.SourceDirectory, "$($ScriptObj.Name).config.json"))

                    # Update Object in Memory
                    $ScriptObj.Update($(priv_Test-Script -ScriptPath $ScriptObj.ScriptPath -UseScriptConfigFile))
                }
                else
                {
                    Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> Updating Script File Info"

                    $currentVerbosePreference = $VerbosePreference
                    $VerbosePreference = 'SilentlyContinue'

                    Update-ScriptFileInfo -Path ($ScriptObj.ScriptPath) -RequiredModules $ModuleDependanciesDefinition -ErrorAction Stop
                    
                    # Update Object in Memory
                    $ScriptObj.Update($(priv_Test-Script -ScriptPath $ScriptObj.ScriptPath))

                    $VerbosePreference = $currentVerbosePreference
                }
            }


            ### PART 4-b: Check if all commands are referenced
            if([PSBuild.Context]::Current.CheckCommandReferencesConfiguration.Enabled)
            {
                if([PSBuild.Context]::Current.CheckCommandReferencesConfiguration.ExcludedSources -notcontains ($ScriptObj.Name))
                {
                    # Update Script Definition. This is required in order to extract all commands used inside the script
                    Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> Reading Script AST"
                    $scrDefiniton = priv_Get-ScriptDefinition -ScriptPath ($ScriptObj.ScriptPath)
                    $ScriptObj.UpdateScriptDefinitionAst($scrDefiniton)


                    Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> Checking if all commands are referenced"
                    foreach($NonLocalCommand in $ScriptObj.GetNonLocalCommands())
                    {
                        if([PSBuild.Context]::Current.CheckCommandReferencesConfiguration.ExcludedCommands -notcontains $NonLocalCommand)
                        {
                            if([PSBuild.Context]::Current.CommandsToModuleMapping.ContainsCommand($NonLocalCommand))  
                            {
                                $cmdIsReferenced = $false
                                foreach($cmdSrc in ([PSBuild.Context]::Current.CommandsToModuleMapping.GetCommandSources($NonLocalCommand)))
                                {
                                    if(($cmdSrc.SourceLocation -eq [PSBuild.CommandSourceLocation]::BuiltIn) -or 
                                       ($ScriptObj.ScriptInfo.RequiredModules.Name -contains $cmdSrc.Source))
                                    {
                                        # Module is either BuiltIn or explicitly referenced
                                        $cmdIsReferenced = $true
                                        break
                                    }
                                }

                                if(-not $cmdIsReferenced)
                                {
                                    if([PSBuild.Context]::Current.CommandsToModuleMapping.GetCommandSources($NonLocalCommand).Count -gt 1)
                                    {
                                        throw "Build Script '$ScriptObj' failed. The command '$NonLocalCommand' was found in modules $(@([PSBuild.Context]::Current.CommandsToModuleMapping.GetCommandSources($NonLocalCommand).ForEach{ "'$($_.Source)'" }) -join ', ') but neither is referenced in the script metadata."
                                    }
                                    else
                                    {
                                        throw "Build Script '$ScriptObj' failed. The command '$NonLocalCommand' was found in module '$([PSBuild.Context]::Current.CommandsToModuleMapping.GetCommandSources($NonLocalCommand)[0].Source)' but it is not referenced in the script metadata."
                                    }
                                }
                            }
                            else
                            {
                                throw "Build Script '$ScriptObj' failed. The command '$NonLocalCommand' was not found in any of the required modules referenced in the script metadata."
                            }
                        }
                    }
                }
            }


            ### PART 4-c: Check Module Integrity
            if (-not $ScriptObj.IsReadyForPackaging)
            {
                throw "Build Script '$ScriptObj' failed. The script is not ready for packaging. Missing either Author or Description."
            }

            if (-not $ScriptObj.IsValid)
            {
                ## NOTE: This also updates the file hash
                Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> Updating Script Version"

                $currentVerbosePreference = $VerbosePreference
                $VerbosePreference = 'SilentlyContinue'

                $oldScriptVer = $ScriptObj.ScriptInfo.Version
                Update-PSScriptVersion -ScriptPath ($ScriptObj.ScriptPath) -ErrorAction Stop -Verbose:$false
						
                # Update Object in Memory
                $ScriptObj.Update($(priv_Test-Script -ScriptPath $ScriptObj.ScriptPath -UseScriptConfigFile:($UseScriptConfigFile.IsPresent)))

                Write-Warning -Message "[Build PSScript] Processing $ScriptObj -> Updated script from version $($oldScriptVer) to version $($ScriptObj.ScriptInfo.Version)"

                $VerbosePreference = $currentVerbosePreference
            }


            ### PART 4-d: Export Script to TargetDirectory
            if($ScriptObj.TargetDirectory)
            {
                Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> Exporting Script"

                try
                {
                    if( -not [IO.Directory]::Exists($ScriptObj.TargetDirectory)) { $null = [IO.Directory]::CreateDirectory($ScriptObj.TargetDirectory) }
                    
                    $privExportArtifact_Params = @{
                        SourcePath      = $ScriptObj.ScriptPath
                        DestinationPath = $ScriptObj.TargetDirectory
                    }
                    if ($UseScriptConfigFile.IsPresent)
                    {
                        $privExportArtifact_Params.Add('Type', 'ScriptWithConfig')
                    }
                    else
                    {
                        $privExportArtifact_Params.Add('Type', 'Script')
                    }

                    priv_Export-Artifact @privExportArtifact_Params -Verbose:$false
                                        
                    [PSBuild.Context]::Current.BuiltScriptsCache.Add([PSBuild.PSScriptBuildInfo]::new($ScriptObj.Name, $ScriptObj.ScriptInfo.Version, $ScriptObj.ScriptPath, $ScriptObj.TargetDirectory))
                }
                catch
                {
                    throw "Build Script '$ScriptObj' failed. Cannot copy script to '$DestinationPath'. Details: $_"
                }
            }


            Write-Verbose -Message "[Build PSScript] Processing $ScriptObj -> DONE"
        }
    }
}

function Build-PSSolution
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SolutionConfigPath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_SolutionByPath')]
        [System.IO.DirectoryInfo]$SolutionConfigPath,

        #SolutionConfig
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_SolutionByObject')]
        [psobject]$SolutionConfigObject,

        #Clear
        [Parameter(Mandatory = $false)]
        [switch]$Clear
    )

    Begin
    {
        if($Clear.IsPresent)
        {
            [PSBuild.Context]::Current.SolutionModulesCache.Clear()
            [PSBuild.Context]::Current.SolutionScriptsCache.Clear()
            [PSBuild.Context]::Current.PsGetModuleValidationCache.Clear()
            [PSBuild.Context]::Current.BuiltModulesCache.Clear()
            [PSBuild.Context]::Current.ExternalModulesCache.Clear()
            [PSBuild.Context]::Current.CommandsToModuleMapping.Clear()
        }
    }

    Process
    {
        #Initialize SolutionConfiguration
        try
        {
            Write-Verbose "Initialize SolutionConfiguration started"
			
            switch ($PSCmdlet.ParameterSetName)
            {
                'NoRemoting_SolutionByPath'
                {
                    $SolutionConfig = Get-PSSolutionConfiguration -Path $SolutionConfigPath.FullName -ErrorAction Stop
                    break
                }
                'NoRemoting_SolutionByObject'
                {
                    $SolutionConfig = $SolutionConfigObject
                    break
                }
                default
                {
                    throw "Unknown ParameterSetName: $($PSCmdlet.ParameterSetName)"
                }
            }


            [PSBuild.Context]::Current.CheckCommandReferencesConfiguration = [PSBuild.CheckCommandReferencesConfiguration]::new($SolutionConfig.Build.CheckCommandReferences)

            [PSBuild.Context]::Current.AllowDuplicateCommandsInCommandToModuleMapping = (-not ($SolutionConfig.Build.CheckDuplicateCommandNames))

            [PSBuild.Context]::Current.UpdateModuleReferences = $SolutionConfig.Build.UpdateModuleReferences


            Write-Verbose "Initialize SolutionConfiguration completed"
        }
        catch
        {
            Write-Error "Initialize SolutionConfiguration failed. Details: $_" -ErrorAction 'Stop'
        }

        #Configure PS Environment
        try
        {
            Write-Verbose "Configure PS Environment started"

            $DependancyFolders = [System.Collections.Generic.List[string]]::new()
            foreach ($mp in $SolutionConfig.SolutionStructure.ModulesPath)
            {
                if ($mp.ContainsKey('BuildPath'))
                {
                    $DependancyFolders.Add($mp.BuildPath)
                }
            }
            foreach ($mp in $SolutionConfig.SolutionStructure.ScriptPath)
            {
                if ($mp.ContainsKey('DependencyDestinationPath'))
                {
                    $DependancyFolders.Add($mp.DependencyDestinationPath)
                }
                elseif ($mp.ContainsKey('BuildPath'))
                {
                    $DependancyFolders.Add($mp.BuildPath)
                }
            }

            if ($DependancyFolders.Count -gt 0)
            {
                $AddRemove_PSModulePathEntry_CommonParams = @{
                    path  = $DependancyFolders
                    Scope = @('User', 'Process')
                }

                #Check if AutoloadDependanciesScope are defined in config
                if ($SolutionConfig.Build.AutoloadDependanciesScope)
                {
                    $AddRemove_PSModulePathEntry_CommonParams['Scope'] = $SolutionConfig.Build.AutoloadDependanciesScope
                }

                if ($SolutionConfig.Build.AutoloadDependancies)
                {
                    Write-Verbose "Configure PS Environment in progress. Enable Module autoloading for: $($DependancyFolders -join ',')"
                    Add-PSModulePathEntry @AddRemove_PSModulePathEntry_CommonParams -Force -ErrorAction Stop
                }
                else
                {
                    Write-Verbose "Configure PS Environment in progress. Disable Module autoloading for: $($DependancyFolders -join ',')"
                    Remove-PSModulePathEntry @AddRemove_PSModulePathEntry_CommonParams -ErrorAction Stop -WarningAction SilentlyContinue
                }
            }

            Write-Verbose "Configure PS Environment completed"
        }
        catch
        {
            Write-Error "Configure PS Environment failed. Details: $_" -ErrorAction 'Stop'
        }

        #Run PreBuild Actions
        try
        {
            Write-Verbose "Run PreBuild Actions started"
			
            Foreach ($Action in $SolutionConfig.BuildActions.PreBuild)
            {
                try
                {
                    Write-Verbose "Run PreBuild Actions in progress. Action: $($Action['Name']) starting."
                    $Null = Invoke-Command -ScriptBlock $Action['ScriptBlock'] -ErrorAction Stop -NoNewScope
                    Write-Verbose "Run PreBuild Actions in progress. Action: $($Action['Name']) completed."
                }
                catch
                {
                    Write-Warning "Run PreBuild Actions in progress. Action: $($Action['Name']) failed."
                    throw $_
                }
            }
      
            Write-Verbose "Run PreBuild Actions completed"
        }
        catch
        {
            Write-Error "Run PreBuild Actions failed. Details: $_" -ErrorAction 'Stop'
        }

        #Build Solution Modules
        try
        {
            if ($SolutionConfig.SolutionStructure.ModulesPath)
            {
                Write-Verbose "Build PSModules started"

                #Enumerate All Modules
                $ModulePathConfiguration = [PSBuild.PSModuleBuildInfoCollection]::new()
                foreach ($ModulePath in $SolutionConfig.SolutionStructure.ModulesPath)
                {
                    $modulesFound = Get-ChildItem -Path $ModulePath.SourcePath -Directory -ErrorAction Stop -Verbose:$false
                    foreach($moduleFound in $modulesFound)
                    {
                        $ModulePathConfiguration.Add([PSBuild.PSModuleBuildInfo]::new(
                            $moduleFound.Name,
                            $null,
                            $moduleFound.FullName,
                            $ModulePath.BuildPath
                        ))
                    }
                }

                $BuildPSModule_Params = @{
                    ModulePathConfiguration    = $ModulePathConfiguration
                    ResolveDependancies        = $SolutionConfig.Build.AutoResolveDependantModules
                    PSGetRepository            = $SolutionConfig.Packaging.PSGetSearchRepositories
                }
                if ($SolutionConfig.GlobalSettings.Proxy.Uri) { $BuildPSModule_Params.Add('Proxy', $SolutionConfig.GlobalSettings.Proxy.Uri) }

                Build-PSModule @BuildPSModule_Params -ErrorAction Stop
		
                Write-Verbose "Build PSModules completed"
            }
            else
            {
                Write-Verbose "Build PSModules skipped"
            }
        }
        catch
        {
            Write-Error "Build Solution Modules failed. Details: $_" -ErrorAction 'Stop'
        }

        #Build Solution Scripts
        try
        {
            Write-Verbose "Build Solution Scripts started"

            #Enumerate All Scripts
            $ScriptPathConfiguration = [PSBuild.PSScriptBuildInfoCollection]::new()
            foreach ($ScriptPath in $SolutionConfig.SolutionStructure.ScriptPath)
            {
                if(($SolutionConfig.Build.AutoResolveDependantModules) -and [String]::IsNullOrEmpty($ScriptPath.BuildPath) -and [String]::IsNullOrEmpty($ScriptPath.DependencyDestinationPath))
                {
                    throw "Build Solution Scripts failed. The Solution Configuration is invalid. ScriptPath requires you to specify at least one of the following properties: BuildPath, DependencyDestinationPath."
                }

                $scriptsFound = Get-ChildItem -Path $ScriptPath.SourcePath -Filter *.ps1  -ErrorAction Stop
                foreach($scriptFound in $scriptsFound)
                {
                    $ScriptPathConfiguration.Add([PSBuild.PSScriptBuildInfo]::new(@{
                        Name                           = $scriptFound.Name
                        SourcePath                     = $scriptFound.FullName
                        DestinationPath                = $ScriptPath.BuildPath
                        RequiredModulesDestinationPath = $(if($ScriptPath.DependencyDestinationPath) {$ScriptPath.DependencyDestinationPath} else {$ScriptPath.BuildPath})
                    }))
                }
            }

            $BuildPSScript_Params = @{
                ScriptPathConfiguration    = $ScriptPathConfiguration
                ResolveDependancies        = $SolutionConfig.Build.AutoResolveDependantModules
                UseScriptConfigFile        = $SolutionConfig.Build.UseScriptConfigFile
                PSGetRepository            = $SolutionConfig.Packaging.PSGetSearchRepositories
            }
            if ($SolutionConfig.GlobalSettings.Proxy.Uri) { $BuildPSScript_Params.Add('Proxy', $SolutionConfig.GlobalSettings.Proxy.Uri) }

            Build-PSScript @BuildPSScript_Params -ErrorAction Stop
      
            Write-Verbose "Build Solution Scripts completed"
        }
        catch
        {
            Write-Error "Build Solution Scripts failed. Details: $_" -ErrorAction 'Stop'
        }

        #Run PostBuild Actions
        try
        {
            Write-Verbose "Run PostBuild Actions started"
			
            Foreach ($Action in $SolutionConfig.BuildActions.PostBuild)
            {
                try
                {
                    Write-Verbose "Run PostBuild Actions in progress. Action: $($Action['Name']) starting."
                    $Null = Invoke-Command -ScriptBlock $Action['ScriptBlock'] -ErrorAction Stop -NoNewScope
                    Write-Verbose "Run PostBuild Actions in progress. Action: $($Action['Name']) completed."
                }
                catch
                {
                    Write-Warning "Run PostBuild Actions in progress. Action: $($Action['Name']) failed."
                    throw $_
                }
            }
      
            Write-Verbose "Run PostBuild Actions completed"
        }
        catch
        {
            Write-Error "Run PostBuild Actions failed. Details: $_" -ErrorAction 'Stop'
        }
    }
}

function Publish-PSSolution
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SolutionConfigPath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_SolutionByPath')]
        [System.IO.DirectoryInfo]$SolutionConfigPath,

        #SolutionConfig
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_SolutionByObject')]
        [psobject]$SolutionConfigObject
    )

    Process
    {
        #Initialize SolutionConfiguration
        try
        {
            Write-Verbose "Initialize SolutionConfiguration started"
			
            switch ($PSCmdlet.ParameterSetName)
            {
                'NoRemoting_SolutionByPath'
                {
                    $SolutionConfig = Get-PSSolutionConfiguration -Path $SolutionConfigPath.FullName -ErrorAction Stop
                    break
                }
                'NoRemoting_SolutionByObject'
                {
                    $SolutionConfig = $SolutionConfigObject
                    break
                }
                default
                {
                    throw "Unknown ParameterSetName: $($PSCmdlet.ParameterSetName)"
                }
            }

            Write-Verbose "Initialize SolutionConfiguration completed"
        }
        catch
        {
            Write-Error "Initialize SolutionConfiguration failed. Details: $_" -ErrorAction 'Stop'
        }

        #Publish Solution Modules
        try
        {
            Write-Verbose "Publish Solution Modules started"

            #Get All Modules
            $Modules = New-Object -TypeName system.collections.arraylist
            foreach ($modPath in $SolutionConfig.SolutionStructure.ModulesPath)
            {
                Get-ChildItem -Path $modPath.SourcePath -Directory -ErrorAction Stop | ForEach-Object {
                    $ModuleToPathMapping = @{
                        Module     = $_
                        SourcePath = Join-Path -Path $modPath.SourcePath -ChildPath $_.Name
                        BuildPath  = Join-Path -Path $modPath.BuildPath -ChildPath $_.Name
                    }
                    $null = $Modules.Add($ModuleToPathMapping)
                }
            }

            #Determine which modules should be published
            if ((-not $SolutionConfig.Packaging.PublishAllModules) -and ($SolutionConfig.Packaging.PublishSpecificModules.Count -gt 0))
            {
                $Modules = $Modules | Where-Object { $SolutionConfig.Packaging.PublishSpecificModules -contains $_.Module.Name }
            }
            elseif ($SolutionConfig.Packaging.PublishAllModules -and ($SolutionConfig.Packaging.PublishSpecificModules.Count -gt 0))
            {
                Write-Warning "Publish Solution Modules in progress. No Modules are configured to be published"
            }
            if ($SolutionConfig.Packaging.PublishExcludeModules.Count -gt 0)
            {
                $Modules = $Modules | Where-Object { $SolutionConfig.Packaging.PublishExcludeModules -ne $_.Module.Name }
            }

            #Determine if there are PSGetRepositories specified for publishing
            if ($Modules)
            {
                if ($SolutionConfig.Packaging.PSGetPublishRepositories.Count -eq 0)
                {
                    Write-Warning "Publish Solution Modules in progress. There are modules for publishing, but no PSGetPublishRepositories are specified"
                }
            }
            else
            {
                Write-Warning "Publish Solution Modules in progress. No Modules for publishing"
            }

            #Install Nuget PackageProvider
            try
            {
                $NuGetProvider = Get-PackageProvider -Name nuget -ErrorAction Stop | Where-Object { [version]$_.Version -ge [version]'2.8.5.208' }
            }
            catch
            {

            }
            if (-not $NuGetProvider)
            {
                $null = Install-PackageProvider -Name Nuget -Force -Confirm:$false -Verbose:$false -Scope CurrentUser
            }


            #Publish Modules to each PSGetPublishRepositories
            foreach ($Repo in $SolutionConfig.Packaging.PSGetPublishRepositories)
            {
                Add-PSModulePathEntry -Scope Process -Path $Modules.BuildPath -ErrorAction Stop
                Publish-PSModule -ModulePath $Modules.BuildPath -PSGetRepository $Repo -ErrorAction Stop
            }

            Write-Verbose "Publish Solution Modules completed"
        }
        catch
        {
            Write-Error "Publish Solution Modules failed. Details: $_" -ErrorAction 'Stop'
        }
    }
}

function Publish-PSModule
{
    [CmdletBinding()]
    param
    (
        #ModulesFolder
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo[]]$ModulePath,

        #PSGetRepository
        [Parameter(Mandatory = $false)]
        [hashtable]$PSGetRepository,

        #SkipVersionValidation
        [Parameter(Mandatory = $false)]
        [switch]$SkipVersionValidation,
		
        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )

    Process
    {
        #Check if Repository is already registered
        try
        {
            Write-Verbose "Check if Repository is already registered started"
			
            $AssertPSRepository_Params = @{
                PSGetRepository = $PSGetRepository
            }
            if ($PSBoundParameters.ContainsKey('Proxy'))
            {
                $AssertPSRepository_Params.Add('Proxy', $Proxy)
            }
            Assert-PSRepository @AssertPSRepository_Params -ErrorAction Stop
			
            Write-Verbose "Check if Repository is already registered completed"
        }
        catch
        {
            Write-Error "Check if Repository is already registered failed. Details: $_" -ErrorAction 'Stop'
        }

        #Publish Module
        foreach ($Module in $ModulePath)
        {
            try
            {
                $moduleName = $Module.Name
                Write-Verbose "Publish Module:$moduleName started"

                #Check if Module is already built
                $ModInfo = Test-PSModule -ModulePath $Module -ErrorAction Stop
                if (-not $ModInfo.IsVersionValid -and (-not $SkipVersionValidation.IsPresent))
                {
                    throw 'not builded'
                }

                #Publish Module
                $PublishModuleAndDependacies_Params = @{
                    ModuleInfo              = $ModInfo.ModuleInfo
                    Repository              = $PSGetRepository.Name
                    PublishDependantModules = $true
                    Force                   = $true
                }
                if ($PSGetRepository.ContainsKey('Credential'))
                {
                    $PublishModuleAndDependacies_Params.Add('Credential', $PSGetRepository.Credential)
                }
                if ($PSGetRepository.ContainsKey('NuGetApiKey'))
                {
                    $PublishModuleAndDependacies_Params.Add('NuGetApiKey', $PSGetRepository.NuGetApiKey)
                }
                if ($PSBoundParameters.ContainsKey('Proxy'))
                {
                    $PublishModuleAndDependacies_Params.Add('Proxy', $Proxy)
                }
                priv_Publish-PSModule @PublishModuleAndDependacies_Params -ErrorAction Stop -Verbose -VerbosePrefix "Publish Module:$moduleName in progress. "

                Write-Verbose "Publish Module:$moduleName completed"
            }
            catch
            {
                Write-Error "Publish Module:$moduleName failed. Details: $_" -ErrorAction Stop
            }
        }
    }
}

function Get-PSSolutionConfiguration
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #Path
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [System.IO.FileInfo]$Path,

        #UserVariables
        [Parameter(Mandatory = $false, ParameterSetName = 'NoRemoting_Default')]
        [hashtable]$UserVariables
    )

    Process
    {
        try
        {
            $SolutionConfig = [System.Collections.Generic.List[string]]::new()
            
            #Add Variables
            $SolutionConfig.Add("`$env:ScriptRoot = '$(Split-Path -Path $Path.FullName -Parent -ErrorAction Stop)'")
            if ($PSBoundParameters.ContainsKey('UserVariables'))
            {
                $SolutionConfig.Add("`$Variables = $(Convertto-string -InputObject $UserVariables)")
            }
            else
            {
                $SolutionConfig.Add("`$Variables = @{}")
            }
            $SolutionConfig.Add("`$Variables['ScriptRoot'] = '$(Split-Path -Path $Path.FullName -Parent -ErrorAction Stop)'")

            #Get config from file
            Get-Content -Path $Path.FullName -ErrorAction Stop | foreach {
                $SolutionConfig.Add($_)
            }
            $SolutionConfigAsString = $SolutionConfig -join [System.Environment]::NewLine
            
            New-DynamicConfiguration -Definition ([scriptblock]::Create($SolutionConfigAsString)) -ErrorAction Stop
        }
        catch
        {
            Write-Error "Unable to load SolutionConfiguration: $($Path.FullName). Details: $_"
        }
    }
}

function Clear-PSSolution
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #SolutionConfigPath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_SolutionByPath')]
        [System.IO.DirectoryInfo]$SolutionConfigPath,

        #SolutionConfig
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_SolutionByObject')]
        [psobject]$SolutionConfigObject
    )
    
    Process
    {
        #Initialize SolutionConfiguration
        try
        {
            Write-Verbose "Initialize SolutionConfiguration started"
			
            switch ($PSCmdlet.ParameterSetName)
            {
                'NoRemoting_SolutionByPath'
                {
                    $SolutionConfig = Get-PSSolutionConfiguration -Path $SolutionConfigPath.FullName -ErrorAction Stop
                    break
                }
                'NoRemoting_SolutionByObject'
                {
                    $SolutionConfig = $SolutionConfigObject
                    break
                }
                default
                {
                    throw "Unknown ParameterSetName: $($PSCmdlet.ParameterSetName)"
                }
            }

            Write-Verbose "Initialize SolutionConfiguration completed"
        }
        catch
        {
            Write-Error "Initialize SolutionConfiguration failed. Details: $_" -ErrorAction 'Stop'
        }

        #Clear Modules
        try
        {
            Write-Verbose "Clear Modules started"
		
            foreach ($Entry in $SolutionConfig.SolutionStructure.ModulesPath)
            {
                if ($Entry.BuildPath -and (Test-Path -Path $Entry.BuildPath))
                {
                    Write-Verbose "Clear Modules in proress. Deleting PSModuleBuildPath: $($Entry.BuildPath)"
                    Remove-Item -Path $Entry.BuildPath -Force -Recurse -ErrorAction Stop
                }			
            }
      
            Write-Verbose "Clear Modules completed"
        }
        catch
        {
            Write-Error "Clear Modules failed. Details: $_" -ErrorAction 'Stop'
        }

        #Clear Scripts
        try
        {
            Write-Verbose "Clear Scripts started"
			
            foreach ($Entry in $SolutionConfig.SolutionStructure.ScriptPath)
            {
                if ($Entry.BuildPath -and (Test-Path -Path $Entry.BuildPath))
                {
                    Write-Verbose "Clear Scripts in proress. Deleting PSScriptBuildPath: $($Entry.BuildPath)"
                    Remove-Item -Path $Entry.BuildPath -Force -Recurse -ErrorAction Stop
                }
				
                if ($Entry.DependencyDestinationPath -and (Test-Path -Path $Entry.DependencyDestinationPath))
                {
                    Write-Verbose "Clear Scripts in proress. Deleting PSScriptDependencyDestinationPath: $($Entry.DependencyDestinationPath)"
                    Remove-Item -Path $Entry.DependencyDestinationPath -Force -Recurse -ErrorAction Stop
                }
            }
			      
            Write-Verbose "Clear Scripts completed"
        }
        catch
        {
            Write-Error "Clear Scripts failed. Details: $_" -ErrorAction 'Stop'
        }
    }
}

function Assert-PSRepository
{
    [CmdletBinding()]
    [OutputType([void])]
    param
    (
        #PSGetRepository
        [Parameter(Mandatory = $true)]
        [hashtable[]]$PSGetRepository,
		
        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )

    Process
    {
        foreach ($Repo in $PSGetRepository)
        {
            if([PSBuild.Context]::Current.AssertedPSRepositories -notcontains ($Repo.Name)) # local cache to speed things up with multiple calls
            {
                #Check if Repository is already registered
                $RepoFound = $false

                try
                {
                    $VerbosePreference = 'SilentlyContinue'
                    $RepoCheck = Get-PSRepository -Name $Repo.Name -ErrorAction Stop -Verbose:$false
                    if ($RepoCheck)
                    {
                        if ($Repo.ContainsKey('SourceLocation') -and ($RepoCheck.SourceLocation -ne $Repo.SourceLocation))
                        {
                            $SetPSRepository_Params = @{
                                Name           = $Repo.Name
                                SourceLocation = $Repo.SourceLocation
                            }
                            if ($PSBoundParameters.ContainsKey('Proxy'))
                            {
                                $SetPSRepository_Params.Add('Proxy', $Proxy)
                            }
                            Set-PSRepository @SetPSRepository_Params -ErrorAction Stop -Verbose:$false
                        }
                        if ($Repo.ContainsKey('PublishLocation') -and ($RepoCheck.PublishLocation -ne $Repo.PublishLocation))
                        {
                            $SetPSRepository_Params = @{
                                Name           = $Repo.Name
                                SourceLocation = $Repo.PublishLocation
                            }
                            if ($PSBoundParameters.ContainsKey('Proxy'))
                            {
                                $SetPSRepository_Params.Add('Proxy', $Proxy)
                            }
                            Set-PSRepository @SetPSRepository_Params -ErrorAction Stop -Verbose:$false
                        }

                        $RepoFound = $true
                    }
                }
                catch
                {
                }
			
                if (-not $RepoFound)
                {
                    $RegisterPSRepository_Params = @{ } + $Repo
                    if ($PSBoundParameters.ContainsKey('Proxy'))
                    {
                        $RegisterPSRepository_Params.Add('Proxy', $Proxy)
                    }
                    $null = Register-PSRepository @RegisterPSRepository_Params -ErrorAction Stop -Verbose:$false
                }

                [PSBuild.Context]::Current.AssertedPSRepositories.Add($Repo.Name)
            }
        }
    }
}

#endregion

#region private Variables

$PSNativeModules = @(
    'Microsoft.PowerShell.Management'
    'Microsoft.PowerShell.Core'
    'Microsoft.PowerShell.Utility'
    'Microsoft.PowerShell.Security'
    'Microsoft.PowerShell.Archive'
)

#endregion

