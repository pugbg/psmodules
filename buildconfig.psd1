$UserVariables = @{
	PSGalleryApiKey=Get-Credential -UserName 'gogbg psgallery repo' -Message 'Enter NugetApiKey'
}
$SolutionStructure=@{
	#Example: @(@{SourcePath='c:\modules'},@{BuildPath='c:\modules bin'})
	ModulesPath=@(
		@{
			SourcePath="$env:ScriptRoot\modules"
			BuildPath="$env:ScriptRoot\bin\modules"
		}
	)
	ScriptPath=@()
}
$Build=@{
	AutoloadbuiltModulesForUser=$false
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
		@{
			Name='PSGallery'
			Priority=2
		}
	)
	PSGetPublishRepositories=@(
		@{
			Name='PSGallery'
			NuGetApiKey=$UserVariables['PSGalleryApiKey'].GetNetworkCredential().password
		}
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
