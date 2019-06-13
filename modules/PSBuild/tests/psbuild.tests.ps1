describe "Scripts with ScriptInfo" {

    $ModulesPath = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent

    it "Build-PSScript -UseScriptConfigFile should use the scriptconfigfile for RequiredModules" {
        #Import required modules
        Import-Module -FullyQualifiedName "$ModulesPath\pshelper" -force -ErrorAction Stop
        Import-Module -FullyQualifiedName "$ModulesPath\psbuild" -force -ErrorAction Stop

        $BuildPSScript_Params = @{
            SourcePath="$PSScriptRoot\examples\examplescript1.ps1"
            DestinationPath="$PSScriptRoot\examples\bin"
            CheckCommandReferences=$true
            CheckCommandReferencesConfiguration=@{
                Enabled=$true
            }
            UseScriptConfigFile=$true
            PSGetRepository=@{
                Name='PSGallery'
            }
        }
        Build-PSScript @BuildPSScript_Params -ErrorAction Stop -Verbose
    }
}