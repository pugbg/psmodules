<#PSScriptInfo

.VERSION 1.0.0.12

.GUID 3e268f95-0479-4baf-b95e-44152c6970e5

.AUTHOR gogbg@outlook.com

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#> 

#Requires -Module @{ ModuleName = 'PSHelper'; ModuleVersion = '1.0.0.58' }

<#
.DESCRIPTION
test script
#>
[cmdletbinding()]
param
()

process
{
    Get-PSModulePath
}