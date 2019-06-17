$UserVariables = @{
	SolutionRoot = (Split-Path $env:ScriptRoot -Parent -ErrorAction Stop | Split-path -Parent -ErrorAction Stop)
}
$SolutionStructure=@{
	#Example: @(@{SourcePath='c:\modules'},@{BuildPath='c:\modules bin'})
	ScriptPath=@(
		@{
			SourcePath="$($UserVariables['SolutionRoot'])\src\scriptsWithConfigs"
		}
	)
}
$Build=@{
	AutoloadDependancies=$true
	AutoloadDependanciesScope=@('Process')
	AutoResolveDependantModules=$true
	CheckCommandReferences=@{
		Enabled=$true
		ExcludedSources=@()
		ExcludedCommands=@()
	}
	CheckDuplicateCommandNames=$true
	UpdateModuleReferences=$true
}
$Packaging=@{
	#Example: @{Name='';SourceLocation='';PublishLocation='';Credential=''}
	PSGetSearchRepositories=@(
		#@{
		#	Name='PSGallery'
		#	Priority=2
		#}
	)
	PSGetPublishRepositories=@(
	)
	#List of Modules that should be published to PSGet Repository
	PublishAllModules=$false
	PublishSpecificModules=@()
	PublishExcludeModules=@()
}
$BuildActions=@{
	#Example: @(@{Name='Step1';ScriptBlock={Start-Something}})
	PostBuild=@(
	)
}
