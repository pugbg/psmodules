#
# Module manifest for module 'PSHelper'
#
# Generated by: gogbg@outlook.com
#
# Generated on: 07.07.2021
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'PSHelper.psm1'

# Version number of this module.
ModuleVersion = '1.0.0.59'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '886ce467-e422-4efc-bc08-84925fab215e'

# Author of this module
Author = 'gogbg@outlook.com'

# Company or vendor of this module
CompanyName = 'unknown'

# Copyright statement for this module
Copyright = '(c) 2014 . All rights reserved.'

# Description of the functionality provided by this module
Description = 'Generic PowerShell functionalities'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(@{ModuleName = 'Microsoft.PowerShell.Utility'; ModuleVersion = '3.1.0.0'; }, 
               @{ModuleName = 'Microsoft.PowerShell.Management'; ModuleVersion = '3.1.0.0'; }, 
               @{ModuleName = 'TypeHelper'; ModuleVersion = '1.0.0.75'; }, 
               @{ModuleName = 'PowerShellGet'; ModuleVersion = '2.2.5'; })

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Add-PSModulePathEntry', 'Set-PSModulePath', 'Get-PSModulePath', 
               'Remove-PSModulePathEntry', 'Test-PSModule', 'Update-PSModuleVersion', 
               'Publish-PSModule', 'Test-PSScript', 'Update-PSScriptVersion', 
               'Update-PSScriptConfig'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    #VersionControl of this module
    VersionControl = '{"Hash":"562433C57EE9B75089ECC682CD42176F49FFF987BFAD69768E082DE03955D576","HashAlgorithm":"SHA256","Version":"1.0.0.59"}'

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        ExternalModuleDependencies = @('Microsoft.PowerShell.Utility','Microsoft.PowerShell.Management')

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

