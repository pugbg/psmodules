$ModulesFolder = "$PSScriptRoot\modules"

Import-Module -FullyQualifiedName "$ModulesFolder\AstExtensions" -Force -ErrorAction Stop
Import-Module -FullyQualifiedName "$ModulesFolder\PSHelper" -Force -ErrorAction Stop
Import-Module -FullyQualifiedName "$ModulesFolder\TypeHelper" -Force -ErrorAction Stop
Import-Module -FullyQualifiedName "$ModulesFolder\PSBuild" -Force -ErrorAction Stop

#Configure Process PSModulePaths
try
{
	Write-Verbose "Configure User PSModulePaths started" -Verbose
			
	#Get Current Entries
	$PathToAdd = @(
		"$PSScriptRoot\bin\modules"
	)
	$CurrentEntries = [System.Environment]::GetEnvironmentVariable('PSModulePath','Process') -split ';'
	$CurPSModulePathArr = New-Object -TypeName System.Collections.ArrayList
	foreach ($Entry in $CurrentEntries)
	{
		if (-not [string]::IsNullOrEmpty($Entry))
		{
			$null = $CurPSModulePathArr.Add($Entry)
		}
	}

	#Add Entries
	foreach ($Item in $PathToAdd)
	{
		if ($CurPSModulePathArr -notcontains $Item)
		{
			$null = $CurPSModulePathArr.Add($Item)
			Write-Verbose "Configure Process PSModulePaths in progress. $Item will be added" -Verbose
		}
	}

	[System.Environment]::SetEnvironmentVariable('PsModulePath',($CurPsModulePathArr -join ';'),[System.EnvironmentVariableTarget]::Process)

	Write-Verbose "Configure Process PSModulePaths completed" -Verbose
}
catch
{
	Write-Error "Register Process PSGet Repositories failed. Details: $_" -ErrorAction 'Stop'
}

Publish-PSSolution -SolutionConfigPath "$PSScriptRoot\buildconfig.psd1" -Verbose -ErrorAction Stop