[Cmdletbinding()]
param
(
	[string]$PSGalleryApiKey
)

process
{
	$ModulesFolder = "$PSScriptRoot\modules"

	Import-Module -FullyQualifiedName "$ModulesFolder\AstExtensions" -Force -ErrorAction Stop
	Import-Module -FullyQualifiedName "$ModulesFolder\TypeHelper" -Force -ErrorAction Stop
	Import-Module -FullyQualifiedName "$ModulesFolder\PSHelper" -Force -ErrorAction Stop
	Import-Module -FullyQualifiedName "$ModulesFolder\PSBuild" -Force -ErrorAction Stop
	
	$SolutionConfiguration = Get-PSSolutionConfiguration -Path 'buildconfig.psd1' -UserVariables @{
		PSGalleryApiKey=$PSGalleryApiKey
	}

	Publish-PSSolution -SolutionConfigObject $SolutionConfiguration -Verbose -ErrorAction Stop
}