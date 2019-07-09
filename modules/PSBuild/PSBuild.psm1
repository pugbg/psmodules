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

        #GlobalCommandAnalysis
        [Parameter(Mandatory = $true)]
        [ref]$GlobalCommandAnalysis,

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
            GlobalCommandAnalysisAsJson = $GlobalCommandAnalysis.Value.ToJson()
            CurrentDependancies         = $CurrentDependancies
            PSGetRepository             = $PSGetRepository
            PSBuildDllPath              = [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq 'PSBuildEntities' } | select -ExpandProperty Location
            PSBuildModulePath = (Get-Module -Name psbuild).Path
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
                Add-Type -Path $JobParams['PSBuildDllPath'] -ErrorAction Stop
                $GlobalCommandAnalysis = [PSBuildEntities.AnalysisResultCollection]::FromJson($JobParams['GlobalCommandAnalysisAsJson'])
                $LocalCommandAnalysis = [PSBuildEntities.AnalysisResultCollection]::New()
			
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
                        throw "Unable to Import Module: $($ModuleValidationCache.Value[$moduleName].ModuleInfo.ModuleBase). Details: $er"
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
                        $CmdResult = [PSBuildEntities.AnalysisResult]::new()
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
                                    $private:TempNugetResult = Find-Module @FindModule_Params -ErrorAction Stop

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
                                                $LocalCommandAnalysis[$MissingCmd.CommandName].SourceLocation = [PSBuildEntities.AnalysisResultSourceLocation]::ProGet
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

        #Update GlobalCommandAnalysis
        $GlobalCommandAnalysis.Value = [PSBuildEntities.AnalysisResultCollection]::FromJson($JobResult.GlobalCommandAnalysisAsJson)
        [PSBuildEntities.AnalysisResultCollection]::FromJson($JobResult.LocalCommandAnalysisAsJson)
    }
}

function priv_Validate-Module
{
    [CmdletBinding()]
    param
    (
        #SourcePath
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [System.IO.DirectoryInfo[]]$SourcePath,

        #ModuleValidation
        [Parameter(Mandatory = $true, ParameterSetName = 'NoRemoting_Default')]
        [ref]$ModuleValidationCache
    )
    
    Process
    {
        foreach ($Module in $SourcePath)
        {
            $moduleName = $Module.Name
            if (-not $ModuleValidationCache.Value.ContainsKey($moduleName))
            {
                $null = $ModuleValidationCache.Value.Add($moduleName, (Test-PSModule -ModulePath $Module.FullName -ErrorAction Stop))
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
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo[]]$SourcePath,

        #DestinationPath
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$DestinationPath,

        #ResolveDependancies
        [Parameter(Mandatory = $false)]
        [switch]$ResolveDependancies,

        #CheckCommandReferencesConfiguration
        [Parameter(Mandatory = $false)]
        [CheckCommandReferencesConfiguration]$CheckCommandReferencesConfiguration = ([CheckCommandReferencesConfiguration]::new()),

        #CheckDuplicateCommandNames
        [Parameter(Mandatory = $false)]
        [switch]$CheckDuplicateCommandNames,

        #UpdateModuleReferences
        [Parameter(Mandatory = $false)]
        [switch]$UpdateModuleReferences,

        #PSGetRepository
        [Parameter(Mandatory = $false)]
        [hashtable[]]$PSGetRepository,

        #ModuleValidation
        [Parameter(Mandatory = $false)]
        [ref]$ModuleValidationCache,

        #PsGetModuleValidation
        [Parameter(Mandatory = $false)]
        [ref]$PsGetModuleValidationCache,

        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )
    
    Process
    {
        #Add DestinationPath to Process PSModulePath
        try
        {
            Add-PSModulePathEntry -Path $DestinationPath -Scope Process -Force
        }
        catch
        {
            Write-Error "Add DestinationPath to Process PSModulePath failed. Details: $_" -ErrorAction 'Stop'
        }

        #Assert PSRepositories
        if ($PSBoundParameters.ContainsKey('PSGetRepository'))
        {
            #Register PSGetRepo
            $AssertPSRepository_Params = @{
                PSGetRepository = $PSGetRepository
            }
            if ($PSBoundParameters.ContainsKey('Proxy'))
            {
                $AssertPSRepository_Params.Add('Proxy', $Proxy)
            }
            Assert-PSRepository @AssertPSRepository_Params -ErrorAction Stop
        }

        #Validate All Modules
        try
        {
            if (-not $PSBoundParameters.ContainsKey('ModuleValidationCache'))
            {
                [ref]$ModuleValidationCache = @{ }
            }
            priv_Validate-Module -SourcePath $SourcePath -ModuleValidationCache $ModuleValidationCache
        }
        catch
        {
            Write-Error "Unable to validate $moduleName. Details: $_" -ErrorAction 'Stop'
        }

        #Validate All Commands
        try
        {
            [ref]$CommandsToModuleMapping = [PSBuildEntities.AnalysisResultCollection]::new()

            #Add BuildIn Comands and Aliases to CommandsToModuleMapping (from module 'Microsoft.PowerShell.Core' as they are buildin to PowerShell)
            Get-Command -Module $PSNativeModules -Verbose:$false | ForEach-Object {

                #Add Command
                $Command = [PSBuildEntities.AnalysisResult]::new()
                $Command.CommandName = "$($_.Name)"
                $Command.CommandType = $_.CommandType
                if ($Command.CommandType -eq 'Alias')
                {
                    try
                    {
                        $TempFinding2 = Get-Command -Name $Command.CommandName -ErrorAction Stop -Verbose:$false
                        $Command.CommandSource = $TempFinding2.Source
                    }
                    catch
                    {
                    }
                }
                else
                {
                    $Command.CommandSource = $_.Source
                }
                $Command.SourceLocation = [PSBuildEntities.AnalysisResultSourceLocation]::BuildIn
                if (-not $CommandsToModuleMapping.Value.Contains($Command.CommandName))
                {
                    $CommandsToModuleMapping.Value.add($Command)
                }

                #Add Alias if exists
                Get-Alias -Definition $_.Name -ErrorAction SilentlyContinue | foreach {
                    $Alias = [PSBuildEntities.AnalysisResult]::new()
                    $Alias.CommandName = "$($_.Name)"
                    $Alias.CommandType = 'Alias'
                    $Alias.CommandSource = $Command.CommandSource
                    $Alias.SourceLocation = [PSBuildEntities.AnalysisResultSourceLocation]::BuildIn
                    if (-not $CommandsToModuleMapping.Value.Contains($Alias.CommandName))
                    {
                        $CommandsToModuleMapping.Value.add($Alias)
                    }
                }
            }

            #Add Solution Commands to CommandsToModuleMapping (from all modules in the solution)
            foreach ($Mod in $ModuleValidationCache.Value.Keys)
            {
                foreach ($cmd in $ModuleValidationCache.Value[$Mod].ModuleInfo.ExportedCommands.Values)
                {
                    $Command = [PSBuildEntities.AnalysisResult]::new()
                    $Command.CommandName = $cmd.Name
                    $Command.CommandType = $cmd.CommandType
                    $Command.CommandSource = $cmd.Source
                    $Command.SourceLocation = [PSBuildEntities.AnalysisResultSourceLocation]::Solution
                    if (-not $CommandsToModuleMapping.Value.Contains($cmd.Name))
                    {
                        $CommandsToModuleMapping.Value.Add($Command)
                    }
                    elseif ($CommandsToModuleMapping.Value[$Command.CommandName].CommandSource -ne $Command.CommandSource)
                    {
                        if ($CheckDuplicateCommandNames.IsPresent)
                        {
                            Write-Error "Command with name: $($Command.CommandName) is present in multiple modules: $($CommandsToModuleMapping.Value[$Command.CommandName].CommandSource),$($Command.CommandSource)" -ErrorAction Stop
                        }
                    }
                }
            }
        }
        catch
        {
            Write-Error "Validate All Commands failed. Details: $_" -ErrorAction 'Stop'
        }

        #Initialize PSGetModuleValidationCache
        if (-not $PSBoundParameters.ContainsKey('PsGetModuleValidationCache'))
        {
            [ref]$PsGetModuleValidationCache = @{ }
        }

        #Build Module
        foreach ($Module in $SourcePath)
        {
            $moduleName = $Module.Name
            if ($ModuleValidationCache.Value[$moduleName].ModuleInfo)
            {
                $moduleVersion = $ModuleValidationCache.Value[$moduleName].ModuleInfo.Version

                Write-Verbose "Build PSModule:$moduleName/$moduleVersion started"

                #Check if Module is already built
                try
                {
                    Remove-Variable -Name ModAlreadyBuildTest -ErrorAction SilentlyContinue
                    $ModuleAlreadyBuild = $false
                    $ModuleDependanciesValid = $true
                    $ModuleVersionBuilded = $false
                    $ModuleBuildDestinationPath = Join-Path -Path $DestinationPath -ChildPath $moduleName -ErrorAction Stop
                    if (Test-Path -Path $ModuleBuildDestinationPath)
                    {
                        $ModAlreadyBuildTest = Test-PSModule -ModulePath $ModuleBuildDestinationPath -ErrorAction Stop
                    }
				
                    #Check if Module with the same version is already builded
                    if ($ModuleValidationCache.Value[$moduleName].IsValid -and $ModAlreadyBuildTest.IsValid -and ($ModuleValidationCache.Value[$moduleName].ModuleInfo.Version -eq $ModuleValidationCache.Value[$moduleName].ModuleInfo.Version))
                    {
                        $ModuleVersionBuilded = $true
                    }

                    #Check if Module Dependancies are valid versions
                    foreach ($DepModule in $ModuleValidationCache.Value[$moduleName].ModuleInfo.RequiredModules)
                    {
                        $depModuleName = $DepModule.Name
                        $depModuleVersion = $DepModule.Version
                        $DepModuleDestinationPath = Join-Path -Path $DestinationPath -ChildPath $depModuleName -ErrorAction Stop

                        #Check if DepModule is marked as ExternalModuleDependency
                        if ($ModuleValidationCache.Value[$moduleName].ModuleInfo.PrivateData.PSData.ExternalModuleDependencies -contains $depModuleName)
                        {
                            #Skip this DepModule from validation, as it is marked as external
                        }
                        #Check if DepModule is in the same Solution
                        elseif (($ModuleValidationCache.Value).ContainsKey($depModuleName))
                        {
                            if ($ModuleValidationCache.Value[$depModuleName].ModuleInfo.Version -gt $depModuleVersion -or (-not $ModuleValidationCache.Value[$depModuleName].IsValid))
                            {
                                $ModuleDependanciesValid = $false
                            }
                        }
                        #Check if DepModule is in PSGetRepositories
                        elseif ($PSBoundParameters.ContainsKey('PSGetRepository'))
                        {
                            #Check for Module in all Nuget Repos
                            Remove-Variable -Name NugetDependencyList -ErrorAction SilentlyContinue
                            $NugetDependencyList = New-Object -TypeName System.Collections.ArrayList
                            foreach ($item in $PSGetRepository)
                            {
                                #Search for module
                                if (-not $PsGetModuleValidationCache.Value.ContainsKey($depModuleName))
                                {
                                    $PSGet_Params = @{
                                        Name       = $depModuleName
                                        Repository = $item.Name
                                    }
                                    if (-not $UpdateModuleReferences.IsPresent)
                                    {
                                        $PSGet_Params.Add('RequiredVersion', $depModuleVersion)
                                    }
                                    if ($item.ContainsKey('Credential'))
                                    {
                                        $PSGet_Params.Add('Credential', $item.Credential)
                                    }
                                    try
                                    {
                                        Remove-Variable -Name NugetDependency -ErrorAction SilentlyContinue
                                        $private:NugetDependency = Find-Module @PSGet_Params -ErrorAction Stop
                                    }
                                    catch
                                    {

                                    }
                                    #Add module to PsGetModuleValidationCache
                                    if ($private:NugetDependency)
                                    {
                                        $AddMember_Params = @{
                                            InputObject = $private:NugetDependency
                                            MemberType  = 'NoteProperty'
                                            Name        = 'PSGetRepoPriority'
                                        }
                                        if ($item.Priority)
                                        {
                                            $AddMember_Params.Add('Value', $item.Priority)
                                        }
                                        else
                                        {
                                            $AddMember_Params.Add('Value', 0)
                                        }
                                        $null = Add-Member @AddMember_Params -ErrorAction Stop
                                        $null = $NugetDependencyList.Add($private:NugetDependency)
                                    }
                                }
                            }
                            #Get Latest Version if multiple are present
                            if ($NugetDependencyList)
                            {
                                Remove-Variable -Name NugetDepToADD -ErrorAction SilentlyContinue
                                $NugetDepToADD = $NugetDependencyList | Sort-Object -Property Version -Descending | Sort-Object -Property PSGetRepoPriority | select -First 1
                                $null = $PsGetModuleValidationCache.Value.Add($depModuleName, $NugetDepToADD)
                            }
								
                            #Check if DepModule ref version is the latest
                            if ($PsGetModuleValidationCache.Value.ContainsKey($depModuleName) -and ($PsGetModuleValidationCache.Value[$depModuleName].Version -gt $depModuleVersion))
                            {
                                Write-Warning "Build PSModule:$moduleName/$moduleVersion in progress. PsGet Dependancy: $depModuleName/$depModuleVersion is not the latest version"
                                if ($UpdateModuleReferences.IsPresent)
                                {
                                    $ModuleDependanciesValid = $false
                                }
                            }
                        }
                        #Check If Module Dependency is already builded
                        elseif (Test-Path -Path $DepModuleDestinationPath)
                        {
                            try
                            {
                                $Mod = Test-PSModule -ModulePath $DepModuleDestinationPath -ErrorAction Stop
                                if ($Mod.ModuleInfo.Version -lt $depModuleVersion)
                                {
                                    $ModuleDependanciesValid = $false
                                }
                            }
                            catch
                            {

                            }
                        }
                        else
                        {
                            $ModuleDependanciesValid = $false
                        }
                    }

                    #Determine if module should be built
                    if ($ModuleDependanciesValid -and $ModuleVersionBuilded)
                    {
                        $ModuleAlreadyBuild = $true
                    }
                }
                catch
                {

                }

                #Build Module if not already built
                if ($ModuleAlreadyBuild)
                {
                    Write-Verbose "Build PSModule:$moduleName/$moduleVersion skipped, already built"
                }
                else
                {
                    #Build Module Dependancies
                    try
                    {
                        #Resolve Dependancies
                        if ($ResolveDependancies.IsPresent)
                        {
                            $Dependancies = $ModuleValidationCache.Value[$moduleName].ModuleInfo.RequiredModules | Where-Object { $ModuleValidationCache.Value[$moduleName].ModuleInfo.PrivateData.PSData.ExternalModuleDependencies -notcontains $_.Name }
                            foreach ($ModDependency in $Dependancies)
                            {
                                $dependantModuleName = $ModDependency.Name
                                $dependantModuleVersion = $ModDependency.Version

                                Write-Verbose "Build PSModule:$moduleName/$moduleVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion started"
                                $ModDependencyFound = $false
                                #Search for module in the Solution
                                if (-not $ModDependencyFound)
                                {
                                    if (($ModuleValidationCache.Value).ContainsKey($dependantModuleName) -and ($ModuleValidationCache.Value[$dependantModuleName].ModuleInfo.Version -ge $dependantModuleVersion))
                                    {
                                        $BuildPSModule_Params = @{
                                            SourcePath            = $ModuleValidationCache.Value[$dependantModuleName].ModuleInfo.ModuleBase
                                            DestinationPath       = $DestinationPath
                                            ResolveDependancies   = $ResolveDependancies 
                                            ModuleValidationCache = $ModuleValidationCache
                                        }
                                        if ($PSBoundParameters.ContainsKey('PSGetRepository'))
                                        {
                                            $BuildPSModule_Params.Add('PSGetRepository', $PSGetRepository)
                                        }
                                        if ($PSBoundParameters.ContainsKey('Proxy'))
                                        {
                                            $BuildPSModule_Params.Add('Proxy', $Proxy)
                                        }

                                        Build-PSModule @BuildPSModule_Params -ErrorAction Stop
                                        $ModDependencyFound = $true
                                    }
                                }

                                #Search for module in Solution PSGetRepositories
                                if ((-not $ModDependencyFound) -and ($PsGetModuleValidationCache.Value.ContainsKey($dependantModuleName)) -and ($PSBoundParameters.ContainsKey('PSGetRepository')))
                                {
                                    $NuGetDependancyHandle = $PsGetModuleValidationCache.Value[$dependantModuleName]
                                    #Check if NugetPackage is already downloaded
                                    try
                                    {
                                        $ModDependencyExcepctedPath = Join-Path -Path $DestinationPath -ChildPath $dependantModuleName -ErrorAction Stop
                                        Remove-Variable -Name ModDependencyExist -ErrorAction SilentlyContinue
                                        $ModDependencyExist = Get-Module -ListAvailable -FullyQualifiedName $ModDependencyExcepctedPath -Refresh -ErrorAction Stop -Verbose:$false
                                    }
                                    catch
                                    {

                                    }
                                    if (($ModDependencyExist) -and ($ModDependencyExist.Version -eq $NuGetDependancyHandle.Version))
                                    {
                                        #NugetPackage already downloaded
                                    }
                                    else
                                    {
                                        #Determine from which repo to download the module
                                        Remove-Variable -Name ModuleRepo -ErrorAction SilentlyContinue
                                        $ModuleRepo = $PSGetRepository | Where-Object { $_.Name -eq ($NuGetDependancyHandle.Repository) }

                                        #Downloading NugetPackage
                                        Write-Verbose "Build PSModule:$moduleName/$moduleVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion in progress. Downloading PSGetPackage: $($NuGetDependancyHandle.Name)/$($NuGetDependancyHandle.Version)"
                                        if (-not (Test-Path $DestinationPath))
                                        {
                                            $null = New-Item -Path $DestinationPath -ItemType Directory -ErrorAction Stop
                                        }
                                        $PSGet_Params = @{
                                            Name            = $dependantModuleName
                                            Repository      = $ModuleRepo.Name
                                            RequiredVersion = $NuGetDependancyHandle.Version
                                            Path            = $DestinationPath
                                        }
                                        if ($ModuleRepo.ContainsKey('Credential'))
                                        {
                                            $PSGet_Params.Add('Credential', $ModuleRepo.Credential)
                                        }
                                        if ($ModuleRepo.ContainsKey('Proxy'))
                                        {
                                            $PSGet_Params.Add('Proxy', $Proxy)
                                        }
                                        Save-Module @PSGet_Params -ErrorAction Stop -Verbose:$false
                                    }
                                    $ModDependencyFound = $true
                                }

                                #Throw Not Found
                                if ($ModDependencyFound)
                                {
                                    Write-Verbose "Build PSModule:$moduleName/$moduleVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion completed"
                                }
                                else 
                                {
                                    throw "Dependand module: $dependantModuleName/$dependantModuleVersion not found"
                                }
                            }
                        }
                    }
                    catch
                    {
                        Write-Error "Build PSModule:$moduleName/$moduleVersion dependancies failed. Details: $_"
                    }

                    #Build Module
                    try
                    {
                        #Update Module Dependancies definition
                        if (-not $ModuleDependanciesValid)
                        {
                            Write-Warning "Build PSModule:$moduleName/$moduleVersion in progress. RequiredModules specification not valid, updating it..."
                            $ModuleDependanciesDefinition = New-Object -TypeName system.collections.arraylist
                            foreach ($DepModule in $ModuleValidationCache.Value[$moduleName].ModuleInfo.RequiredModules)
                            {
                                $depModuleName = $DepModule.Name
                                $depModuleVersion = $DepModule.Version

                                if (($ModuleValidationCache.Value).ContainsKey($depModuleName))
                                {
                                    $ModSpec = [Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                                            ModuleName    = $ModuleValidationCache.Value[$depModuleName].ModuleInfo.Name
                                            ModuleVersion = $ModuleValidationCache.Value[$depModuleName].ModuleInfo.Version
                                        })
                                    $null = $ModuleDependanciesDefinition.Add($ModSpec)
                                }
                                elseif ($PsGetModuleValidationCache.Value.ContainsKey($depModuleName))
                                {
                                    $ModSpec = [Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                                            ModuleName    = $PsGetModuleValidationCache.Value[$depModuleName].Name
                                            ModuleVersion = $PsGetModuleValidationCache.Value[$depModuleName].Version
                                        })
                                    $null = $ModuleDependanciesDefinition.Add($ModSpec)
                                }
                                else
                                {
                                    if (Test-Path $DepModule.Path)
                                    {
                                        $tempDepModuleName = $DepModule.Path
                                    }
                                    else
                                    {
                                        $tempDepModuleName = $DepModule.Name
                                    }
									
                                    $ModSpec = [Microsoft.PowerShell.Commands.ModuleSpecification]::new(@{
                                            ModuleName    = $tempDepModuleName
                                            ModuleVersion = $DepModule.Version
                                        })
                                    $null = $ModuleDependanciesDefinition.Add($ModSpec)
                                }
                            }
                            if ($ModuleDependanciesDefinition.Count -gt 0)
                            {
                                Update-ModuleManifest -Path $ModuleValidationCache.Value[$moduleName].ModuleInfo.Path -RequiredModules $ModuleDependanciesDefinition -ErrorAction Stop
                            }
                        }

                        #Check Module Dependancies
                        if ($CheckCommandReferencesConfiguration.Enabled -and (-not $ModuleValidationCache.Value[$moduleName].IsVersionValid)) 
                        {
                            #if Module is Excluded in CheckCommandReferencesConfiguration
                            if ($CheckCommandReferencesConfiguration.ExcludedSources -contains $moduleName)
                            {
                                Write-Warning "Build PSModule:$moduleName/$moduleVersion in progress. Skipping CommandReference validation"
                            }
                            #if Module is not Excluded in CheckCommandReferencesConfiguration
                            else
                            {
                                #Analyze Command references
                                $CurrentRequiredModules = $PSNativeModules + $ModuleValidationCache.Value[$moduleName].ModuleInfo.RequiredModules.Name
                                $priv_AnalyseItemDependancies_Params = @{
                                    ModulePath            = $ModuleValidationCache.Value[$moduleName].ModuleInfo.ModuleBase
                                    GlobalCommandAnalysis = $CommandsToModuleMapping
                                    CurrentDependancies   = $CurrentRequiredModules
                                }
                                if ($PSBoundParameters.ContainsKey('PSGetRepository'))
                                {
                                    $priv_AnalyseItemDependancies_Params.Add('PSGetRepository', $PSGetRepository)
                                }
                                if ($PSBoundParameters.ContainsKey('Proxy'))
                                {
                                    $priv_AnalyseItemDependancies_Params.Add('Proxy', $Proxy)
                                }
                                $LocalCommandAnalysis = priv_Analyse-ItemDependancies @priv_AnalyseItemDependancies_Params -ErrorAction Stop
                                $CommandNotReferenced = $LocalCommandAnalysis | Where-Object { $_.IsReferenced -eq $false -and $_.CommandType -ne 'Application' }

                                #Check if command is in CheckCommandReferencesConfiguration.ExcludedCommands list
                                if ($CheckCommandReferencesConfiguration.ExcludedCommands.Count -gt 0)
                                {
                                    $CommandNotReferenced = $CommandNotReferenced | Where-Object { $CheckCommandReferencesConfiguration.ExcludedCommands -notcontains $_.CommandName }
                                }

                                if ($CommandNotReferenced)
                                {
                                    throw "Missing RequiredModule reference for [Module\Command]: $($CommandNotReferenced.GetCommandFQDN() -join ', ')"
                                }
                            }
                        }

                        #Check Module Integrity
                        if (-not $ModuleValidationCache.Value[$moduleName].IsReadyForPackaging)
                        {
                            throw "Not ready for packaging. Missing either Author or Description."
                        }
                        if (-not $ModuleValidationCache.Value[$moduleName].IsValid)
                        {
                            Write-Warning "Build PSModule:$moduleName/$moduleVersion in progress. Not valid, updating version..."
                            Update-PSModuleVersion -ModulePath $ModuleValidationCache.Value[$moduleName].ModuleInfo.ModuleBase -ErrorAction Stop
						
                            #Refresh ModuleValidation
                            $ModuleValidationCache.Value[$moduleName] = Test-PSModule -ModulePath $ModuleValidationCache.Value[$moduleName].ModuleInfo.ModuleBase -ErrorAction Stop
                        }

                        #Export Module to DestinationPath
                        try
                        {
                            priv_Export-Artifact -Type Module -SourcePath $ModuleValidationCache.Value[$moduleName].ModuleInfo.ModuleBase -Version $ModuleValidationCache.Value[$moduleName].ModuleInfo.Version -DestinationPath $DestinationPath -Verbose:$false
                        }
                        catch
                        {
                            throw "failed to copy module to $DestinationPath. details: $_"
                        }
                    }
                    catch
                    {
                        Write-Error "Build PSModule:$moduleName/$moduleVersion failed. Details: $_" -ErrorAction 'Stop'
                    }
                }

                Write-Verbose "Build PSModule:$moduleName/$moduleVersion completed"
            }
            else
            {
                Write-Error "Build PSModule:$moduleName failed. Missing ModuleInfo." -ErrorAction Stop
            }
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
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$SourcePath,

        #DestinationPath
        [Parameter(Mandatory = $false)]
        [System.IO.DirectoryInfo]$DestinationPath,

        #DependencyDestinationPath
        [Parameter(Mandatory = $false)]
        [System.IO.DirectoryInfo]$DependencyDestinationPath,

        #UseScriptConfigFile
        [Parameter(Mandatory = $false)]
        [switch]$UseScriptConfigFile,

        #ResolveDependancies
        [Parameter(Mandatory = $false)]
        [switch]$ResolveDependancies,

        #CheckCommandReferencesConfiguration
        [Parameter(Mandatory = $false)]
        [CheckCommandReferencesConfiguration]$CheckCommandReferencesConfiguration = ([CheckCommandReferencesConfiguration]::new()),

        #UpdateModuleReferences
        [Parameter(Mandatory = $false)]
        [switch]$UpdateModuleReferences,

        #PSGetRepository
        [Parameter(Mandatory = $false)]
        [hashtable[]]$PSGetRepository,

        #ModuleValidation
        [Parameter(Mandatory = $false)]
        [ref]$ModuleValidationCache = [ref]@{ },

        #PsGetModuleValidation
        [Parameter(Mandatory = $false)]
        [ref]$PsGetModuleValidationCache,

        #Proxy
        [Parameter(Mandatory = $false)]
        [uri]$Proxy
    )
    
    Process
    {
        if ($ResolveDependancies.IsPresent)
        {
            if (-not $PSBoundParameters.ContainsKey('DestinationPath'))
            {
                throw "DestinationPath Parameter should be used in combination with ResolveDependancies Parameter"
            }

            if (-not $PSBoundParameters.ContainsKey('DependencyDestinationPath'))
            {
                $DependencyDestinationPath = $DestinationPath
            }

            #Add DependencyDestinationPath to Process PSModulePath
            try
            {
                Add-PSModulePathEntry -Path $DependencyDestinationPath -Scope Process -Force
            }
            catch
            {
                Write-Error "Add DependencyDestinationPath to Process PSModulePath failed. Details: $_" -ErrorAction 'Stop'
            }
        }
        
        #Assert PSRepositories
        if ($PSBoundParameters.ContainsKey('PSGetRepository'))
        {
            #Register PSGetRepo
            $AssertPSRepository_Params = @{
                PSGetRepository = $PSGetRepository
            }
            if ($PSBoundParameters.ContainsKey('Proxy'))
            {
                $AssertPSRepository_Params.Add('Proxy', $Proxy)
            }
            Assert-PSRepository @AssertPSRepository_Params -ErrorAction Stop
        }

        #Validate All Scripts
        try
        {
            if (-not ($AllScriptValidation))
            {
                $AllScriptValidation = @{ }
                foreach ($Script in $SourcePath)
                {
                    $scriptName = $Script.BaseName
                    $scriptFilePath = $script.FullName
                    if (-not $AllScriptValidation.ContainsKey($scriptFilePath))
                    {
                        Remove-variable -name PSScriptValidation -ErrorAction SilentlyContinue
                        $TestPSScript_Params = @{
                            ScriptPath = $Script.FullName
                        }
                        if ($UseScriptConfigFile.IsPresent)
                        {
                            $TestPSScript_Params.Add('UseScriptConfigFile', $true)
                        }
                        $PSScriptValidation = Test-PSScript @TestPSScript_Params -ErrorAction Stop
                        
                        $null = $AllScriptValidation.Add($scriptFilePath, $PSScriptValidation)
                    }
                }
            }
        }
        catch
        {
            Write-Error "Unable to validate $scriptName. Details: $_" -ErrorAction 'Stop'
        }

        #Validate All Commands
        try
        {
            [ref]$CommandsToModuleMapping = [PSBuildEntities.AnalysisResultCollection]::new()

            #Add BuildIn Comands and Aliases to CommandsToModuleMapping (from module 'Microsoft.PowerShell.Core' as they are buildin to PowerShell)
            Get-Command -Module $PSNativeModules -Verbose:$false | ForEach-Object {

                #Add Command
                $Command = [PSBuildEntities.AnalysisResult]::new()
                $Command.CommandName = "$($_.Name)"
                $Command.CommandType = $_.CommandType
                if ($Command.CommandType -eq 'Alias')
                {
                    try
                    {
                        $TempFinding2 = Get-Command -Name $Command.CommandName -ErrorAction Stop -Verbose:$false
                        $Command.CommandSource = $TempFinding2.Source
                    }
                    catch
                    {
                    }
                }
                else
                {
                    $Command.CommandSource = $_.Source
                }
                $Command.SourceLocation = [PSBuildEntities.AnalysisResultSourceLocation]::BuildIn
                if (-not $CommandsToModuleMapping.Value.Contains($Command.CommandName))
                {
                    $CommandsToModuleMapping.Value.add($Command)
                }

                #Add Alias if exists
                Get-Alias -Definition $_.Name -ErrorAction SilentlyContinue | foreach {
                    $Alias = [PSBuildEntities.AnalysisResult]::new()
                    $Alias.CommandName = "$($_.Name)"
                    $Alias.CommandType = 'Alias'
                    $Alias.CommandSource = $Command.CommandSource
                    $Alias.SourceLocation = [PSBuildEntities.AnalysisResultSourceLocation]::BuildIn
                    if (-not $CommandsToModuleMapping.Value.Contains($Alias.CommandName))
                    {
                        $CommandsToModuleMapping.Value.add($Alias)
                    }
                }
            }

            #Add Solution Commands to CommandsToModuleMapping (from all modules in the solution)
            if ($PSBoundParameters.ContainsKey('ModuleValidationCache'))
            {
                foreach ($Mod in $ModuleValidationCache.Value.Keys)
                {
                    foreach ($cmd in $ModuleValidationCache.Value[$Mod].ModuleInfo.ExportedCommands.Values)
                    {
                        $Command = [PSBuildEntities.AnalysisResult]::new()
                        $Command.CommandName = $cmd.Name
                        $Command.CommandType = $cmd.CommandType
                        $Command.CommandSource = $cmd.Source
                        $Command.SourceLocation = [PSBuildEntities.AnalysisResultSourceLocation]::Solution
                        if (-not $CommandsToModuleMapping.Value.Contains($cmd.Name))
                        {
                            $CommandsToModuleMapping.Value.Add($Command)
                        }
                        elseif ($CommandsToModuleMapping.Value[$Command.CommandName].CommandSource -ne $Command.CommandSource)
                        {
                            if ($CheckDuplicateCommandNames.IsPresent)
                            {
                                Write-Error "Command with name: $($Command.CommandName) is present in multiple modules: $($CommandsToModuleMapping.Value[$Command.CommandName].CommandSource),$($Command.CommandSource)" -ErrorAction Stop
                            }
                        }
                    }
                }
            }
        }
        catch
        {
            Write-Error "Validate All Commands failed. Details: $_" -ErrorAction 'Stop'
        }

        #Initialize PSGetModuleValidationCache
        if (-not $PSBoundParameters.ContainsKey('PsGetModuleValidationCache'))
        {
            [ref]$PsGetModuleValidationCache = @{ }
        }

        #Build Script
        foreach ($Script in $SourcePath)
        {
            $scriptName = $Script.BaseName
            $scriptFilePath = $script.FullName

            #Get ScriptRequiredModules_All and ScriptRequiredModules_NotExternal
            Remove-Variable -Name ScriptRequiredModules -ErrorAction SilentlyContinue
            Remove-Variable -Name ScriptRequiredModules_NotExternal -ErrorAction SilentlyContinue
            if ($UseScriptConfigFile.IsPresent)
            {
                $ScriptRequiredModules_All = $AllScriptValidation[$scriptFilePath].ScriptConfig.RequiredModules
                $ScriptRequiredModules_NotExternal = $AllScriptValidation[$scriptFilePath].ScriptConfig.RequiredModules | Where-Object { $AllScriptValidation[$scriptFilePath].ScriptInfo.ExternalModuleDependencies -notcontains $_.Name }
            }
            else
            {
                $ScriptRequiredModules_All = $AllScriptValidation[$scriptFilePath].ScriptInfo.RequiredModules
                $ScriptRequiredModules_NotExternal = $AllScriptValidation[$scriptFilePath].ScriptInfo.RequiredModules | Where-Object { $AllScriptValidation[$scriptFilePath].ScriptInfo.ExternalModuleDependencies -notcontains $_.Name }
            }

            if ($AllScriptValidation[$scriptFilePath].ScriptInfo)
            {
                $scriptVersion = $AllScriptValidation[$scriptFilePath].ScriptInfo.Version

                Write-Verbose "Build Script: $scriptName/$scriptVersion started"

                #Check if Script is already built
                try
                {
                    $ScriptAlreadyBuild = $false
                    $ScriptDependanciesValid = $true
                    $ScriptVersionBuilded = $false
                    if ($PSBoundParameters.ContainsKey('DestinationPath'))
                    {
                        $ScriptBuildDestinationPath = Join-Path -Path $DestinationPath -ChildPath $Script.Name -ErrorAction Stop
                        if (Test-Path -Path $ScriptBuildDestinationPath)
                        {
                            $ScriptAlreadyBuildTest = Test-PSScript -ScriptPath $ScriptBuildDestinationPath -ErrorAction Stop
                        }
                    }
                
                    #Check if Script with the same version is already builded
                    if ($AllScriptValidation[$scriptFilePath].IsValid -and $ScriptAlreadyBuildTest.IsValid -and ($AllScriptValidation[$scriptFilePath].ScriptInfo.Version -eq $ScriptAlreadyBuildTest.ScriptInfo.Version))
                    {
                        $ScriptVersionBuilded = $true
                    }

                    #Check if Module Dependancies are valid versions
                    foreach ($DepModule in $ScriptRequiredModules_All)
                    {
                        $depModuleName = $DepModule.Name
                        $depModuleVersion = $DepModule.Version
                        if ($DependencyDestinationPath)
                        {
                            $DepModuleDestinationPath = Join-Path -Path $DependencyDestinationPath -ChildPath $depModuleName -ErrorAction Stop
                        }

                        #Check if DepModule is marked as ExternalModuleDependency
                        if ($AllScriptValidation[$scriptFilePath].ScriptInfo.ExternalModuleDependencies -contains $depModuleName)
                        {
                            #Skip this DepModule from validation, as it is marked as external
                        }
                        #Check if DepModule is in the same Solution
                        elseif (($ModuleValidationCache.Value).ContainsKey($depModuleName))
                        {
                            if ($ModuleValidationCache.Value[$depModuleName].ModuleInfo.Version -gt $depModuleVersion -or (-not $ModuleValidationCache.Value[$depModuleName].IsValid))
                            {
                                $ScriptDependanciesValid = $false
                            }
                        }
                        #Check if DepModule is in PSGetRepositories
                        elseif ($PSBoundParameters.ContainsKey('PSGetRepository'))
                        {
                            #Check for Module in all Nuget Repos
                            Remove-Variable -Name NugetDependencyList -ErrorAction SilentlyContinue
                            $NugetDependencyList = New-Object -TypeName System.Collections.ArrayList
                            foreach ($item in $PSGetRepository)
                            {
                                #Search for module
                                if (-not $PsGetModuleValidationCache.Value.ContainsKey($depModuleName))
                                {
                                    $PSGet_Params = @{
                                        Name       = $depModuleName
                                        Repository = $item.Name
                                    }
                                    if (-not $UpdateModuleReferences.IsPresent)
                                    {
                                        $PSGet_Params.Add('RequiredVersion', $depModuleVersion)
                                    }
                                    if ($item.ContainsKey('Credential'))
                                    {
                                        $PSGet_Params.Add('Credential', $item.Credential)
                                    }
                                    if ($PSBoundParameters.ContainsKey('Proxy'))
                                    {
                                        $PSGet_Params.Add('Proxy', $Proxy)
                                    }	
                                    try
                                    {
                                        Remove-Variable -Name NugetDependency -ErrorAction SilentlyContinue
                                        $private:NugetDependency = Find-Module @PSGet_Params -ErrorAction Stop
                                    }
                                    catch
                                    {

                                    }
                                    #Add module to PsGetModuleValidationCache
                                    if ($private:NugetDependency)
                                    {
                                        $AddMember_Params = @{
                                            InputObject = $private:NugetDependency
                                            MemberType  = 'NoteProperty'
                                            Name        = 'PSGetRepoPriority'
                                        }
                                        if ($item.Priority)
                                        {
                                            $AddMember_Params.Add('Value', $item.Priority)
                                        }
                                        else
                                        {
                                            $AddMember_Params.Add('Value', 0)
                                        }
                                        $null = Add-Member @AddMember_Params -ErrorAction Stop
                                        $null = $NugetDependencyList.Add($private:NugetDependency)
                                    }
                                }
                            }
                            #Get Latest Version if multiple are present
                            if ($NugetDependencyList)
                            {
                                Remove-Variable -Name NugetDepToADD -ErrorAction SilentlyContinue
                                $NugetDepToADD = $NugetDependencyList | Sort-Object -Property Version -Descending | Sort-Object -Property PSGetRepoPriority | select -First 1
                                $null = $PsGetModuleValidationCache.Value.Add($depModuleName, $NugetDepToADD)
                            }
								
                            #Check if DepModule ref version is the latest
                            if ($PsGetModuleValidationCache.Value.ContainsKey($depModuleName) -and ($PsGetModuleValidationCache.Value[$depModuleName].Version -gt $depModuleVersion))
                            {
                                Write-Warning "Build Script: $scriptName/$scriptVersion in progress. PsGet Dependancy: $depModuleName/$depModuleVersion is not the latest version"
                                if ($UpdateModuleReferences.IsPresent)
                                {
                                    $ScriptDependanciesValid = $false
                                }
                            }
                        }
                        #Check If Module Dependency is already builded
                        elseif ($DependencyDestinationPath -and (Test-Path -Path $DepModuleDestinationPath))
                        {
                            try
                            {
                                $Mod = Test-PSModule -ModulePath $DepModuleDestinationPath -ErrorAction Stop
                                if ($Mod.ModuleInfo.Version -lt $depModuleVersion)
                                {
                                    $ScriptDependanciesValid = $false
                                }
                            }
                            catch
                            {

                            }
                        }
                        else
                        {
                            $ScriptDependanciesValid = $false
                        }
                    }

                    #Determine if script should be built
                    if ($ScriptVersionBuilded -and $ScriptDependanciesValid)
                    {
                        $ScriptAlreadyBuild = $true
                    }
                }
                catch
                {

                }

                #Build Script if not already built
                if ($ScriptAlreadyBuild)
                {
                    Write-Verbose "Build Script: $scriptName/$scriptVersion skipped, already built"
                }
                else
                {
                    #Build Script Dependancies
                    try
                    {
                        #Resolve Dependancies
                        if ($ResolveDependancies.IsPresent)
                        {
                            foreach ($ModDependency in $ScriptRequiredModules_NotExternal)
                            {
                                $dependantModuleName = $ModDependency.Name
                                $dependantModuleVersion = $ModDependency.Version

                                Write-Verbose "Build Script: $scriptName/$scriptVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion started"
                                $ModDependencyFound = $false
                                #Search for module in the Solution
                                if ((-not $ModDependencyFound) -and ($ModuleValidationCache.Value).ContainsKey($dependantModuleName))
                                {
                                    $BuildPSModule_Params = @{
                                        SourcePath            = $ModuleValidationCache.Value[$dependantModuleName].ModuleInfo.ModuleBase
                                        DestinationPath       = $DependencyDestinationPath
                                        ResolveDependancies   = $ResolveDependancies.IsPresent
                                        ModuleValidationCache = $ModuleValidationCache
                                    }
                                    if ($PSBoundParameters.ContainsKey('Proxy'))
                                    {
                                        $BuildPSModule_Params.Add('Proxy', $Proxy)
                                    }
                                    Build-PSModule @BuildPSModule_Params -ErrorAction Stop
                                    $ModDependencyFound = $true
                                }

                                #Search for module in Solution PSGetRepositories
                                if ((-not $ModDependencyFound) -and ($PsGetModuleValidationCache.Value.ContainsKey($dependantModuleName)) -and ($PSBoundParameters.ContainsKey('PSGetRepository')))
                                {
                                    $NuGetDependancyHandle = $PsGetModuleValidationCache.Value[$dependantModuleName]
                                    #Check if NugetPackage is already downloaded
                                    try
                                    {
                                        $ModDependencyExcepctedPath = Join-Path -Path $DependencyDestinationPath -ChildPath $dependantModuleName -ErrorAction Stop
                                        Remove-Variable -Name ModDependencyExist -ErrorAction SilentlyContinue
                                        $ModDependencyExist = Get-Module -ListAvailable -FullyQualifiedName $ModDependencyExcepctedPath -Refresh -ErrorAction Stop -Verbose:$false
                                    }
                                    catch
                                    {

                                    }
                                    if (($ModDependencyExist) -and ($ModDependencyExist.Version -eq $NuGetDependancyHandle.Version))
                                    {
                                        #NugetPackage already downloaded
                                    }
                                    else
                                    {
                                        #Determine from which repo to download the module
                                        Remove-Variable -Name ModuleRepo -ErrorAction SilentlyContinue
                                        $ModuleRepo = $PSGetRepository | Where-Object { $_.Name -eq ($NuGetDependancyHandle.Repository) }

                                        #Downloading NugetPackage
                                        Write-Verbose "Build Script: $scriptName/$scriptVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion in progress. Downloading PSGetPackage: $($NuGetDependancyHandle.Name)/$($NuGetDependancyHandle.Version)"
                                        if (-not (Test-Path $DependencyDestinationPath))
                                        {
                                            $null = New-Item -Path $DependencyDestinationPath -ItemType Directory -ErrorAction Stop
                                        }
                                        $PSGet_Params = @{
                                            Name            = $dependantModuleName
                                            Repository      = $ModuleRepo.Name
                                            RequiredVersion = $NuGetDependancyHandle.Version
                                            Path            = $DependencyDestinationPath
                                        }
                                        if ($ModuleRepo.ContainsKey('Credential'))
                                        {
                                            $PSGet_Params.Add('Credential', $ModuleRepo.Credential)
                                        }
                                        if ($PSBoundParameters.ContainsKey('Proxy'))
                                        {
                                            $PSGet_Params.Add('Proxy', $Proxy)
                                        }
                                        Save-Module @PSGet_Params -ErrorAction Stop -Verbose:$false
                                    }
                                    $ModDependencyFound = $true
                                }

                                #Throw Not Found
                                if ($ModDependencyFound)
                                {
                                    Write-Verbose "Build Script: $scriptName/$scriptVersion in progress. Build dependant module:$dependantModuleName/$dependantModuleVersion completed"
                                }
                                else 
                                {
                                    throw "Dependand module: $dependantModuleName/$dependantModuleVersion not found"
                                }
                            }
                        }
                    }
                    catch
                    {
                        Write-Error "Build Script: $scriptName/$scriptVersion failed. Details: $_"
                    }

                    #Build Script
                    try
                    {
                        #Update Script Dependancies definition
                        if (-not $ScriptDependanciesValid)
                        {
                            Write-Warning "Build Script: $scriptName/$scriptVersion in progress. RequiredModules specification not valid, updating it..."

                            foreach ($DepModule in $ScriptRequiredModules_All)
                            {
                                $depModuleName = $DepModule.Name

                                if (($ModuleValidationCache.Value).ContainsKey($depModuleName))
                                {
                                    $DepModule.Version = $ModuleValidationCache.Value[$depModuleName].ModuleInfo.Version
                                }
                                elseif ($PsGetModuleValidationCache.Value.ContainsKey($depModuleName))
                                {
                                    $DepModule.Version = $PsGetModuleValidationCache.Value[$depModuleName].Version
                                }
                            }
                            if (($ScriptRequiredModules_All | measure-object).Count -gt 0)
                            {
                                if ($UseScriptConfigFile.IsPresent)
                                {
                                    Update-PSScriptConfig -ScriptPath $AllScriptValidation[$scriptFilePath].ScriptInfo.Path -ScriptConfig $AllScriptValidation[$scriptFilePath].ScriptConfig
                                }
                                else
                                {
                                    Update-ScriptFileInfo -Path $AllScriptValidation[$scriptFilePath].ScriptInfo.Path -RequiredModules $ScriptRequiredModules -ErrorAction Stop
                                }
                            }
                        }

                        #Check Script Dependancies
                        if ($CheckCommandReferencesConfiguration.Enabled -and (-not $AllScriptValidation[$scriptFilePath].IsVersionValid))
                        {
                            #if Script is Excluded in CheckCommandReferencesConfiguration
                            if ($CheckCommandReferencesConfiguration.ExcludedSources -contains $scriptName)
                            {
                                Write-Warning "Build Script: $scriptName/$scriptVersion in progress. Skipping CommandReference validation"
                            }
                            #if Script is not Excluded in CheckCommandReferencesConfiguration
                            else
                            {
                                #Analyze Command references

                                $CurrentRequiredModules = $PSNativeModules + $ScriptRequiredModules_All.Name
                                
                                $priv_AnalyseItemDependancies_Params = @{
                                    ScriptPath            = $AllScriptValidation[$scriptFilePath].ScriptInfo.Path
                                    GlobalCommandAnalysis = $CommandsToModuleMapping
                                    CurrentDependancies   = $CurrentRequiredModules
                                }
                                if ($PSBoundParameters.ContainsKey('PSGetRepository'))
                                {
                                    $priv_AnalyseItemDependancies_Params.Add('PSGetRepository', $PSGetRepository)
                                }
                                if ($PSBoundParameters.ContainsKey('Proxy'))
                                {
                                    $priv_AnalyseItemDependancies_Params.Add('Proxy', $Proxy)
                                }
                                $LocalCommandAnalysis = priv_Analyse-ItemDependancies @priv_AnalyseItemDependancies_Params -ErrorAction Stop
                                $CommandNotReferenced = $LocalCommandAnalysis | Where-Object { ($_.IsReferenced -eq $false) -and ($_.CommandType -ne 'Application') }

                                #Check if command is in CheckCommandReferencesConfiguration.ExcludedCommands list
                                if ($CheckCommandReferencesConfiguration.ExcludedCommands.Count -gt 0)
                                {
                                    $CommandNotReferenced = $CommandNotReferenced | Where-Object { $CheckCommandReferencesConfiguration.ExcludedCommands -notcontains $_.CommandName }
                                }

                                if ($CommandNotReferenced)
                                {
                                    throw "Missing RequiredModule reference for [Module\Command]: $($CommandNotReferenced.GetCommandFQDN() -join ', ')"
                                }
                            }
                        }

                        #Check Script Integrity
                        if (-not $AllScriptValidation[$scriptFilePath].IsValid)
                        {
                            Write-Warning "Build Script: $scriptName/$scriptVersion in progress. Not valid, updating version..."
                            Update-PSScriptVersion -ScriptPath $AllScriptValidation[$scriptFilePath].ScriptInfo.Path -ErrorAction Stop
						
                            #Refresh ScriptValidation
                            $AllScriptValidation[$scriptFilePath] = Test-PSScript -ScriptPath $AllScriptValidation[$scriptFilePath].ScriptInfo.Path -ErrorAction Stop
                        }
                        elseif (-not $AllScriptValidation[$scriptFilePath].IsReadyForPackaging)
                        {
                            throw "Not ready for packaging. Missing either Author or Description."
                        }

                        #Export Script to DestinationPath
                        if ($PSBoundParameters.ContainsKey('DestinationPath'))
                        {
                            try
                            {
                                $privExportArtifact_Params = @{
                                    SourcePath      = $AllScriptValidation[$scriptFilePath].ScriptInfo.Path
                                    DestinationPath = $DestinationPath
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
                            }
                            catch
                            {
                                throw "Unable to copy script to $DestinationPath. Details: $_"
                            }
                        }
                    }
                    catch
                    {
                        Write-Error "Build Script: $scriptName/$scriptVersion failed. Details: $_" -ErrorAction 'Stop'
                    }
                }

                Write-Verbose "Build Script: $scriptName/$scriptVersion completed"
            }
            else
            {
                $ErrorMsg = "Build Script: $scriptName failed."
                if ($AllScriptValidation[$scriptFilePath].ValidationErrors)
                {
                    $ErrorDetails = $AllScriptValidation[$scriptFilePath].ValidationErrors -join "$([System.Environment]::NewLine) $([System.Environment]::NewLine)"
                    $ErrorMsg += @"
 Script Parse Errors:
$ErrorDetails
"@
                }
                else
                {
                    $ErrorMsg += 'Missing ScriptInfo.'
                }
                Write-Error $ErrorMsg -ErrorAction Stop	
            }
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

                #Calculate ProfilesNotInScope
                #$ProfilesNotInScope = [System.Collections.Generic.List[string]]::new()
                #foreach ($scp in @('User','Process','Machine'))
                #{
                #    if ($AddRemove_PSModulePathEntry_CommonParams['Scope'] -notcontains $scp)
                #    {
                #        $ProfilesNotInScope.add($scp)
                #    }
                #}

                if ($SolutionConfig.Build.AutoloadDependancies)
                {
                    Write-Verbose "Configure PS Environment in progress. Enable Module autoloading for: $($DependancyFolders -join ',')"
                    Add-PSModulePathEntry @AddRemove_PSModulePathEntry_CommonParams -Force -ErrorAction Stop

                    #if ($ProfilesNotInScope.Count -gt 0)
                    #{
                    #    Remove-PSModulePathEntry -Path $DependancyFolders -Scope $ProfilesNotInScope -ErrorAction Stop -WarningAction SilentlyContinue
                    #}
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
            [ref]$ModuleValidationCache = @{ }
            [ref]$PsGetModuleValidationCache = @{ }

            if ($SolutionConfig.SolutionStructure.ModulesPath)
            {
                Write-Verbose "Build PSModules started"

                #Validate All Modules
                $AllModulesPath = New-Object System.Collections.ArrayList -ErrorAction Stop
                foreach ($ModulePath in $SolutionConfig.SolutionStructure.ModulesPath)
                {
                    $null = Get-ChildItem -Path $ModulePath.SourcePath -Directory -ErrorAction Stop | foreach { $AllModulesPath.Add($_) }
                }
                priv_Validate-Module -SourcePath $AllModulesPath -ModuleValidationCache $ModuleValidationCache

                foreach ($ModulePath in $SolutionConfig.SolutionStructure.ModulesPath)
                {
                    $Modules = Get-ChildItem -Path $ModulePath.SourcePath -Directory -ErrorAction Stop
                    $BuildPSModule_Params = @{
                        SourcePath                          = $Modules
                        DestinationPath                     = $ModulePath.BuildPath
                        ResolveDependancies                 = $SolutionConfig.Build.AutoResolveDependantModules
                        PSGetRepository                     = $SolutionConfig.Packaging.PSGetSearchRepositories
                        CheckCommandReferencesConfiguration = $SolutionConfig.Build.CheckCommandReferences
                        ModuleValidationCache               = $ModuleValidationCache
                        UpdateModuleReferences              = $SolutionConfig.Build.UpdateModuleReferences
                        PsGetModuleValidationCache          = $PsGetModuleValidationCache
                    }
                    if ($SolutionConfig.GlobalSettings.Proxy.Uri)
                    {
                        $BuildPSModule_Params.Add('Proxy', $SolutionConfig.GlobalSettings.Proxy.Uri)
                    }
                    Build-PSModule @BuildPSModule_Params -ErrorAction Stop
                }
		
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

            foreach ($ScriptPath in $SolutionConfig.SolutionStructure.ScriptPath)
            {
                Remove-Variable -Name Scripts -ErrorAction SilentlyContinue
                $Scripts = Get-ChildItem -Path $ScriptPath.SourcePath -Filter *.ps1  -ErrorAction Stop
                if ($ScriptPath.ContainsKey('Exclude'))
                {
                    $Scripts = $Scripts | where-object { $ScriptPath.Exclude -notcontains $_.Name }
                }
                if ($scripts)
                {
                    $BuildPSScript_Params = @{
                        SourcePath                          = $Scripts
                        ResolveDependancies                 = $SolutionConfig.Build.AutoResolveDependantModules
                        PSGetRepository                     = $SolutionConfig.Packaging.PSGetSearchRepositories
                        CheckCommandReferencesConfiguration = $SolutionConfig.Build.CheckCommandReferences
                        ModuleValidationCache               = $ModuleValidationCache
                        UpdateModuleReferences              = $SolutionConfig.Build.UpdateModuleReferences
                        PsGetModuleValidationCache          = $PsGetModuleValidationCache
                        UseScriptConfigFile                 = $SolutionConfig.Build.UseScriptConfigFile
                    }
                    if ($ScriptPath.ContainsKey('BuildPath'))
                    {
                        $BuildPSScript_Params.Add('DestinationPath', $ScriptPath.BuildPath)
                    }
                    if ($ScriptPath.ContainsKey('DependencyDestinationPath'))
                    {
                        $BuildPSScript_Params.Add('DependencyDestinationPath', $ScriptPath.DependencyDestinationPath)
                    }
                    if ($SolutionConfig.GlobalSettings.Proxy.Uri -and (-not [string]::IsNullOrEmpty($SolutionConfig.GlobalSettings.Proxy.Uri)))
                    {
                        $BuildPSScript_Params.Add('Proxy', $SolutionConfig.GlobalSettings.Proxy.Uri)
                    }
                    Build-PSScript @BuildPSScript_Params -ErrorAction Stop
                }
            }
      
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
            $SolutionConfigRaw = Get-Content -Path $Path.FullName -Raw -ErrorAction Stop
            $SolutionRootFolder = Split-Path -Path $Path -Parent -ErrorAction Stop
            if ($PSBoundParameters.ContainsKey('UserVariables'))
            {
                Set-Variable -Name UserVariables -Value $UserVariables -Scope global -ErrorAction Stop
            }
            $r = "`$env:ScriptRoot = '$SolutionRootFolder'" + "`n" + $SolutionConfigRaw
            New-DynamicConfiguration -Definition ([scriptblock]::Create($r)) -ErrorAction Stop
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
            #Check if Repository is already registered
            $RepoFound = $false
            try
            {
                $RepoCheck = Get-PSRepository -Name $Repo.Name -ErrorAction Stop
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
                        Set-PSRepository @SetPSRepository_Params -ErrorAction Stop
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
                        Set-PSRepository @SetPSRepository_Params -ErrorAction Stop
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
                $null = Register-PSRepository @RegisterPSRepository_Params -ErrorAction Stop
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

#region Configuration Classes

class CheckCommandReferencesConfiguration
{
    [bool] $Enabled
    [System.Collections.Generic.List[string]]$ExcludedSources = ([System.Collections.Generic.List[string]]::new())
    [System.Collections.Generic.List[string]]$ExcludedCommands = ([System.Collections.Generic.List[string]]::new())
}

#endregion