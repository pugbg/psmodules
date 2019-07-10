describe 'AdoAzHelper-TesterExtension' {
    it "Build and Publish To Marketplace" {
        try
        {
            $PublisherId = 'psmodules-tester'
            $PublisherPat = read-host -Prompt 'Publisher PAT'
            $AdoOrgToShareTo = 'gogbg'

            #Create Temp Folder to build the extension
            $ExtesionBinFolderPath = Join-Path -Path "TestDrive:" -ChildPath 'bin\ADO-Extension'
            if (-not (Test-Path -Path $ExtesionBinFolderPath))
            {
                New-Item -Path $ExtesionBinFolderPath -ItemType Directory -ErrorAction Stop
            }
            Set-Location $ExtesionBinFolderPath

            #Copy ADO-Extenson to ExtesionBinFolderPath 
            $ExtensionPath = Join-Path -Path $PSScriptRoot -ChildPath AdoAzHelper-TesterExtension
            Copy-Item -Path "$ExtensionPath\*" -Destination $ExtesionBinFolderPath -Recurse -ErrorAction Stop

            #Inject Dependant module in ps_modules
            Save-module -Name AdoAzHelper -Path "$ExtesionBinFolderPath\task1\ps_modules"

            #Install Dependancies
            
            npm --% install vss-web-extension-sdk --save --loglevel=error
            $PackageDetailsAsJson = tfx --% extension create --json
            $PackageDetails = $PackageDetailsAsJson | ConvertFrom-Json

            #Publish Extension
            Start-NewProcess -FilePath 'C:\programdata\nodejs\tfx.cmd' -Arguments "extension publish --vsix $($PackageDetails.path) --service-url https://marketplace.visualstudio.com --token $PublisherPat --publisher $PublisherId --share-with $AdoOrgToShareTo --no-prompt" -ReturnResult
        }
        finally
        {
            Set-Location c:
        }
    }
}